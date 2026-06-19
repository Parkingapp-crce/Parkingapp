import json
from decimal import Decimal
from urllib.parse import urlparse

import stripe
import razorpay
from django.conf import settings
from django.db import transaction
from rest_framework.exceptions import ValidationError

from apps.bookings.models import Booking
from apps.societies.models import ParkingSlot

from .models import Payment


MONEY_MULTIPLIER = Decimal("100")


def _get_stripe_client():
    if not settings.STRIPE_SECRET_KEY:
        raise ValidationError("Stripe is not configured.")

    stripe.api_key = settings.STRIPE_SECRET_KEY
    return stripe


def sync_razorpay_order_status(razorpay_order_id):
    """
    Polls the Razorpay API to check if an order has been paid.
    Useful for auto-verification if the frontend callback fails.
    """
    client = _get_razorpay_client()
    try:
        # Fetch the order from Razorpay
        order = client.order.fetch(razorpay_order_id)
        # Fetch payments for this order
        payments = client.order.payments(razorpay_order_id)
        
        if not payments or not payments.get("items"):
            return False

        # Look for a captured payment
        captured_payment = next(
            (p for p in payments["items"] if p["status"] == "captured"), 
            None
        )

        if captured_payment:
            from .models import Payment
            from apps.bookings.models import Booking

            with transaction.atomic():
                payment_obj = Payment.objects.select_for_update().get(
                    razorpay_order_id=razorpay_order_id
                )
                if payment_obj.status != Payment.Status.CAPTURED:
                    payment_obj.status = Payment.Status.CAPTURED
                    payment_obj.razorpay_payment_id = captured_payment["id"]
                    payment_obj.razorpay_signature = "auto_verified"
                    payment_obj.save()

                    if payment_obj.booking:
                        booking = payment_obj.booking
                        booking.status = Booking.Status.CONFIRMED
                        booking.save()
            return True
    except Exception as e:
        print(f"Error syncing Razorpay order {razorpay_order_id}: {e}")
    
    return False


def _get_razorpay_client():
    if not settings.RAZORPAY_KEY_ID or not settings.RAZORPAY_KEY_SECRET:
        raise ValidationError("Razorpay is not configured.")

    return razorpay.Client(
        auth=(settings.RAZORPAY_KEY_ID, settings.RAZORPAY_KEY_SECRET)
    )


def _resolve_frontend_base_url(request=None):
    candidates = []
    if request is not None:
        origin = request.headers.get("Origin")
        referer = request.headers.get("Referer")
        if origin:
            candidates.append(origin)
        if referer:
            candidates.append(referer)

    candidates.append(settings.FRONTEND_BASE_URL)

    for candidate in candidates:
        parsed = urlparse(candidate)
        if parsed.scheme and parsed.netloc:
            return f"{parsed.scheme}://{parsed.netloc}"

    return "http://127.0.0.1:3000"


def _amount_in_smallest_unit(amount):
    return int((Decimal(amount) * MONEY_MULTIPLIER).quantize(Decimal("1")))


def _payment_intent_id(payment_intent):
    if isinstance(payment_intent, str):
        return payment_intent
    if isinstance(payment_intent, dict):
        return payment_intent.get("id")
    return getattr(payment_intent, "id", None)


def _mark_booking_as_confirmed(payment):
    if not payment.booking_id:
        return payment

    booking = Booking.objects.select_for_update().get(id=payment.booking_id)
    if booking.status == Booking.Status.PENDING_PAYMENT:
        booking.status = Booking.Status.CONFIRMED
        booking.save(update_fields=["status", "updated_at"])

        slot = ParkingSlot.objects.select_for_update().get(id=booking.slot_id)
        slot.state = ParkingSlot.SlotState.RESERVED
        slot.save(update_fields=["state", "updated_at"])

    return payment


