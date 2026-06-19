import re

filepath = 'backend/apps/payments/views.py'
with open(filepath, 'r') as f:
    content = f.read()

# Fix the call to create_bypass_payment to pass gateway
content = content.replace(
    'payment = create_bypass_payment(booking, request)',
    'payment = create_bypass_payment(booking, request, gateway=gateway)'
)
content = content.replace(
    'payment = create_bypass_penalty_payment(penalty, request)',
    'payment = create_bypass_penalty_payment(penalty, request, gateway=gateway)'
)

with open(filepath, 'w') as f:
    f.write(content)

filepath = 'backend/apps/payments/services.py'
with open(filepath, 'r') as f:
    content = f.read()

# Fix create_bypass_payment signature and logic
bypass_payment_old = """def create_bypass_payment(booking, request=None):
    \"\"\"Create a test payment that bypasses external gateways and marks booking confirmed."""
bypass_payment_new = """def create_bypass_payment(booking, request=None, gateway='stripe'):
    \"\"\"Create a test payment that bypasses external gateways and marks booking confirmed."""
content = content.replace(bypass_payment_old, bypass_payment_new)

bypass_payment_body_old = """        payment = Payment.objects.create(
            booking=booking,
            payment_type=Payment.PaymentType.BOOKING,
            amount=booking.amount,
            currency=(booking.amount and "INR") or "INR",
            provider=Payment.Provider.STRIPE,
            stripe_checkout_session_id=f"bypass-{booking.booking_number}",
            stripe_payment_intent_id=f"bypass-{booking.booking_number}",
            status=Payment.Status.CAPTURED,
        )"""
bypass_payment_body_new = """        provider = Payment.Provider.RAZORPAY if gateway == 'razorpay' else Payment.Provider.STRIPE
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
        )"""
content = content.replace(bypass_payment_body_old, bypass_payment_body_new)


# Fix create_bypass_penalty_payment signature and logic
bypass_penalty_old = """def create_bypass_penalty_payment(penalty, request=None):
    \"\"\"Create a test payment that bypasses external gateways and marks penalty as paid."""
bypass_penalty_new = """def create_bypass_penalty_payment(penalty, request=None, gateway='stripe'):
    \"\"\"Create a test payment that bypasses external gateways and marks penalty as paid."""
content = content.replace(bypass_penalty_old, bypass_penalty_new)

bypass_penalty_body_old = """        payment = Payment.objects.create(
            user=penalty.booking.user,
            penalty=penalty,
            payment_type=Payment.PaymentType.PENALTY,
            amount=penalty.amount,
            currency="INR",
            provider=Payment.Provider.STRIPE,
            stripe_checkout_session_id=f"bypass-pen-{penalty.id}",
            stripe_payment_intent_id=f"bypass-pen-{penalty.id}",
            status=Payment.Status.CAPTURED,
        )"""
bypass_penalty_body_new = """        provider = Payment.Provider.RAZORPAY if gateway == 'razorpay' else Payment.Provider.STRIPE
        payment = Payment.objects.create(
            user=penalty.booking.user,
            penalty=penalty,
            payment_type=Payment.PaymentType.PENALTY,
            amount=penalty.amount,
            currency="INR",
            provider=provider,
            stripe_checkout_session_id=f"bypass-pen-{penalty.id}" if provider == Payment.Provider.STRIPE else None,
            stripe_payment_intent_id=f"bypass-pen-{penalty.id}" if provider == Payment.Provider.STRIPE else None,
            razorpay_order_id=f"bypass-rzp-{penalty.id}" if provider == Payment.Provider.RAZORPAY else None,
            status=Payment.Status.CAPTURED,
        )"""
content = content.replace(bypass_penalty_body_old, bypass_penalty_body_new)

with open(filepath, 'w') as f:
    f.write(content)

