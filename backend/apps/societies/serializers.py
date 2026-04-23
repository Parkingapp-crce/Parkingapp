from django.contrib.auth import get_user_model
from rest_framework import serializers

from .models import ParkingSlot, SlotAvailabilityWindow, Society, SocietyMembershipRequest

User = get_user_model()


class SocietySerializer(serializers.ModelSerializer):
    total_slots = serializers.IntegerField(read_only=True)
    available_slots = serializers.IntegerField(read_only=True)

    class Meta:
        model = Society
        fields = [
            "id", "name", "address", "city", "state", "pincode",
            "latitude", "longitude", "contact_email", "contact_phone",
            "join_code", "is_active", "total_slots", "available_slots", "created_at",
        ]
        read_only_fields = ["id", "join_code", "created_at"]


class SocietyCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Society
        fields = [
            "name", "address", "city", "state", "pincode",
            "latitude", "longitude", "contact_email", "contact_phone",
        ]


class ParkingSlotSerializer(serializers.ModelSerializer):
    owner_name = serializers.CharField(source="owner.full_name", read_only=True)
    approval_owner = serializers.CharField(source="approved_by.full_name", read_only=True)
    available_from_write = serializers.TimeField(write_only=True, required=False)
    available_to_write = serializers.TimeField(write_only=True, required=False)
    available_from = serializers.SerializerMethodField()
    available_to = serializers.SerializerMethodField()

    class Meta:
        model = ParkingSlot
        fields = [
            "id", "society", "slot_number", "floor", "slot_type",
            "state", "ownership_type", "owner", "hourly_rate",
            "created_by", "approval_status", "approval_notes",
            "approved_by", "approved_at", "is_active", "created_at",
            "owner_name", "approval_owner", "available_from_write", "available_to_write",
            "available_from", "available_to",
        ]
        read_only_fields = [
            "id",
            "society",
            "state",
            "owner",
            "created_by",
            "approval_status",
            "approval_notes",
            "approved_by",
            "approved_at",
            "created_at",
            "owner_name",
            "approval_owner",
            "available_from",
            "available_to",
        ]

    def get_available_from(self, obj):
        window = obj.availability_windows.first()
        return window.start_time.strftime("%H:%M:%S") if window else "00:00:00"

    def get_available_to(self, obj):
        window = obj.availability_windows.first()
        return window.end_time.strftime("%H:%M:%S") if window else "23:59:59"


class SocietyMembershipRequestSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source="user.full_name", read_only=True)
    user_email = serializers.EmailField(source="user.email", read_only=True)
    user_phone = serializers.CharField(source="user.phone", read_only=True)
    reviewed_by_name = serializers.CharField(source="reviewed_by.full_name", read_only=True)

    class Meta:
        model = SocietyMembershipRequest
        fields = [
            "id",
            "society",
            "user",
            "status",
            "notes",
            "reviewed_by",
            "reviewed_at",
            "created_at",
            "user_name",
            "user_email",
            "user_phone",
            "reviewed_by_name",
        ]
        read_only_fields = fields


class SocietyMembershipRequestDecisionSerializer(serializers.Serializer):
    action = serializers.ChoiceField(choices=["approve", "reject"])
    notes = serializers.CharField(required=False, allow_blank=True, max_length=255)


class SlotAvailabilityWindowSerializer(serializers.ModelSerializer):
    class Meta:
        model = SlotAvailabilityWindow
        fields = ["id", "slot", "day_of_week", "start_time", "end_time", "is_active"]
        read_only_fields = ["id", "slot"]
