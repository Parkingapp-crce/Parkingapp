from django.db import transaction
from django.utils import timezone
from rest_framework.exceptions import ValidationError

from apps.bookings.models import Booking
from apps.penalties.services import create_overstay_penalty
from apps.societies.models import ParkingSlot
from utils.qr import decode_qr_token


def validate_entry(qr_token):
    try:
        payload = decode_qr_token(qr_token)
    except Exception:
        raise ValidationError("Invalid QR code.")

    now = timezone.now()

    with transaction.atomic():
        try:
            booking = Booking.objects.select_for_update().get(
                id=payload["booking_id"],
                qr_code_token=qr_token,
            )
        except Booking.DoesNotExist:
            raise ValidationError("Booking not found.")

        if booking.status != Booking.Status.CONFIRMED:
            raise ValidationError(
                f"Booking is in '{booking.get_status_display()}' state. "
                "Only confirmed bookings allow entry."
            )

        if now < booking.start_time:
            raise ValidationError(
                f"Early arrival. Entry is not permitted before "
                f"{booking.start_time.strftime('%H:%M')}."
            )

        if now > booking.end_time:
            raise ValidationError("Booking has expired. Entry denied.")

        # Mark entry
        booking.status = Booking.Status.ACTIVE
        booking.actual_entry = now
        booking.save(update_fields=["status", "actual_entry", "updated_at"])

        slot = ParkingSlot.objects.select_for_update().get(id=booking.slot_id)
        slot.state = ParkingSlot.SlotState.OCCUPIED
        slot.save(update_fields=["state", "updated_at"])

    return {
        "status": "entry_granted",
        "booking_number": booking.booking_number,
        "slot_number": booking.slot.slot_number,
        "vehicle_reg": booking.vehicle.registration_no,
        "start_time": booking.start_time.isoformat(),
        "end_time": booking.end_time.isoformat(),
    }


def validate_exit(qr_token):
    try:
        payload = decode_qr_token(qr_token)
    except Exception:
        raise ValidationError("Invalid QR code.")

    now = timezone.now()

    with transaction.atomic():
        try:
            booking = Booking.objects.select_for_update().get(
                id=payload["booking_id"],
                qr_code_token=qr_token,
            )
        except Booking.DoesNotExist:
            raise ValidationError("Booking not found.")

        if booking.status != Booking.Status.ACTIVE:
            raise ValidationError(
                f"Booking is in '{booking.get_status_display()}' state. "
                "Only active bookings allow exit."
            )

        # Mark exit
        booking.status = Booking.Status.COMPLETED
        booking.actual_exit = now
        booking.save(update_fields=["status", "actual_exit", "updated_at"])

        slot = ParkingSlot.objects.select_for_update().get(id=booking.slot_id)
        slot.state = ParkingSlot.SlotState.AVAILABLE
        slot.save(update_fields=["state", "updated_at"])

    # Check overstay
    penalty_info = None
    if now > booking.end_time:
        overstay_minutes = int((now - booking.end_time).total_seconds() / 60)
        penalty_info = create_overstay_penalty(booking, overstay_minutes)

    return {
        "status": "exit_granted",
        "booking_number": booking.booking_number,
        "slot_number": booking.slot.slot_number,
        "vehicle_reg": booking.vehicle.registration_no,
        "entry_time": booking.actual_entry.isoformat() if booking.actual_entry else None,
        "exit_time": now.isoformat(),
        "overstay": penalty_info is not None,
        "penalty": penalty_info,
    }