def _mark_penalty_as_paid(payment):
    if not payment.penalty_id:
        return payment

    penalty = payment.penalty
    if penalty and penalty.status == penalty.Status.UNPAID:
        penalty.status = penalty.Status.PAID
        penalty.save(update_fields=["status", "updated_at"])

    return payment


def create_stripe_checkout_session(booking, request=None, embedded=False):
    stripe_client = _get_stripe_client()
    frontend_base_url = _resolve_frontend_base_url(request)

    return_url = (
        f"{frontend_base_url}/bookings/{booking.id}"
        "?checkout=success&session_id={CHECKOUT_SESSION_ID}"
    )
    session_params = dict(
        client_reference_id=str(booking.id),
        customer_email=booking.user.email or None,
        mode="payment",
        metadata={
            "booking_id": str(booking.id),
            "booking_number": booking.booking_number,
        },
        payment_intent_data={
            "metadata": {
                "booking_id": str(booking.id),
                "booking_number": booking.booking_number,
            }
        },
        line_items=[
            {
                "quantity": 1,
                "price_data": {
                    "currency": "inr",
                    "unit_amount": _amount_in_smallest_unit(booking.amount),
                    "product_data": {
                        "name": f"Parking Booking {booking.booking_number}",
                        "description": (
                            f"Slot {booking.slot.slot_number} "
                            f"at {booking.slot.society.name}"
                        ),
                    },
                },
            }
        ],
    )

    if embedded:
        session_params.update(
            ui_mode="embedded",
            redirect_on_completion="never",
        )
    else:
        session_params.update(
            success_url=return_url,
            cancel_url=f"{frontend_base_url}/bookings/{booking.id}?checkout=cancelled",
        )

    checkout_session = stripe_client.checkout.Session.create(**session_params)

    payment = Payment.objects.create(
        booking=booking,
        payment_type=Payment.PaymentType.BOOKING,
        amount=booking.amount,
        currency="INR",
        provider=Payment.Provider.STRIPE,
        stripe_checkout_session_id=checkout_session.id,
        stripe_payment_intent_id=_payment_intent_id(checkout_session.payment_intent),
    )

    return (
        payment,
        checkout_session.url,
        getattr(checkout_session, "client_secret", None),
    )


def create_razorpay_order(booking, request=None):
    client = _get_razorpay_client()

    order_params = {
        "amount": _amount_in_smallest_unit(booking.amount),
        "currency": "INR",
        "receipt": booking.booking_number,
        "notes": {
            "booking_id": str(booking.id),
            "booking_number": booking.booking_number,
            "user_email": booking.user.email,
        },
    }

    razorpay_order = client.order.create(data=order_params)

    payment = Payment.objects.create(
        booking=booking,
        payment_type=Payment.PaymentType.BOOKING,
        amount=booking.amount,
        currency="INR",
        provider=Payment.Provider.RAZORPAY,
        razorpay_order_id=razorpay_order["id"],
    )

    return payment, razorpay_order["id"]


def create_bypass_payment(booking, request=None, gateway='stripe'):
    """Create a test payment that bypasses external gateways and marks booking confirmed.

    This is intended for local/dev setups where payment gateway credentials are not
    yet configured. It creates a Payment with status CAPTURED and runs the same
    confirmation logic so the booking and slot become reserved and a QR token exists.
    """
    with transaction.atomic():
        provider = Payment.Provider.RAZORPAY if gateway == 'razorpay' else Payment.Provider.STRIPE
        payment = Payment.objects.create(
            booking=booking,
            payment_type=Payment.PaymentType.BOOKING,
            amount=booking.amount,
            currency=(booking.amount and "INR") or "INR",
            provider=provider,
            stripe_checkout_session_id=f"bypass-{booking.booking_number}" if provider == Payment.Provider.STRIPE else None,
            stripe_payment_intent_id=f"bypass-{booking.booking_number}" if provider == Payment.Provider.STRIPE else None,
            razorpay_order_id=f"bypass-rzp-{booking.booking_number}" if provider == Payment.Provider.RAZORPAY else None,
            status=Payment.Status.CAPTURED,
        )

        # Reuse existing confirmation logic to reserve slot and set booking status
        _mark_booking_as_confirmed(payment)

    return payment


