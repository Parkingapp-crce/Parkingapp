from django.db.models import Count, Q
from django.utils import timezone
from django.contrib.auth import get_user_model
from urllib.request import Request, urlopen
import json
from urllib.parse import quote
import ssl

import certifi

from django.conf import settings

from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import UserNotification
from apps.accounts.permissions import IsSocietyAdmin, IsSuperAdmin

from .models import ParkingSlot, SlotAvailabilityWindow, Society, SocietyMembershipRequest
from .serializers import (
    ParkingSlotSerializer,
    SocietyMembershipRequestDecisionSerializer,
    SocietyMembershipRequestSerializer,
    SlotAvailabilityWindowSerializer,
    SocietyCreateSerializer,
    SocietySerializer,
)

User = get_user_model()


class GeocodeLocationView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    @staticmethod
    def _read_json(req, timeout=8):
        context = ssl.create_default_context(cafile=certifi.where())
        with urlopen(req, timeout=timeout, context=context) as resp:
            return json.loads(resp.read().decode("utf-8"))

    def _maptiler_features(self, query, maptiler_key):
        encoded_query = quote(query)
        url = (
            f"https://api.maptiler.com/geocoding/{encoded_query}.json"
            f"?key={maptiler_key}&limit=5"
        )
        req = Request(
            url,
            headers={
                "Accept": "application/json",
                "User-Agent": "ParkWise/1.0",
            },
        )
        payload = self._read_json(req, timeout=8)
        if isinstance(payload, dict):
            return payload.get("features", [])
        return []

    def _nominatim_features(self, query):
        encoded_query = quote(query)
        url = (
            "https://nominatim.openstreetmap.org/search"
            f"?q={encoded_query}&format=jsonv2&limit=5&addressdetails=1"
        )
        req = Request(
            url,
            headers={
                "Accept": "application/json",
                "User-Agent": "ParkWise/1.0 (local-dev)",
            },
        )
        payload = self._read_json(req, timeout=8)

        features = []
        if isinstance(payload, list):
            for item in payload:
                try:
                    lon = float(item.get("lon"))
                    lat = float(item.get("lat"))
                except (TypeError, ValueError):
                    continue
                features.append(
                    {
                        "place_name": item.get("display_name"),
                        "geometry": {"coordinates": [lon, lat]},
                    }
                )
        return features

    def get(self, request):
        query = (request.query_params.get("q") or "").strip()
        if not query:
            return Response(
                {"error": "Query parameter 'q' is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        maptiler_key = getattr(settings, "MAPTILER_API_KEY", "")
        features = []

        if maptiler_key:
            try:
                features = self._maptiler_features(query, maptiler_key)
            except Exception:
                features = []

        if not features:
            try:
                features = self._nominatim_features(query)
            except Exception:
                return Response(
                    {"error": "Location search is temporarily unavailable."},
                    status=status.HTTP_503_SERVICE_UNAVAILABLE,
                )

        if not features:
            return Response(
                {"error": "No location found for this query."},
                status=status.HTTP_404_NOT_FOUND,
            )

        top = features[0]
        coordinates = top.get("geometry", {}).get("coordinates", [])
        if len(coordinates) < 2:
            return Response(
                {"error": "No location found for this query."},
                status=status.HTTP_404_NOT_FOUND,
            )
        return Response(
            {
                "query": query,
                "latitude": float(coordinates[1]),
                "longitude": float(coordinates[0]),
                "display_name": top.get("place_name"),
                "results": [
                    feature.get("place_name")
                    for feature in features
                    if feature.get("place_name")
                ],
            }
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
            return [permissions.IsAuthenticated()]
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
            
        # Filter by owner
        owner_id = self.request.query_params.get("owner_id")
        if owner_id:
            qs = qs.filter(owner_id=owner_id)

        # Keep pagination stable by always returning a deterministic order.
        qs = qs.order_by("-created_at")

        user = self.request.user
        if user.role == User.Role.SOCIETY_ADMIN and user.society_id == society_id:
            return qs
        if user.role == User.Role.GUARD and user.society_id == society_id:
            return qs.filter(approval_status=ParkingSlot.ApprovalStatus.APPROVED)
        
        # For USER role
        if owner_id and str(owner_id) == str(user.id):
            return qs
        return qs.filter(approval_status=ParkingSlot.ApprovalStatus.APPROVED)

    def perform_create(self, serializer):
        society_id = self.kwargs["society_id"]
        society = Society.objects.get(id=society_id)
        user = self.request.user

        if user.society_id != society.id:
            from rest_framework.exceptions import PermissionDenied
            raise PermissionDenied("You can only manage slots in your own society.")

        available_from = serializer.validated_data.pop("available_from_write", None)
        available_to = serializer.validated_data.pop("available_to_write", None)

        if user.role == User.Role.SOCIETY_ADMIN:
            serializer.save(
                society=society,
                ownership_type=ParkingSlot.OwnershipType.SOCIETY,
                created_by=user,
                approval_status=ParkingSlot.ApprovalStatus.APPROVED,
                approved_by=user,
                approved_at=timezone.now(),
            )
        else:
            serializer.save(
                society=society,
                owner=user,
                created_by=user,
                ownership_type=ParkingSlot.OwnershipType.RESIDENT,
                approval_status=ParkingSlot.ApprovalStatus.PENDING,
                state=ParkingSlot.SlotState.BLOCKED,
            )

        slot = serializer.instance
        if available_from and available_to:
            for day in range(7):
                SlotAvailabilityWindow.objects.create(
                    slot=slot,
                    day_of_week=day,
                    start_time=available_from,
                    end_time=available_to,
                )

        if user.role != User.Role.SOCIETY_ADMIN:
            admins = User.objects.filter(
                role=User.Role.SOCIETY_ADMIN,
                society=society,
                is_active=True,
            )
            for admin in admins:
                UserNotification.objects.create(
                    user=admin,
                    notification_type=UserNotification.NotificationType.SLOT_PENDING,
                    title="New slot approval request",
                    message=f"{user.full_name} submitted a new parking slot for approval.",
                    payload={
                        "slot_id": str(slot.id),
                        "society_id": str(society.id),
                        "created_by": str(user.id),
                    },
                )


class SlotUpdateView(generics.RetrieveUpdateAPIView):
    serializer_class = ParkingSlotSerializer

    def get_permissions(self):
        if self.request.method in ("PUT", "PATCH"):
            return [IsSocietyAdmin()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        society_id = self.kwargs["society_id"]
        return ParkingSlot.objects.filter(society_id=society_id, is_active=True)


class SocietyMembershipRequestListView(generics.ListAPIView):
    serializer_class = SocietyMembershipRequestSerializer
    permission_classes = [IsSocietyAdmin]

    def get_queryset(self):
        society_id = self.kwargs["society_id"]
        status_filter = self.request.query_params.get("status")
        qs = SocietyMembershipRequest.objects.filter(society_id=society_id)
        if self.request.user.society_id != society_id:
            return SocietyMembershipRequest.objects.none()
        if status_filter:
            qs = qs.filter(status=status_filter)
        return qs.select_related("user", "reviewed_by")


class SocietyMembershipRequestDecisionView(APIView):
    permission_classes = [IsSocietyAdmin]

    def post(self, request, society_id, pk):
        if request.user.society_id != society_id:
            return Response(
                {"error": "Not authorized for this society"},
                status=status.HTTP_403_FORBIDDEN,
            )

        try:
            join_request = SocietyMembershipRequest.objects.select_related("user", "society").get(
                id=pk,
                society_id=society_id,
            )
        except SocietyMembershipRequest.DoesNotExist:
            return Response({"error": "Join request not found"}, status=status.HTTP_404_NOT_FOUND)

        if join_request.status != SocietyMembershipRequest.Status.PENDING:
            return Response(
                {"error": "Join request already processed"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        serializer = SocietyMembershipRequestDecisionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        action = serializer.validated_data["action"]
        notes = serializer.validated_data.get("notes", "")

        join_request.notes = notes
        join_request.reviewed_by = request.user
        join_request.reviewed_at = timezone.now()

        if action == "approve":
            join_request.status = SocietyMembershipRequest.Status.APPROVED
            join_request.user.society = join_request.society
            join_request.user.save(update_fields=["society", "updated_at"])
            join_request.save(update_fields=["status", "notes", "reviewed_by", "reviewed_at", "updated_at"])
            UserNotification.objects.create(
                user=join_request.user,
                notification_type=UserNotification.NotificationType.JOIN_APPROVED,
                title="Membership approved",
                message=f"Your request to join {join_request.society.name} has been approved.",
                payload={
                    "join_request_id": str(join_request.id),
                    "society_id": str(join_request.society_id),
                },
            )
        else:
            join_request.status = SocietyMembershipRequest.Status.REJECTED
            join_request.save(update_fields=["status", "notes", "reviewed_by", "reviewed_at", "updated_at"])
            UserNotification.objects.create(
                user=join_request.user,
                notification_type=UserNotification.NotificationType.JOIN_REJECTED,
                title="Membership request rejected",
                message=f"Your request to join {join_request.society.name} was rejected.",
                payload={
                    "join_request_id": str(join_request.id),
                    "society_id": str(join_request.society_id),
                },
            )

        return Response(SocietyMembershipRequestSerializer(join_request).data)


class SlotApprovalDecisionView(APIView):
    permission_classes = [IsSocietyAdmin]

    def post(self, request, society_id, pk):
        if request.user.society_id != society_id:
            return Response(
                {"error": "Not authorized for this society"},
                status=status.HTTP_403_FORBIDDEN,
            )

        serializer = SocietyMembershipRequestDecisionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        action = serializer.validated_data["action"]
        notes = serializer.validated_data.get("notes", "")

        try:
            slot = ParkingSlot.objects.select_related("owner", "society").get(
                id=pk,
                society_id=society_id,
                is_active=True,
            )
        except ParkingSlot.DoesNotExist:
            return Response({"error": "Slot not found"}, status=status.HTTP_404_NOT_FOUND)

        if slot.approval_status != ParkingSlot.ApprovalStatus.PENDING:
            return Response(
                {"error": "Slot is not pending approval"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        slot.approval_notes = notes
        slot.approved_by = request.user
        slot.approved_at = timezone.now()

        if action == "approve":
            slot.approval_status = ParkingSlot.ApprovalStatus.APPROVED
            slot.state = ParkingSlot.SlotState.AVAILABLE
            notification_type = UserNotification.NotificationType.SLOT_APPROVED
            notification_title = "Slot approved"
            notification_message = f"Your slot {slot.slot_number} has been approved."
        else:
            slot.approval_status = ParkingSlot.ApprovalStatus.REJECTED
            slot.state = ParkingSlot.SlotState.BLOCKED
            notification_type = UserNotification.NotificationType.SLOT_REJECTED
            notification_title = "Slot rejected"
            notification_message = f"Your slot {slot.slot_number} was rejected."

        slot.save(
            update_fields=[
                "approval_status",
                "approval_notes",
                "approved_by",
                "approved_at",
                "state",
                "updated_at",
            ]
        )

        if slot.owner_id:
            UserNotification.objects.create(
                user=slot.owner,
                notification_type=notification_type,
                title=notification_title,
                message=notification_message,
                payload={"slot_id": str(slot.id), "society_id": str(slot.society_id)},
            )

        if action == "approve":
            guards = User.objects.filter(
                role=User.Role.GUARD,
                society=slot.society,
                is_active=True,
            )
            for guard in guards:
                UserNotification.objects.create(
                    user=guard,
                    notification_type=UserNotification.NotificationType.SLOT_APPROVED,
                    title="New approved slot",
                    message=f"Slot {slot.slot_number} has been approved in {slot.society.name}.",
                    payload={"slot_id": str(slot.id), "society_id": str(slot.society_id)},
                )

        return Response(ParkingSlotSerializer(slot).data)


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
