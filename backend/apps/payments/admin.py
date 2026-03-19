from django.contrib import admin

from .models import Payment


@admin.register(Payment)
class PaymentAdmin(admin.ModelAdmin):
    list_display = ("razorpay_order_id", "payment_type", "amount", "status", "created_at")
    list_filter = ("status", "payment_type")
    search_fields = ("razorpay_order_id", "razorpay_payment_id")
    readonly_fields = ("razorpay_order_id", "razorpay_payment_id", "razorpay_signature")