def create_bypass_penalty_payment(penalty, request=None, gateway='stripe'):
    """Create a test payment that bypasses external gateways and marks penalty as paid.
    """
    with transaction.atomic():
        payment = Payment.objects.create(
            penalty=penalty,
            payment_type=Payment.PaymentType.PENALTY,
            amount=penalty.amount,
            currency=(penalty.amount and "INR") or "INR",
            provider=Payment.Provider.STRIPE,
            stripe_checkout_session_id=f"bypass-pen-{penalty.id}",
            stripe_payment_intent_id=f"bypass-pen-{penalty.id}",
            status=Payment.Status.CAPTURED,
        )

        _mark_penalty_as_paid(payment)

    return payment


def create_stripe_penalty_checkout_session(penalty, request=None, embedded=False):
    stripe_client = _get_stripe_client()
    frontend_base_url = _resolve_frontend_base_url(request)

    success_url = (
        f"{frontend_base_url}/bookings/{penalty.booking_id}"
        "?checkout=success&session_id={CHECKOUT_SESSION_ID}"
    )
    cancel_url = f"{frontend_base_url}/bookings/{penalty.booking_id}?checkout=cancelled"

    session_params = dict(
        mode="payment",
        client_reference_id=str(penalty.id),
        customer_email=penalty.user.email or None,
        metadata={
            "penalty_id": str(penalty.id),
            "booking_id": str(penalty.booking_id),
        },
        payment_intent_data={
            "metadata": {
                "penalty_id": str(penalty.id),
                "booking_id": str(penalty.booking_id),
            }
        },
        line_items=[
            {
                "quantity": 1,
                "price_data": {
                    "currency": "inr",
                    "unit_amount": _amount_in_smallest_unit(penalty.amount),
                    "product_data": {
                        "name": f"Parking Penalty {penalty.id}",
                        "description": (
                            f"Penalty for booking {penalty.booking.booking_number}"
                        ),
                    },
                },
            }
        ],
    )

    if embedded:
        session_params.update(
            ui_mode="embedded",
            redirect_on_completion="never",
        )
    else:
        session_params.update(
            success_url=success_url,
            cancel_url=cancel_url,
        )

    checkout_session = stripe_client.checkout.Session.create(**session_params)

    payment = Payment.objects.create(
        penalty=penalty,
        payment_type=Payment.PaymentType.PENALTY,
        amount=penalty.amount,
        currency="INR",
        provider=Payment.Provider.STRIPE,
        stripe_checkout_session_id=checkout_session.id,
        stripe_payment_intent_id=_payment_intent_id(checkout_session.payment_intent),
    )

    return (
        payment,
        checkout_session.url,
        getattr(checkout_session, "client_secret", None),
    )


def create_razorpay_penalty_order(penalty, request=None):
    client = _get_razorpay_client()

    order_params = {
        "amount": _amount_in_smallest_unit(penalty.amount),
        "currency": "INR",
        "receipt": f"pen_{penalty.id}",
        "notes": {
            "penalty_id": str(penalty.id),
            "booking_id": str(penalty.booking_id),
            "user_email": penalty.user.email,
        },
    }

    razorpay_order = client.order.create(data=order_params)

    payment = Payment.objects.create(
        penalty=penalty,
        payment_type=Payment.PaymentType.PENALTY,
        amount=penalty.amount,
        currency="INR",
        provider=Payment.Provider.RAZORPAY,
        razorpay_order_id=razorpay_order["id"],
    )

    return payment, razorpay_order["id"]


