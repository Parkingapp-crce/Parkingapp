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
    owner_name = serializers.CharField(source="user.full_name", read_only=True)
    owner_email = serializers.CharField(source="user.email", read_only=True)
    owner_phone = serializers.CharField(source="user.phone", read_only=True)
    payment_status = serializers.SerializerMethodField()

    class Meta:
        model = Booking
        fields = [
            "id", "booking_number", "user", "vehicle", "slot",
            "slot_number", "society_name", "owner_name", "owner_email",
            "owner_phone", "start_time", "end_time", "actual_entry",
            "actual_exit", "status", "amount", "payment_status",
            "lock_expires_at", "created_at",
        ]
        read_only_fields = fields

    def get_payment_status(self, obj):
        payments = getattr(obj, "prefetched_payments", None)
        if payments is None:
            payments = list(obj.payments.all())
        if not payments:
            return "unpaid"
        return payments[0].status
