from datetime import datetime, timedelta

from django.db import transaction
from rest_framework import serializers
from django.utils import timezone

from apps.accounts.models import User

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
    admin_full_name = serializers.CharField(
        write_only=True, required=False, max_length=150
    )
    admin_email = serializers.EmailField(write_only=True, required=False)
    admin_phone = serializers.CharField(write_only=True, required=False, max_length=15)
    admin_password = serializers.CharField(
        write_only=True, required=False, min_length=8, style={"input_type": "password"}
    )

    class Meta:
        model = Society
        fields = [
            "name", "address", "city", "state", "pincode",
            "latitude", "longitude", "contact_email", "contact_phone",
            "admin_full_name", "admin_email", "admin_phone", "admin_password",
        ]

    def validate(self, attrs):
        if self.instance is not None:
            return attrs

        required_admin_fields = (
            "admin_full_name",
            "admin_email",
            "admin_phone",
            "admin_password",
        )
        missing_fields = [
            field
            for field in required_admin_fields
            if not attrs.get(field, "").strip()
        ]
        if missing_fields:
            raise serializers.ValidationError(
                {
                    field: "This field is required when creating a society."
                    for field in missing_fields
                }
            )

        admin_email = attrs["admin_email"]
        admin_phone = attrs["admin_phone"]
        if User.objects.filter(email__iexact=admin_email).exists():
            raise serializers.ValidationError(
                {"admin_email": "A user with this email already exists."}
            )
        if User.objects.filter(phone=admin_phone).exists():
            raise serializers.ValidationError(
                {"admin_phone": "A user with this phone number already exists."}
            )
        return attrs

    @transaction.atomic
    def create(self, validated_data):
        admin_full_name = validated_data.pop("admin_full_name")
        admin_email = validated_data.pop("admin_email")
        admin_phone = validated_data.pop("admin_phone")
        admin_password = validated_data.pop("admin_password")

        society = Society.objects.create(**validated_data)
        User.objects.create_user(
            email=admin_email,
            password=admin_password,
            full_name=admin_full_name,
            phone=admin_phone,
            role=User.Role.SOCIETY_ADMIN,
            society=society,
        )
        return society


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


class DestinationAutocompleteSerializer(serializers.Serializer):
    q = serializers.CharField(min_length=2, max_length=200)
    limit = serializers.IntegerField(required=False, min_value=1, max_value=10)


class ReverseGeocodeSerializer(serializers.Serializer):
    latitude = serializers.FloatField(min_value=-90, max_value=90)
    longitude = serializers.FloatField(min_value=-180, max_value=180)


class SocietyAvailabilitySearchSerializer(serializers.Serializer):
    destination_text = serializers.CharField(required=False, allow_blank=True)
    destination_lat = serializers.FloatField(min_value=-90, max_value=90)
    destination_lng = serializers.FloatField(min_value=-180, max_value=180)
    destination_place_id = serializers.CharField(required=False, allow_blank=True)
    current_lat = serializers.FloatField(required=False, min_value=-90, max_value=90)
    current_lng = serializers.FloatField(required=False, min_value=-180, max_value=180)
    booking_date = serializers.DateField()
    start_time = serializers.TimeField()
    end_time = serializers.TimeField(required=False)
    duration_minutes = serializers.IntegerField(required=False, min_value=30, max_value=1440)
    vehicle_type = serializers.ChoiceField(choices=ParkingSlot.SlotType.choices)
    search_radius_km = serializers.FloatField(required=False, min_value=0.5, max_value=50)

    def validate(self, attrs):
        has_end_time = attrs.get("end_time") is not None
        has_duration = attrs.get("duration_minutes") is not None
        if has_end_time == has_duration:
            raise serializers.ValidationError(
                "Provide either end_time or duration_minutes."
            )
        has_current_lat = attrs.get("current_lat") is not None
        has_current_lng = attrs.get("current_lng") is not None
        if has_current_lat != has_current_lng:
            raise serializers.ValidationError(
                "Provide both current_lat and current_lng together."
            )

        timezone_obj = timezone.get_current_timezone()
        start_dt = timezone.make_aware(
            datetime.combine(attrs["booking_date"], attrs["start_time"]),
            timezone_obj,
        )

        if has_end_time:
            end_dt = timezone.make_aware(
                datetime.combine(attrs["booking_date"], attrs["end_time"]),
                timezone_obj,
            )
        else:
            end_dt = start_dt + timedelta(minutes=attrs["duration_minutes"])

        if end_dt <= start_dt:
            raise serializers.ValidationError("End time must be after start time.")

        attrs["start_datetime"] = start_dt
        attrs["end_datetime"] = end_dt
        return attrs


class SlotAvailabilityFilterSerializer(serializers.Serializer):
    booking_date = serializers.DateField()
    start_time = serializers.TimeField()
    end_time = serializers.TimeField(required=False)
    duration_minutes = serializers.IntegerField(required=False, min_value=30, max_value=1440)
    vehicle_type = serializers.ChoiceField(choices=ParkingSlot.SlotType.choices)

    def validate(self, attrs):
        has_end_time = attrs.get("end_time") is not None
        has_duration = attrs.get("duration_minutes") is not None
        if has_end_time == has_duration:
            raise serializers.ValidationError(
                "Provide either end_time or duration_minutes."
            )

        timezone_obj = timezone.get_current_timezone()
        start_dt = timezone.make_aware(
            datetime.combine(attrs["booking_date"], attrs["start_time"]),
            timezone_obj,
        )

        if has_end_time:
            end_dt = timezone.make_aware(
                datetime.combine(attrs["booking_date"], attrs["end_time"]),
                timezone_obj,
            )
        else:
            end_dt = start_dt + timedelta(minutes=attrs["duration_minutes"])

        if end_dt <= start_dt:
            raise serializers.ValidationError("End time must be after start time.")

        attrs["start_datetime"] = start_dt
        attrs["end_datetime"] = end_dt
        return attrs
