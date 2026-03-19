from rest_framework import serializers

from .models import Penalty


class PenaltySerializer(serializers.ModelSerializer):
    booking_number = serializers.CharField(source="booking.booking_number", read_only=True)

    class Meta:
        model = Penalty
        fields = [
            "id", "booking", "booking_number", "user",
            "overstay_minutes", "amount", "status", "created_at",
        ]
        read_only_fields = fields
