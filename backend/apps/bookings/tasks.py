from celery import shared_task
from django.db import transaction
from django.utils import timezone


@shared_task
def expire_booking_lock(booking_id):
    from apps.bookings.models import Booking

    with transaction.atomic():
        try:
            booking = Booking.objects.select_for_update().get(id=booking_id)
        except Booking.DoesNotExist:
            return

        if booking.status == Booking.Status.PENDING_PAYMENT:
            booking.status = Booking.Status.EXPIRED
            booking.save(update_fields=["status", "updated_at"])


@shared_task
def detect_no_shows():
    from apps.bookings.models import Booking
    from apps.societies.models import ParkingSlot

    now = timezone.now()

    with transaction.atomic():
        expired_bookings = (
            Booking.objects.select_for_update()
            .filter(
                status=Booking.Status.CONFIRMED,
                end_time__lte=now,
                actual_entry__isnull=True,
            )
        )

        for booking in expired_bookings:
            booking.status = Booking.Status.NO_SHOW
            booking.save(update_fields=["status", "updated_at"])

            slot = ParkingSlot.objects.select_for_update().get(id=booking.slot_id)
            if slot.state == ParkingSlot.SlotState.RESERVED:
                slot.state = ParkingSlot.SlotState.AVAILABLE
                slot.save(update_fields=["state", "updated_at"])
