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
ACTIVE_BOOKING_STATUSES = [
    Booking.Status.PENDING_PAYMENT,
    Booking.Status.CONFIRMED,
    Booking.Status.ACTIVE,
]


def _generate_booking_number():
    date_part = timezone.now().strftime("%Y%m%d")
    random_part = "".join(random.choices(string.ascii_uppercase + string.digits, k=6))
    return f"BK-{date_part}-{random_part}"


def validate_booking_window(start_time, end_time):
    now = timezone.now()

    if start_time < now:
        raise ValidationError("Start time cannot be in the past.")

    if start_time > now + timedelta(hours=MAX_ADVANCE_HOURS):
        raise ValidationError(f"Cannot book more than {MAX_ADVANCE_HOURS} hours in advance.")

    duration = end_time - start_time
    if duration < timedelta(minutes=MIN_DURATION_MINUTES):
        raise ValidationError(f"Minimum booking duration is {MIN_DURATION_MINUTES} minutes.")

    if duration > timedelta(hours=MAX_DURATION_HOURS):
        raise ValidationError(f"Maximum booking duration is {MAX_DURATION_HOURS} hours.")

    return duration


def _slot_windows(slot, day_of_week):
    prefetched = getattr(slot, "_prefetched_objects_cache", {})
    if "availability_windows" in prefetched:
        return [
            window
            for window in prefetched["availability_windows"]
            if window.is_active and window.day_of_week == day_of_week
        ]

    return SlotAvailabilityWindow.objects.filter(
        slot=slot,
        day_of_week=day_of_week,
        is_active=True,
    )


def slot_is_available(slot, vehicle_type, start_time, end_time):
    if slot.state == ParkingSlot.SlotState.BLOCKED:
        return False

    if slot.slot_type != vehicle_type:
        return False

    if slot.ownership_type == ParkingSlot.OwnershipType.RESIDENT:
        day_of_week = start_time.weekday()
        windows = _slot_windows(slot, day_of_week)
        if not windows:
            return False

        in_window = any(
            window.start_time <= start_time.time() and window.end_time >= end_time.time()
            for window in windows
        )
        if not in_window:
            return False

    buffer = timedelta(minutes=BUFFER_MINUTES)
    overlapping = Booking.objects.filter(
        slot=slot,
        status__in=ACTIVE_BOOKING_STATUSES,
    ).filter(
        Q(start_time__lt=end_time + buffer) & Q(end_time__gt=start_time - buffer)
    )
    return not overlapping.exists()


def get_available_slots(*, society_id, vehicle_type, start_time, end_time, for_update=False):
    queryset = ParkingSlot.objects.filter(
        society_id=society_id,
        is_active=True,
        slot_type=vehicle_type,
    ).exclude(state=ParkingSlot.SlotState.BLOCKED)

    if for_update:
        queryset = queryset.select_for_update()

    slots = list(
        queryset.select_related("society").prefetch_related("availability_windows")
    )
    valid_slots = [
        slot
        for slot in slots
        if slot_is_available(slot, vehicle_type, start_time, end_time)
    ]
    valid_slots.sort(key=lambda slot: (slot.hourly_rate, slot.slot_number))
    return valid_slots


def _build_pending_booking(user, slot, vehicle, start_time, end_time):
    duration = end_time - start_time
    duration_hours = math.ceil(duration.total_seconds() / 3600)
    amount = slot.hourly_rate * duration_hours
    booking_number = _generate_booking_number()
    now = timezone.now()

    booking = Booking(
        booking_number=booking_number,
        user=user,
        vehicle=vehicle,
        slot=slot,
        start_time=start_time,
        end_time=end_time,
        status=Booking.Status.PENDING_PAYMENT,
        amount=amount,
        qr_code_token="placeholder",
        lock_expires_at=now + timedelta(seconds=LOCK_DURATION_SECONDS),
    )
    booking.save()
    booking.qr_code_token = generate_qr_token(booking)
    booking.save(update_fields=["qr_code_token"])

    from .tasks import expire_booking_lock
    import logging

    try:
        expire_booking_lock.apply_async(
            args=[str(booking.id)],
            countdown=LOCK_DURATION_SECONDS,
        )
    except Exception as e:
        logging.warning("Failed to queue expire_booking_lock task: %s", e)

    return booking


def create_booking(user, slot_id, vehicle, start_time, end_time):
    validate_booking_window(start_time, end_time)

    with transaction.atomic():
        try:
            slot = (
                ParkingSlot.objects.select_for_update()
                .select_related("society")
                .prefetch_related("availability_windows")
                .get(id=slot_id, is_active=True)
            )
        except ParkingSlot.DoesNotExist:
            raise ValidationError("Slot not found or inactive.")

        if not slot_is_available(slot, vehicle.vehicle_type, start_time, end_time):
            raise ValidationError("Slot is not available for the requested time range.")

        return _build_pending_booking(user, slot, vehicle, start_time, end_time)


def create_booking_for_society(user, society_id, vehicle, start_time, end_time):
    validate_booking_window(start_time, end_time)

    with transaction.atomic():
        valid_slots = get_available_slots(
            society_id=society_id,
            vehicle_type=vehicle.vehicle_type,
            start_time=start_time,
            end_time=end_time,
            for_update=True,
        )
        if not valid_slots:
            raise ValidationError("No available slots found for the selected society.")

        return _build_pending_booking(
            user=user,
            slot=valid_slots[0],
            vehicle=vehicle,
            start_time=start_time,
            end_time=end_time,
        )


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
