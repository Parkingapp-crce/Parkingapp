from django.db.models import Count, Q
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.permissions import IsSocietyAdmin, IsSuperAdmin

from .models import ParkingSlot, SlotAvailabilityWindow, Society
from .serializers import (
    ParkingSlotSerializer,
    SlotAvailabilityWindowSerializer,
    SocietyCreateSerializer,
    SocietySerializer,
)


class SocietyListCreateView(generics.ListCreateAPIView):
    def get_serializer_class(self):
        if self.request.method == "POST":
            return SocietyCreateSerializer
        return SocietySerializer

    def get_permissions(self):
        if self.request.method == "POST":
            return [IsSuperAdmin()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        return Society.objects.filter(is_active=True).annotate(
            total_slots=Count("slots", filter=Q(slots__is_active=True)),
            available_slots=Count(
                "slots",
                filter=Q(slots__is_active=True, slots__state="available"),
            ),
        )


class SocietyDetailView(generics.RetrieveUpdateAPIView):
    def get_serializer_class(self):
        if self.request.method in ("PUT", "PATCH"):
            return SocietyCreateSerializer
        return SocietySerializer

    def get_permissions(self):
        if self.request.method in ("PUT", "PATCH"):
            return [IsSuperAdmin()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        return Society.objects.annotate(
            total_slots=Count("slots", filter=Q(slots__is_active=True)),
            available_slots=Count(
                "slots",
                filter=Q(slots__is_active=True, slots__state="available"),
            ),
        )


class SlotListCreateView(generics.ListCreateAPIView):
    serializer_class = ParkingSlotSerializer

    def get_permissions(self):
        if self.request.method == "POST":
            return [IsSocietyAdmin()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        society_id = self.kwargs["society_id"]
        qs = ParkingSlot.objects.filter(society_id=society_id, is_active=True)

        # Filter by slot_type
        slot_type = self.request.query_params.get("slot_type")
        if slot_type:
            qs = qs.filter(slot_type=slot_type)

        # Filter by state
        state = self.request.query_params.get("state")
        if state:
            qs = qs.filter(state=state)

        return qs

    def perform_create(self, serializer):
        society_id = self.kwargs["society_id"]
        society = Society.objects.get(id=society_id)
        # Verify admin belongs to this society
        if self.request.user.society_id != society.id:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("You can only manage slots in your own society.")
        serializer.save(society=society)


class SlotUpdateView(generics.UpdateAPIView):
    serializer_class = ParkingSlotSerializer
    permission_classes = [IsSocietyAdmin]

    def get_queryset(self):
        society_id = self.kwargs["society_id"]
        return ParkingSlot.objects.filter(society_id=society_id, is_active=True)


class SlotBlockView(APIView):
    permission_classes = [IsSocietyAdmin]

    def post(self, request, society_id, pk):
        try:
            slot = ParkingSlot.objects.get(id=pk, society_id=society_id, is_active=True)
        except ParkingSlot.DoesNotExist:
            return Response({"error": "Slot not found"}, status=status.HTTP_404_NOT_FOUND)

        if request.user.society_id != slot.society_id:
            return Response(
                {"error": "Not authorized for this society"},
                status=status.HTTP_403_FORBIDDEN,
            )

        if slot.state != ParkingSlot.SlotState.AVAILABLE:
            return Response(
                {"error": f"Cannot block slot in '{slot.state}' state"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        slot.state = ParkingSlot.SlotState.BLOCKED
        slot.save(update_fields=["state", "updated_at"])
        return Response(ParkingSlotSerializer(slot).data)


class SlotUnblockView(APIView):
    permission_classes = [IsSocietyAdmin]

    def post(self, request, society_id, pk):
        try:
            slot = ParkingSlot.objects.get(id=pk, society_id=society_id, is_active=True)
        except ParkingSlot.DoesNotExist:
            return Response({"error": "Slot not found"}, status=status.HTTP_404_NOT_FOUND)

        if request.user.society_id != slot.society_id:
            return Response(
                {"error": "Not authorized for this society"},
                status=status.HTTP_403_FORBIDDEN,
            )

        if slot.state != ParkingSlot.SlotState.BLOCKED:
            return Response(
                {"error": "Slot is not blocked"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        slot.state = ParkingSlot.SlotState.AVAILABLE
        slot.save(update_fields=["state", "updated_at"])
        return Response(ParkingSlotSerializer(slot).data)


class SlotAvailabilityWindowListCreateView(generics.ListCreateAPIView):
    serializer_class = SlotAvailabilityWindowSerializer
    permission_classes = [IsSocietyAdmin]

    def get_queryset(self):
        return SlotAvailabilityWindow.objects.filter(
            slot_id=self.kwargs["pk"],
            slot__society_id=self.kwargs["society_id"],
            is_active=True,
        )

    def perform_create(self, serializer):
        slot = ParkingSlot.objects.get(
            id=self.kwargs["pk"],
            society_id=self.kwargs["society_id"],
        )
        serializer.save(slot=slot)
