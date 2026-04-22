from django.db import transaction
from django.utils import timezone
from rest_framework.exceptions import ValidationError

from apps.bookings.models import Booking
from apps.penalties.services import create_overstay_penalty
from apps.societies.models import ParkingSlot
from utils.qr import decode_qr_token

from .models import ScanEvent


def _payment_status_for_booking(booking):
    latest_payment = booking.payments.order_by("-created_at").first()
    return latest_payment.status if latest_payment else "unpaid"


def _build_scan_response(*, booking, event_type, now, penalty_info=None):
    return {
        "status": f"{event_type}_granted",
        "booking_id": str(booking.id),
        "booking_number": booking.booking_number,
        "slot_number": booking.slot.slot_number,
        "vehicle_number": booking.vehicle.registration_no,
        "owner_name": booking.user.full_name,
        "owner_email": booking.user.email,
        "owner_phone": booking.user.phone,
        "payment_status": _payment_status_for_booking(booking),
        "start_time": booking.start_time.isoformat(),
        "end_time": booking.end_time.isoformat(),
        "entry_time": booking.actual_entry.isoformat() if booking.actual_entry else None,
        "exit_time": booking.actual_exit.isoformat() if booking.actual_exit else None,
        "processed_at": now.isoformat(),
        "overstay": penalty_info is not None,
        "penalty": penalty_info,
    }


def _record_scan_event(*, booking, guard, event_type, result, error_message=""):
    ScanEvent.objects.create(
        booking=booking,
        guard=guard,
        society=guard.society,
        event_type=event_type,
        result=result,
        error_message=error_message,
    )


def validate_entry(qr_token, guard):
    try:
        payload = decode_qr_token(qr_token)
    except Exception:
        _record_scan_event(
            booking=None,
            guard=guard,
            event_type=ScanEvent.EventType.ENTRY,
            result=ScanEvent.Result.DENIED,
            error_message="Invalid QR code.",
        )
        raise ValidationError("Invalid QR code.")

    now = timezone.now()
    booking = None

    try:
        with transaction.atomic():
            try:
                booking = Booking.objects.select_for_update().get(
                    id=payload["booking_id"],
                    qr_code_token=qr_token,
                )
            except Booking.DoesNotExist as exc:
                raise ValidationError("Booking not found.") from exc

            if booking.slot.society_id != guard.society_id:
                raise ValidationError("This booking does not belong to your society.")

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
    except ValidationError as exc:
        detail = exc.detail[0] if isinstance(exc.detail, list) else exc.detail
        _record_scan_event(
            booking=booking,
            guard=guard,
            event_type=ScanEvent.EventType.ENTRY,
            result=ScanEvent.Result.DENIED,
            error_message=str(detail),
        )
        raise

    _record_scan_event(
        booking=booking,
        guard=guard,
        event_type=ScanEvent.EventType.ENTRY,
        result=ScanEvent.Result.APPROVED,
    )

    return _build_scan_response(booking=booking, event_type="entry", now=now)


def validate_exit(qr_token, guard):
    try:
        payload = decode_qr_token(qr_token)
    except Exception:
        _record_scan_event(
            booking=None,
            guard=guard,
            event_type=ScanEvent.EventType.EXIT,
            result=ScanEvent.Result.DENIED,
            error_message="Invalid QR code.",
        )
        raise ValidationError("Invalid QR code.")

    now = timezone.now()
    booking = None

    try:
        with transaction.atomic():
            try:
                booking = Booking.objects.select_for_update().get(
                    id=payload["booking_id"],
                    qr_code_token=qr_token,
                )
            except Booking.DoesNotExist as exc:
                raise ValidationError("Booking not found.") from exc

            if booking.slot.society_id != guard.society_id:
                raise ValidationError("This booking does not belong to your society.")

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
    except ValidationError as exc:
        detail = exc.detail[0] if isinstance(exc.detail, list) else exc.detail
        _record_scan_event(
            booking=booking,
            guard=guard,
            event_type=ScanEvent.EventType.EXIT,
            result=ScanEvent.Result.DENIED,
            error_message=str(detail),
        )
        raise

    # Check overstay
    penalty_info = None
    if now > booking.end_time:
        overstay_minutes = int((now - booking.end_time).total_seconds() / 60)
        penalty_info = create_overstay_penalty(booking, overstay_minutes)

    _record_scan_event(
        booking=booking,
        guard=guard,
        event_type=ScanEvent.EventType.EXIT,
        result=ScanEvent.Result.APPROVED,
    )

    return _build_scan_response(
        booking=booking,
        event_type="exit",
        now=now,
        penalty_info=penalty_info,
    )
