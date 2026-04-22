from django.http import HttpResponse
from django.db.models import Prefetch
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import User, Vehicle
from apps.payments.models import Payment
from utils.qr import generate_qr_image

from .models import Booking
from .serializers import BookingCreateSerializer, BookingSerializer
from .services import cancel_booking, create_booking


class BookingCreateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = BookingCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        # Validate vehicle belongs to user
        try:
            vehicle = Vehicle.objects.get(
                id=serializer.validated_data["vehicle_id"],
                user=request.user,
                is_active=True,
            )
        except Vehicle.DoesNotExist:
            return Response(
                {"error": "Vehicle not found or does not belong to you."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        booking = create_booking(
            user=request.user,
            slot_id=serializer.validated_data["slot_id"],
            vehicle=vehicle,
            start_time=serializer.validated_data["start_time"],
            end_time=serializer.validated_data["end_time"],
        )
        return Response(BookingSerializer(booking).data, status=status.HTTP_201_CREATED)


class BookingListView(generics.ListAPIView):
    serializer_class = BookingSerializer

    def get_queryset(self):
        qs = Booking.objects.select_related(
            "user", "vehicle", "slot", "slot__society"
        ).prefetch_related(
            Prefetch(
                "payments",
                queryset=Payment.objects.order_by("-created_at"),
                to_attr="prefetched_payments",
            )
        )

        if self.request.user.role in (User.Role.SOCIETY_ADMIN, User.Role.GUARD):
            qs = qs.filter(slot__society_id=self.request.user.society_id)
        else:
            qs = qs.filter(user=self.request.user)

        status_filter = self.request.query_params.get("status")
        if status_filter:
            qs = qs.filter(status=status_filter)
        return qs


class BookingDetailView(generics.RetrieveAPIView):
    serializer_class = BookingSerializer

    def get_queryset(self):
        qs = Booking.objects.select_related(
            "user", "vehicle", "slot", "slot__society"
        ).prefetch_related(
            Prefetch(
                "payments",
                queryset=Payment.objects.order_by("-created_at"),
                to_attr="prefetched_payments",
            )
        )
        if self.request.user.role in (User.Role.SOCIETY_ADMIN, User.Role.GUARD):
            return qs.filter(slot__society_id=self.request.user.society_id)
        return qs.filter(user=self.request.user)


class BookingCancelView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        try:
            booking = Booking.objects.get(id=pk, user=request.user)
        except Booking.DoesNotExist:
            return Response(
                {"error": "Booking not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        booking = cancel_booking(booking, request.user)
        return Response(BookingSerializer(booking).data)


class BookingQRView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk):
        try:
            booking = Booking.objects.get(id=pk, user=request.user)
        except Booking.DoesNotExist:
            return Response(
                {"error": "Booking not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        if booking.status not in (Booking.Status.CONFIRMED, Booking.Status.ACTIVE):
            return Response(
                {"error": "QR code only available for confirmed or active bookings."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        qr_image = generate_qr_image(booking.qr_code_token)
        return HttpResponse(qr_image.getvalue(), content_type="image/png")
