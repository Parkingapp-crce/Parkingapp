from decimal import Decimal

from rest_framework import serializers

from apps.accounts.serializers import UserProfileSerializer
from apps.bookings.serializers import BookingSerializer
from apps.payments.models import Payment
from apps.payments.serializers import RefundSerializer
from apps.qr_validation.models import ScanEvent


class GuardDecisionSerializer(serializers.Serializer):
    notes = serializers.CharField(required=False, allow_blank=True, max_length=255)


class ScanEventSerializer(serializers.ModelSerializer):
    guard_name = serializers.CharField(source="guard.full_name", read_only=True)
    booking_number = serializers.CharField(
        source="booking.booking_number",
        read_only=True,
        default="",
    )
    vehicle_number = serializers.CharField(
        source="booking.vehicle.registration_no",
        read_only=True,
        default="",
    )
    owner_name = serializers.CharField(
        source="booking.user.full_name",
        read_only=True,
        default="",
    )
    owner_phone = serializers.CharField(
        source="booking.user.phone",
        read_only=True,
        default="",
    )
    owner_email = serializers.CharField(
        source="booking.user.email",
        read_only=True,
        default="",
    )
    slot_number = serializers.CharField(
        source="booking.slot.slot_number",
        read_only=True,
        default="",
    )
    payment_status = serializers.SerializerMethodField()
    entry_time = serializers.DateTimeField(source="booking.actual_entry", read_only=True)
    exit_time = serializers.DateTimeField(source="booking.actual_exit", read_only=True)

    class Meta:
        model = ScanEvent
        fields = [
            "id",
            "event_type",
            "result",
            "error_message",
            "scanned_at",
            "guard_name",
            "booking_number",
            "vehicle_number",
            "owner_name",
            "owner_phone",
            "owner_email",
            "slot_number",
            "payment_status",
            "entry_time",
            "exit_time",
        ]

    def get_payment_status(self, obj):
        booking = obj.booking
        if booking is None:
            return "unknown"
        payments = getattr(booking, "prefetched_payments", None)
        if payments is None:
            payments = list(booking.payments.all())
        if not payments:
            return "unpaid"
        return payments[0].status


class SocietyAdminDashboardSerializer(serializers.Serializer):
    join_code = serializers.CharField()
    total_slots = serializers.IntegerField()
    available_slots = serializers.IntegerField()
    reserved_slots = serializers.IntegerField()
    occupied_slots = serializers.IntegerField()
    blocked_slots = serializers.IntegerField()
    active_bookings = serializers.IntegerField()
    completed_today = serializers.IntegerField()
    pending_guard_requests = serializers.IntegerField()
    approved_guards = serializers.IntegerField()
    currently_parked = BookingSerializer(many=True)
    recent_gate_activity = ScanEventSerializer(many=True)


class GuardAccountSerializer(UserProfileSerializer):
    class Meta(UserProfileSerializer.Meta):
        fields = UserProfileSerializer.Meta.fields + ["temporary_password"]


class RefundInitiateSerializer(serializers.Serializer):
    booking_id = serializers.UUIDField()
    refund_amount = serializers.DecimalField(
        max_digits=10, decimal_places=2, min_value=Decimal("0.01")
    )
    reason = serializers.CharField(required=False, allow_blank=True, default="", max_length=500)


class BookingRefundLookupSerializer(serializers.Serializer):
    """Returned when super admin looks up a booking before issuing a refund."""
    booking_id = serializers.UUIDField()
    booking_number = serializers.CharField()
    user_name = serializers.CharField()
    user_email = serializers.CharField()
    booking_status = serializers.CharField()
    booking_amount = serializers.DecimalField(max_digits=10, decimal_places=2)
    start_time = serializers.DateTimeField()
    end_time = serializers.DateTimeField()
    slot_number = serializers.CharField()
    society_name = serializers.CharField()
    # Payment info
    payment_id = serializers.UUIDField(allow_null=True)
    payment_status = serializers.CharField(allow_null=True)
    payment_provider = serializers.CharField(allow_null=True)
    amount_paid = serializers.DecimalField(max_digits=10, decimal_places=2, allow_null=True)
    max_refundable = serializers.DecimalField(max_digits=10, decimal_places=2, allow_null=True)
    already_refunded = serializers.DecimalField(max_digits=10, decimal_places=2)
    # Past refunds on this booking
    past_refunds = RefundSerializer(many=True)


# Re-export RefundSerializer for convenience in views
__all__ = [
    "GuardDecisionSerializer",
    "ScanEventSerializer",
    "SocietyAdminDashboardSerializer",
    "GuardAccountSerializer",
    "RefundInitiateSerializer",
    "BookingRefundLookupSerializer",
    "RefundSerializer",
]
