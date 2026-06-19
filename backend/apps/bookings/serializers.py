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
    society_address = serializers.CharField(source="slot.society.address", read_only=True)
    society_city = serializers.CharField(source="slot.society.city", read_only=True)
    society_state = serializers.CharField(source="slot.society.state", read_only=True)
    society_latitude = serializers.DecimalField(
        source="slot.society.latitude",
        max_digits=9,
        decimal_places=6,
        read_only=True,
    )
    society_longitude = serializers.DecimalField(
        source="slot.society.longitude",
        max_digits=9,
        decimal_places=6,
        read_only=True,
    )
    owner_name = serializers.CharField(source="user.full_name", read_only=True)
    owner_email = serializers.CharField(source="user.email", read_only=True)
    owner_phone = serializers.CharField(source="user.phone", read_only=True)
    payment_status = serializers.SerializerMethodField()
    amount_paid = serializers.SerializerMethodField()

    class Meta:
        model = Booking
        fields = [
            "id", "booking_number", "user", "vehicle", "slot",
            "slot_number", "society_name", "owner_name", "owner_email",
            "owner_phone", "society_address", "society_city", "society_state",
            "society_latitude", "society_longitude", "start_time", "end_time",
            "actual_entry", "actual_exit", "status", "base_amount", "surge_amount", "surge_multiplier", "amount", "amount_paid",
            "payment_status", "lock_expires_at", "created_at",
        ]
        read_only_fields = fields

    def get_payment_status(self, obj):
        payments = getattr(obj, "prefetched_payments", None)
        if payments is None:
            payments = list(obj.payments.all())
        if not payments:
            return "unpaid"
        return payments[0].status

    def get_amount_paid(self, obj):
        payments = getattr(obj, "prefetched_payments", None)
        if payments is None:
            payments = list(obj.payments.all())
        # Sum up captured payments that are specifically for the booking (ignoring penalties if any mixed)
        total_paid = sum(p.amount for p in payments if p.status == "captured" and p.payment_type == "booking")
        # If no captured payment, fallback to the original booking amount
        if total_paid > 0:
            return str(total_paid)
        return str(obj.amount)
