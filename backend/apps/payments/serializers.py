from django.conf import settings
from rest_framework import serializers

from .models import Payment


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
