import math
import random
import string
from datetime import timedelta

from django.db import transaction
from django.db.models import Q
from django.utils import timezone
from rest_framework.exceptions import ValidationError

from apps.societies.models import ParkingSlot, SlotAvailabilityWindow
from utils.qr import generate_qr_token

from .models import Booking

BUFFER_MINUTES = 10
MIN_DURATION_MINUTES = 30
MAX_DURATION_HOURS = 24
MAX_ADVANCE_HOURS = 24
LOCK_DURATION_SECONDS = 120  # 2 minutes


def _generate_booking_number():
    date_part = timezone.now().strftime("%Y%m%d")
    random_part = "".join(random.choices(string.ascii_uppercase + string.digits, k=6))
    return f"BK-{date_part}-{random_part}"


def create_booking(user, slot_id, vehicle, start_time, end_time):
    now = timezone.now()

    # Validate timing constraints
    if start_time < now:
        raise ValidationError("Start time cannot be in the past.")

    if start_time > now + timedelta(hours=MAX_ADVANCE_HOURS):
        raise ValidationError(f"Cannot book more than {MAX_ADVANCE_HOURS} hours in advance.")

    duration = end_time - start_time
    if duration < timedelta(minutes=MIN_DURATION_MINUTES):
        raise ValidationError(f"Minimum booking duration is {MIN_DURATION_MINUTES} minutes.")

    if duration > timedelta(hours=MAX_DURATION_HOURS):
        raise ValidationError(f"Maximum booking duration is {MAX_DURATION_HOURS} hours.")

    with transaction.atomic():
        # Lock the slot row to prevent race conditions
        try:
            slot = ParkingSlot.objects.select_for_update().get(
                id=slot_id, is_active=True
            )
        except ParkingSlot.DoesNotExist:
            raise ValidationError("Slot not found or inactive.")

        # Validate slot state
        if slot.state == ParkingSlot.SlotState.BLOCKED:
            raise ValidationError("Slot is currently blocked.")

        if slot.approval_status != ParkingSlot.ApprovalStatus.APPROVED:
            raise ValidationError("Slot is not approved for booking yet.")

        # Validate vehicle type matches slot type
        if vehicle.vehicle_type != slot.slot_type:
            raise ValidationError(
                f"Vehicle type '{vehicle.vehicle_type}' does not match "
                f"slot type '{slot.slot_type}'."
            )

        # Check resident-owned slot availability windows
        if slot.ownership_type == ParkingSlot.OwnershipType.RESIDENT:
            day_of_week = start_time.weekday()
            windows = SlotAvailabilityWindow.objects.filter(
                slot=slot,
                day_of_week=day_of_week,
                is_active=True,
            )
            if not windows.exists():
                raise ValidationError("Slot is not available on this day.")

            in_window = any(
                w.start_time <= start_time.time() and w.end_time >= end_time.time()
                for w in windows
            )
            if not in_window:
                raise ValidationError(
                    "Booking time falls outside the slot's availability window."
                )

        # Check for overlapping bookings (with 10-min buffer)
        buffer = timedelta(minutes=BUFFER_MINUTES)
        overlapping = Booking.objects.filter(
            slot=slot,
            status__in=[
                Booking.Status.PENDING_PAYMENT,
                Booking.Status.CONFIRMED,
                Booking.Status.ACTIVE,
            ],
        ).filter(
            Q(start_time__lt=end_time + buffer) & Q(end_time__gt=start_time - buffer)
        )

        if overlapping.exists():
            raise ValidationError(
                "Slot is not available for the requested time range "
                "(including 10-minute buffer between bookings)."
            )

        # Calculate amount
        duration_hours = math.ceil(duration.total_seconds() / 3600)
        amount = slot.hourly_rate * duration_hours

        # Generate booking number and QR token
        booking_number = _generate_booking_number()

        # Create booking
        booking = Booking(
            booking_number=booking_number,
            user=user,
            vehicle=vehicle,
            slot=slot,
            start_time=start_time,
            end_time=end_time,
            status=Booking.Status.PENDING_PAYMENT,
            amount=amount,
            qr_code_token="placeholder",  # will be updated after save
            lock_expires_at=now + timedelta(seconds=LOCK_DURATION_SECONDS),
        )
        booking.save()

        # Generate QR token with booking data
        booking.qr_code_token = generate_qr_token(booking)
        booking.save(update_fields=["qr_code_token"])

        # Schedule lock expiry via Celery
        from .tasks import expire_booking_lock

        expire_booking_lock.apply_async(
            args=[str(booking.id)],
            countdown=LOCK_DURATION_SECONDS,
        )

        return booking


def cancel_booking(booking, user):
    if booking.user != user:
        raise ValidationError("You can only cancel your own bookings.")

    if booking.status not in (
        Booking.Status.PENDING_PAYMENT,
        Booking.Status.CONFIRMED,
    ):
        raise ValidationError(f"Cannot cancel booking in '{booking.status}' state.")

    with transaction.atomic():
        booking = Booking.objects.select_for_update().get(id=booking.id)
        was_confirmed = booking.status == Booking.Status.CONFIRMED

        booking.status = Booking.Status.CANCELLED
        booking.save(update_fields=["status", "updated_at"])

        # Free slot if it was reserved
        if was_confirmed:
            slot = ParkingSlot.objects.select_for_update().get(id=booking.slot_id)
            if slot.state == ParkingSlot.SlotState.RESERVED:
                slot.state = ParkingSlot.SlotState.AVAILABLE
                slot.save(update_fields=["state", "updated_at"])

    return booking
