from rest_framework import serializers

from .models import ParkingSlot, SlotAvailabilityWindow, Society


class SocietySerializer(serializers.ModelSerializer):
    total_slots = serializers.IntegerField(read_only=True)
    available_slots = serializers.IntegerField(read_only=True)

    class Meta:
        model = Society
        fields = [
            "id", "name", "address", "city", "state", "pincode",
            "latitude", "longitude", "contact_email", "contact_phone",
            "is_active", "total_slots", "available_slots", "created_at",
        ]
        read_only_fields = ["id", "created_at"]


class SocietyCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Society
        fields = [
            "name", "address", "city", "state", "pincode",
            "latitude", "longitude", "contact_email", "contact_phone",
        ]


class ParkingSlotSerializer(serializers.ModelSerializer):
    class Meta:
        model = ParkingSlot
        fields = [
            "id", "society", "slot_number", "floor", "slot_type",
            "state", "ownership_type", "owner", "hourly_rate",
            "is_active", "created_at",
        ]
        read_only_fields = ["id", "society", "state", "created_at"]


class SlotAvailabilityWindowSerializer(serializers.ModelSerializer):
    class Meta:
        model = SlotAvailabilityWindow
        fields = ["id", "slot", "day_of_week", "start_time", "end_time", "is_active"]
        read_only_fields = ["id", "slot"]
