from rest_framework import serializers

from apps.accounts.serializers import VehicleSerializer

from .models import Booking


class BookingCreateSerializer(serializers.Serializer):
    slot_id = serializers.UUIDField()
    vehicle_id = serializers.UUIDField()
    start_time = serializers.DateTimeField()
    end_time = serializers.DateTimeField()


class BookingSerializer(serializers.ModelSerializer):
    vehicle = VehicleSerializer(read_only=True)
    slot_number = serializers.CharField(source="slot.slot_number", read_only=True)
    society_name = serializers.CharField(source="slot.society.name", read_only=True)

    class Meta:
        model = Booking
        fields = [
            "id", "booking_number", "user", "vehicle", "slot",
            "slot_number", "society_name", "start_time", "end_time",
            "actual_entry", "actual_exit", "status", "amount",
            "lock_expires_at", "created_at",
        ]
        read_only_fields = fields
