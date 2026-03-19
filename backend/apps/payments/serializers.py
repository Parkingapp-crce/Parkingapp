from rest_framework import serializers

from .models import Payment


class PaymentInitiateSerializer(serializers.Serializer):
    booking_id = serializers.UUIDField()


class PaymentVerifySerializer(serializers.Serializer):
    razorpay_order_id = serializers.CharField()
    razorpay_payment_id = serializers.CharField()
    razorpay_signature = serializers.CharField()


class PaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Payment
        fields = [
            "id", "booking", "penalty", "payment_type", "amount",
            "razorpay_order_id", "razorpay_payment_id", "status", "created_at",
        ]
        read_only_fields = fields