def verify_checkout_session(checkout_session_id, user=None):
    stripe_client = _get_stripe_client()
    checkout_session = stripe_client.checkout.Session.retrieve(
        checkout_session_id,
        expand=["payment_intent"],
    )

    with transaction.atomic():
        payment_query = Payment.objects.select_for_update()
        try:
            payment = payment_query.get(stripe_checkout_session_id=checkout_session_id)
        except Payment.DoesNotExist as exc:
            raise ValidationError("Payment not found.") from exc

        if user is not None and payment.booking and payment.booking.user_id != user.id:
            raise ValidationError("Payment does not belong to this user.")

        payment.provider = Payment.Provider.STRIPE
        payment.currency = (
            checkout_session.currency or payment.currency or "inr"
        ).upper()
        payment.stripe_payment_intent_id = _payment_intent_id(
            checkout_session.payment_intent
        )

        if payment.status == Payment.Status.CAPTURED:
            payment.save(
                update_fields=[
                    "provider",
                    "currency",
                    "stripe_payment_intent_id",
                    "updated_at",
                ]
            )
            return payment

        if checkout_session.payment_status != "paid":
            payment.status = Payment.Status.FAILED
            payment.save(
                update_fields=[
                    "provider",
                    "currency",
                    "stripe_payment_intent_id",
                    "status",
                    "updated_at",
                ]
            )
            raise ValidationError("Stripe checkout has not completed successfully.")

        payment.status = Payment.Status.CAPTURED
        payment.save(
            update_fields=[
                "provider",
                "currency",
                "stripe_payment_intent_id",
                "status",
                "updated_at",
            ]
        )

        _mark_booking_as_confirmed(payment)
        _mark_penalty_as_paid(payment)
        return payment


def verify_razorpay_payment(
    razorpay_order_id, razorpay_payment_id, razorpay_signature, user=None
):
    client = _get_razorpay_client()

    # Verify signature
    try:
        client.utility.verify_payment_signature(
            {
                "razorpay_order_id": razorpay_order_id,
                "razorpay_payment_id": razorpay_payment_id,
                "razorpay_signature": razorpay_signature,
            }
        )
    except razorpay.errors.SignatureVerificationError as exc:
        raise ValidationError("Invalid Razorpay signature.") from exc

    with transaction.atomic():
        payment_query = Payment.objects.select_for_update()
        try:
            payment = payment_query.get(razorpay_order_id=razorpay_order_id)
        except Payment.DoesNotExist as exc:
            raise ValidationError("Payment not found for this order ID.") from exc

        if user is not None and payment.booking and payment.booking.user_id != user.id:
            raise ValidationError("Payment does not belong to this user.")

        if payment.status == Payment.Status.CAPTURED:
            return payment

        payment.razorpay_payment_id = razorpay_payment_id
        payment.status = Payment.Status.CAPTURED
        payment.save(
            update_fields=["razorpay_payment_id", "status", "updated_at"]
        )

        _mark_booking_as_confirmed(payment)
        _mark_penalty_as_paid(payment)
        return payment


def handle_stripe_webhook(request_body, signature):
    stripe_client = _get_stripe_client()

    if not settings.STRIPE_WEBHOOK_SECRET:
        # In development without webhook secret, parse event directly (INSECURE - for testing only)
        import json
        event = json.loads(request_body)
    else:
        # Production: verify webhook signature
        event = stripe_client.Webhook.construct_event(
            payload=request_body,
            sig_header=signature,
            secret=settings.STRIPE_WEBHOOK_SECRET,
        )

    event_type = event.get("type")
    event_object = event.get("data", {}).get("object", {})

    if event_type == "checkout.session.completed":
        verify_checkout_session(event_object["id"])
        return

    if event_type == "payment_intent.payment_failed":
        payment_intent_id = event_object.get("id")
        if not payment_intent_id:
            return

        with transaction.atomic():
            payment = (
                Payment.objects.select_for_update()
                .filter(stripe_payment_intent_id=payment_intent_id)
                .first()
            )
            if payment is None:
                return

            payment.status = Payment.Status.FAILED
            payment.save(update_fields=["status", "updated_at"])


def serialize_stripe_event(request_body):
    return json.loads(request_body)
