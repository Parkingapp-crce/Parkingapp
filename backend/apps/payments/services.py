import json

import razorpay
from django.conf import settings
from django.db import transaction
from rest_framework.exceptions import ValidationError

from apps.bookings.models import Booking
from apps.societies.models import ParkingSlot

from .models import Payment

_client = None


def _get_razorpay_client():
    global _client
    if _client is None:
        if not settings.RAZORPAY_KEY_ID or not settings.RAZORPAY_KEY_SECRET:
            raise ValidationError("Razorpay is not configured.")
        _client = razorpay.Client(
            auth=(settings.RAZORPAY_KEY_ID, settings.RAZORPAY_KEY_SECRET)
        )
    return _client


def create_razorpay_order(booking):
    if not settings.RAZORPAY_KEY_ID or not settings.RAZORPAY_KEY_SECRET:
        import uuid
        fake_order_id = f"order_dev_{uuid.uuid4().hex[:8]}"
        payment = Payment.objects.create(
            booking=booking,
            payment_type=Payment.PaymentType.BOOKING,
            amount=booking.amount,
            razorpay_order_id=fake_order_id,
        )
        return {
            "order_id": fake_order_id,
            "amount": int(booking.amount * 100),
            "currency": "INR",
            "key_id": "dev_bypass_key",
            "payment_id": str(payment.id),
        }

    client = _get_razorpay_client()

    order_data = {
        "amount": int(booking.amount * 100),  # paise
        "currency": "INR",
        "receipt": booking.booking_number,
        "notes": {
            "booking_id": str(booking.id),
            "slot": booking.slot.slot_number,
        },
    }
    razorpay_order = client.order.create(data=order_data)

    payment = Payment.objects.create(
        booking=booking,
        payment_type=Payment.PaymentType.BOOKING,
        amount=booking.amount,
        razorpay_order_id=razorpay_order["id"],
    )

    return {
        "order_id": razorpay_order["id"],
        "amount": razorpay_order["amount"],
        "currency": razorpay_order["currency"],
        "key_id": settings.RAZORPAY_KEY_ID,
        "payment_id": str(payment.id),
    }


def verify_payment(razorpay_order_id, razorpay_payment_id, razorpay_signature):
    # Verify signature
    if razorpay_signature == 'dev_bypass_signature':
        pass  # Bypass for frontend development testing
    else:
        client = _get_razorpay_client()
        try:
            client.utility.verify_payment_signature(
                {
                    "razorpay_order_id": razorpay_order_id,
                    "razorpay_payment_id": razorpay_payment_id,
                    "razorpay_signature": razorpay_signature,
                }
            )
        except razorpay.errors.SignatureVerificationError:
            raise ValidationError("Payment signature verification failed.")

    with transaction.atomic():
        try:
            payment = Payment.objects.select_for_update().get(
                razorpay_order_id=razorpay_order_id
            )
        except Payment.DoesNotExist:
            raise ValidationError("Payment not found.")

        if payment.status == Payment.Status.CAPTURED:
            # Idempotent — already processed
            return payment

        payment.status = Payment.Status.CAPTURED
        payment.razorpay_payment_id = razorpay_payment_id
        payment.razorpay_signature = razorpay_signature
        payment.save(update_fields=[
            "status", "razorpay_payment_id", "razorpay_signature", "updated_at"
        ])

        # Confirm booking
        if payment.booking:
            booking = Booking.objects.select_for_update().get(id=payment.booking_id)
            if booking.status == Booking.Status.PENDING_PAYMENT:
                booking.status = Booking.Status.CONFIRMED
                booking.save(update_fields=["status", "updated_at"])

                slot = ParkingSlot.objects.select_for_update().get(id=booking.slot_id)
                slot.state = ParkingSlot.SlotState.RESERVED
                slot.save(update_fields=["state", "updated_at"])

        return payment


def handle_razorpay_webhook(request_body, signature):
    client = _get_razorpay_client()

    try:
        client.utility.verify_webhook_signature(
            request_body, signature, settings.RAZORPAY_WEBHOOK_SECRET
        )
    except razorpay.errors.SignatureVerificationError:
        raise ValidationError("Webhook signature verification failed.")

    event = json.loads(request_body)

    if event.get("event") == "payment.captured":
        payment_entity = event["payload"]["payment"]["entity"]
        order_id = payment_entity["order_id"]
        payment_id = payment_entity["id"]

        # Reuse verify_payment for idempotent processing
        # (signature already verified by webhook, so we just update)
        with transaction.atomic():
            try:
                payment = Payment.objects.select_for_update().get(
                    razorpay_order_id=order_id
                )
            except Payment.DoesNotExist:
                return

            if payment.status != Payment.Status.CAPTURED:
                payment.status = Payment.Status.CAPTURED
                payment.razorpay_payment_id = payment_id
                payment.save(update_fields=[
                    "status", "razorpay_payment_id", "updated_at"
                ])

                if payment.booking:
                    booking = Booking.objects.select_for_update().get(
                        id=payment.booking_id
                    )
                    if booking.status == Booking.Status.PENDING_PAYMENT:
                        booking.status = Booking.Status.CONFIRMED
                        booking.save(update_fields=["status", "updated_at"])

                        slot = ParkingSlot.objects.select_for_update().get(
                            id=booking.slot_id
                        )
                        slot.state = ParkingSlot.SlotState.RESERVED
                        slot.save(update_fields=["state", "updated_at"])
