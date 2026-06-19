from django.conf import settings
from rest_framework import serializers

from .models import Payment, Refund


class PaymentInitiateSerializer(serializers.Serializer):
    booking_id = serializers.UUIDField()
    embedded = serializers.BooleanField(required=False, default=False)
    gateway = serializers.ChoiceField(
        choices=["stripe", "razorpay"],
        required=False,
        default="stripe",
    )


class PaymentVerifySerializer(serializers.Serializer):
    checkout_session_id = serializers.CharField()


class PaymentSerializer(serializers.ModelSerializer):
    checkout_url = serializers.SerializerMethodField()
    checkout_client_secret = serializers.SerializerMethodField()
    stripe_publishable_key = serializers.SerializerMethodField()
    razorpay_key_id = serializers.SerializerMethodField()

    class Meta:
        model = Payment
        fields = [
            "id",
            "booking",
            "penalty",
            "payment_type",
            "amount",
            "currency",
            "provider",
            "razorpay_order_id",
            "razorpay_payment_id",
            "stripe_checkout_session_id",
            "stripe_payment_intent_id",
            "status",
            "created_at",
            "checkout_url",
            "checkout_client_secret",
            "stripe_publishable_key",
            "razorpay_key_id",
        ]
        read_only_fields = fields

    def get_checkout_url(self, obj):
        return self.context.get("checkout_url")

    def get_checkout_client_secret(self, obj):
        return self.context.get("checkout_client_secret")

    def get_stripe_publishable_key(self, obj):
        return self.context.get("stripe_publishable_key")

    def get_razorpay_key_id(self, obj):
        return settings.RAZORPAY_KEY_ID


class RefundSerializer(serializers.ModelSerializer):
    initiated_by_name = serializers.CharField(
        source="initiated_by.full_name", read_only=True, default=""
    )
    initiated_by_email = serializers.CharField(
        source="initiated_by.email", read_only=True, default=""
    )
    booking_number = serializers.CharField(
        source="booking.booking_number", read_only=True, default=""
    )
    payment_provider = serializers.CharField(
        source="payment.provider", read_only=True, default=""
    )

    class Meta:
        model = Refund
        fields = [
            "id",
            "payment",
            "booking",
            "booking_number",
            "initiated_by",
            "initiated_by_name",
            "initiated_by_email",
            "refund_amount",
            "reason",
            "provider_refund_id",
            "payment_provider",
            "status",
            "is_full_refund",
            "created_at",
        ]
        read_only_fields = fields

