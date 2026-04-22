from decimal import Decimal

from django.db.models import Count, Prefetch, Q, Sum
from django.db.models.functions import Coalesce
from django.utils import timezone
from rest_framework import permissions
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import User
from apps.accounts.permissions import IsSocietyAdmin, IsSuperAdmin
from apps.bookings.models import Booking
from apps.payments.models import Payment
from apps.qr_validation.models import ScanEvent
from apps.societies.models import ParkingSlot, Society

from .serializers import (
    GuardAccountSerializer,
    GuardDecisionSerializer,
    SocietyAdminDashboardSerializer,
)

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


class SocietyAdminDashboardView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsSocietyAdmin]

    def get(self, request):
        society_id = request.user.society_id
        if society_id is None:
            return Response({"error": "No society assigned to this admin."}, status=400)

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
            blocked_slots=Count(
                "id", filter=Q(state=ParkingSlot.SlotState.BLOCKED)
            ),
        )

        booking_payments_prefetch = Prefetch(
            "payments",
            queryset=Payment.objects.order_by("-created_at"),
            to_attr="prefetched_payments",
        )
        currently_parked = list(
            Booking.objects.filter(
                slot__society_id=society_id,
                status=Booking.Status.ACTIVE,
            )
            .select_related("user", "vehicle", "slot", "slot__society")
            .prefetch_related(booking_payments_prefetch)[:10]
        )
        recent_gate_activity = list(
            ScanEvent.objects.filter(society_id=society_id)
            .select_related(
                "guard",
                "booking",
                "booking__user",
                "booking__vehicle",
                "booking__slot",
            )
            .prefetch_related(
                Prefetch(
                    "booking__payments",
                    queryset=Payment.objects.order_by("-created_at"),
                    to_attr="prefetched_payments",
                )
            )[:12]
        )
        today = timezone.localdate()
        completed_today = Booking.objects.filter(
            slot__society_id=society_id,
            status=Booking.Status.COMPLETED,
            actual_exit__date=today,
        ).count()

        payload = {
            "total_slots": slot_counts["total_slots"] or 0,
            "available_slots": slot_counts["available_slots"] or 0,
            "reserved_slots": slot_counts["reserved_slots"] or 0,
            "occupied_slots": slot_counts["occupied_slots"] or 0,
            "blocked_slots": slot_counts["blocked_slots"] or 0,
            "active_bookings": Booking.objects.filter(
                slot__society_id=society_id,
                status=Booking.Status.ACTIVE,
            ).count(),
            "completed_today": completed_today,
            "pending_guard_requests": User.objects.filter(
                society_id=society_id,
                role=User.Role.GUARD,
                approval_status=User.ApprovalStatus.PENDING,
            ).count(),
            "approved_guards": User.objects.filter(
                society_id=society_id,
                role=User.Role.GUARD,
                approval_status=User.ApprovalStatus.APPROVED,
            ).count(),
            "currently_parked": currently_parked,
            "recent_gate_activity": recent_gate_activity,
        }
        serializer = SocietyAdminDashboardSerializer(payload)
        return Response(serializer.data)


class SocietyGuardListView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsSocietyAdmin]

    def get(self, request):
        status_filter = request.query_params.get("status")
        guards = User.objects.filter(
            society_id=request.user.society_id,
            role=User.Role.GUARD,
        ).order_by("approval_status", "full_name")
        if status_filter:
            guards = guards.filter(approval_status=status_filter)
        return Response(GuardAccountSerializer(guards, many=True).data)


class SocietyGuardApproveView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsSocietyAdmin]

    def post(self, request, guard_id):
        serializer = GuardDecisionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        guard = User.objects.filter(
            id=guard_id,
            role=User.Role.GUARD,
            society_id=request.user.society_id,
        ).first()
        if guard is None:
            return Response({"error": "Guard request not found."}, status=404)

        guard.approval_status = User.ApprovalStatus.APPROVED
        guard.approval_notes = serializer.validated_data.get(
            "notes",
            "Approved by society admin.",
        )
        guard.approved_at = timezone.now()
        guard.save(update_fields=["approval_status", "approval_notes", "approved_at"])
        return Response(GuardAccountSerializer(guard).data)


class SocietyGuardRejectView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsSocietyAdmin]

    def post(self, request, guard_id):
        serializer = GuardDecisionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        guard = User.objects.filter(
            id=guard_id,
            role=User.Role.GUARD,
            society_id=request.user.society_id,
        ).first()
        if guard is None:
            return Response({"error": "Guard request not found."}, status=404)

        guard.approval_status = User.ApprovalStatus.REJECTED
        guard.approval_notes = serializer.validated_data.get(
            "notes",
            "Rejected by society admin.",
        )
        guard.approved_at = None
        guard.save(update_fields=["approval_status", "approval_notes", "approved_at"])
        return Response(GuardAccountSerializer(guard).data)
