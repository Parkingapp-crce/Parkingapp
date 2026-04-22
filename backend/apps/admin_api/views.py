from decimal import Decimal

from django.db.models import Count, Q, Sum
from django.db.models.functions import Coalesce
from rest_framework import permissions
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.permissions import IsSuperAdmin
from apps.bookings.models import Booking
from apps.payments.models import Payment
from apps.societies.models import ParkingSlot, Society


ACTIVE_BOOKING_STATUSES = [
    Booking.Status.PENDING_PAYMENT,
    Booking.Status.CONFIRMED,
    Booking.Status.ACTIVE,
]


class AdminDashboardView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsSuperAdmin]

    def get(self, request):
        total_societies = Society.objects.count()
        active_societies = Society.objects.filter(is_active=True).count()
        total_slots = ParkingSlot.objects.filter(is_active=True).count()
        total_bookings = Booking.objects.count()
        total_revenue = Payment.objects.filter(
            status=Payment.Status.CAPTURED
        ).aggregate(total=Coalesce(Sum("amount"), Decimal("0.00")))["total"]

        return Response(
            {
                "total_societies": total_societies,
                "active_societies": active_societies,
                "total_slots": total_slots,
                "total_bookings": total_bookings,
                "total_revenue": str(total_revenue),
            }
        )


class SocietyStatsView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsSuperAdmin]

    def get(self, request, society_id):
        society = Society.objects.filter(id=society_id).first()
        if society is None:
            return Response({"error": "Society not found."}, status=404)

        slot_counts = ParkingSlot.objects.filter(
            society_id=society_id,
            is_active=True,
        ).aggregate(
            total_slots=Count("id"),
            available_slots=Count(
                "id", filter=Q(state=ParkingSlot.SlotState.AVAILABLE)
            ),
            reserved_slots=Count(
                "id", filter=Q(state=ParkingSlot.SlotState.RESERVED)
            ),
            occupied_slots=Count(
                "id", filter=Q(state=ParkingSlot.SlotState.OCCUPIED)
            ),
        )
        total_slots = slot_counts["total_slots"] or 0
        unavailable_slots = (slot_counts["reserved_slots"] or 0) + (
            slot_counts["occupied_slots"] or 0
        )
        occupancy_rate = round(
            (unavailable_slots / total_slots) * 100, 1
        ) if total_slots else 0.0

        total_bookings = Booking.objects.filter(slot__society_id=society_id).count()
        active_bookings = Booking.objects.filter(
            slot__society_id=society_id,
            status__in=ACTIVE_BOOKING_STATUSES,
        ).count()
        total_revenue = Payment.objects.filter(
            booking__slot__society_id=society_id,
            status=Payment.Status.CAPTURED,
        ).aggregate(total=Coalesce(Sum("amount"), Decimal("0.00")))["total"]

        return Response(
            {
                "society_id": str(society.id),
                "total_slots": total_slots,
                "available_slots": slot_counts["available_slots"] or 0,
                "reserved_slots": slot_counts["reserved_slots"] or 0,
                "occupied_slots": slot_counts["occupied_slots"] or 0,
                "total_bookings": total_bookings,
                "active_bookings": active_bookings,
                "total_revenue": str(total_revenue),
                "occupancy_rate": occupancy_rate,
            }
        )
