import uuid

from django.db import models


class Payment(models.Model):
    class Provider(models.TextChoices):
        RAZORPAY = "razorpay", "Razorpay"
        STRIPE = "stripe", "Stripe"

    class Status(models.TextChoices):
        CREATED = "created", "Created"
        CAPTURED = "captured", "Captured"
        FAILED = "failed", "Failed"
        REFUNDED = "refunded", "Refunded"
        PARTIALLY_REFUNDED = "partially_refunded", "Partially Refunded"

    class PaymentType(models.TextChoices):
        BOOKING = "booking", "Booking"
        PENALTY = "penalty", "Penalty"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    booking = models.ForeignKey(
        "bookings.Booking",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="payments",
    )
    penalty = models.ForeignKey(
        "penalties.Penalty",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="payments",
    )
    payment_type = models.CharField(max_length=20, choices=PaymentType.choices)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=10, default="INR")
    provider = models.CharField(
        max_length=20, choices=Provider.choices, default=Provider.STRIPE
    )
    razorpay_order_id = models.CharField(max_length=100, null=True, blank=True, unique=True)
    razorpay_payment_id = models.CharField(max_length=100, null=True, blank=True)
    razorpay_signature = models.CharField(max_length=255, null=True, blank=True)
    stripe_checkout_session_id = models.CharField(
        max_length=255, null=True, blank=True, unique=True
    )
    stripe_payment_intent_id = models.CharField(
        max_length=255, null=True, blank=True, unique=True
    )
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.CREATED
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        reference = (
            self.stripe_checkout_session_id
            or self.razorpay_order_id
            or str(self.id)
        )
        return f"Payment {reference} - {self.status}"


class Refund(models.Model):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        SUCCEEDED = "succeeded", "Succeeded"
        FAILED = "failed", "Failed"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    payment = models.ForeignKey(
        Payment,
        on_delete=models.CASCADE,
        related_name="refunds",
    )
    booking = models.ForeignKey(
        "bookings.Booking",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="refunds",
    )
    initiated_by = models.ForeignKey(
        "accounts.User",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="initiated_refunds",
    )
    refund_amount = models.DecimalField(max_digits=10, decimal_places=2)
    reason = models.TextField(blank=True, default="")
    provider_refund_id = models.CharField(max_length=255, blank=True, default="")
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.PENDING
    )
    is_full_refund = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Refund ₹{self.refund_amount} for Payment {self.payment_id} - {self.status}"
