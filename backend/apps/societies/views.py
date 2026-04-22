from django.db.models import Count, Q
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.permissions import IsSocietyAdmin, IsSuperAdmin
from apps.bookings.services import get_available_slots, validate_booking_window

from .models import ParkingSlot, SlotAvailabilityWindow, Society
from .serializers import (
    DestinationAutocompleteSerializer,
    ParkingSlotSerializer,
    ReverseGeocodeSerializer,
    SlotAvailabilityWindowSerializer,
    SlotAvailabilityFilterSerializer,
    SocietyAvailabilitySearchSerializer,
    SocietyCreateSerializer,
    SocietySerializer,
)
from .services import (
    autocomplete_destinations,
    reverse_geocode_destination,
    search_societies_by_availability,
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


class PublicSocietyListView(generics.ListAPIView):
    serializer_class = SocietySerializer
    permission_classes = [permissions.AllowAny]

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


class DestinationAutocompleteView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        serializer = DestinationAutocompleteSerializer(data=request.query_params)
        serializer.is_valid(raise_exception=True)

        return Response(
            {
                "results": autocomplete_destinations(
                    serializer.validated_data["q"],
                    limit=serializer.validated_data.get("limit"),
                )
            }
        )


class DestinationReverseGeocodeView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        serializer = ReverseGeocodeSerializer(data=request.query_params)
        serializer.is_valid(raise_exception=True)
        return Response(
            reverse_geocode_destination(
                serializer.validated_data["latitude"],
                serializer.validated_data["longitude"],
            )
        )


class SocietyAvailabilitySearchView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = SocietyAvailabilitySearchSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        validate_booking_window(
            serializer.validated_data["start_datetime"],
            serializer.validated_data["end_datetime"],
        )

        results = search_societies_by_availability(
            destination_lat=serializer.validated_data["destination_lat"],
            destination_lng=serializer.validated_data["destination_lng"],
            destination_text=serializer.validated_data.get("destination_text", ""),
            destination_place_id=serializer.validated_data.get(
                "destination_place_id", ""
            ),
            start_time=serializer.validated_data["start_datetime"],
            end_time=serializer.validated_data["end_datetime"],
            vehicle_type=serializer.validated_data["vehicle_type"],
            search_radius_km=serializer.validated_data.get("search_radius_km"),
        )
        return Response(results)


class SlotListCreateView(generics.ListCreateAPIView):
    serializer_class = ParkingSlotSerializer

    def get_permissions(self):
        if self.request.method == "POST":
            return [IsSocietyAdmin()]
        return [permissions.IsAuthenticated()]

    def get_queryset(self):
        society_id = self.kwargs["society_id"]
        qs = ParkingSlot.objects.filter(society_id=society_id, is_active=True)

        params = self.request.query_params
        if {
            "booking_date",
            "start_time",
            "vehicle_type",
        }.issubset(params.keys()) and (
            "end_time" in params or "duration_minutes" in params
        ):
            filter_serializer = SlotAvailabilityFilterSerializer(data=params)
            filter_serializer.is_valid(raise_exception=True)

            validate_booking_window(
                filter_serializer.validated_data["start_datetime"],
                filter_serializer.validated_data["end_datetime"],
            )

            valid_slot_ids = [
                slot.id
                for slot in get_available_slots(
                    society_id=society_id,
                    vehicle_type=filter_serializer.validated_data["vehicle_type"],
                    start_time=filter_serializer.validated_data["start_datetime"],
                    end_time=filter_serializer.validated_data["end_datetime"],
                )
            ]
            qs = qs.filter(id__in=valid_slot_ids)
        else:
            slot_type = self.request.query_params.get("slot_type")
            if slot_type:
                qs = qs.filter(slot_type=slot_type)

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


class SlotUpdateView(generics.RetrieveUpdateAPIView):
    serializer_class = ParkingSlotSerializer

    def get_permissions(self):
        if self.request.method == "GET":
            return [permissions.IsAuthenticated()]
        return [IsSocietyAdmin()]

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
