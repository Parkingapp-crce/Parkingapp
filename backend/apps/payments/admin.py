from django.contrib import admin

from .models import Payment


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = (
        "provider",
        "razorpay_order_id",
        "payment_type",
        "amount",
        "status",
        "created_at",
    )
    list_filter = ("provider", "status", "payment_type")
    search_fields = (
        "razorpay_order_id",
        "razorpay_payment_id",
        "stripe_checkout_session_id",
        "stripe_payment_intent_id",
    )
    readonly_fields = (
        "provider",
        "currency",
        "razorpay_order_id",
        "razorpay_payment_id",
        "razorpay_signature",
        "stripe_checkout_session_id",
        "stripe_payment_intent_id",
    )
