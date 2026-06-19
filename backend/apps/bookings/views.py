from django.http import HttpResponse
from django.db.models import Prefetch
from django.utils import timezone
from decimal import Decimal
import math
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

    def get_object(self):
        obj = super().get_object()
        if obj.status == Booking.Status.PENDING_PAYMENT:
            # Auto-verify pending payments from Stripe or Razorpay when refreshing
            from apps.payments.models import Payment
            from apps.payments.services import verify_checkout_session, sync_razorpay_order_status
            
            # Stripe verification
            stripe_payments = obj.payments.filter(
                provider=Payment.Provider.STRIPE, 
                status=Payment.Status.CREATED
            ).exclude(stripe_checkout_session_id__isnull=True)
            
            for payment in stripe_payments:
                try:
                    verify_checkout_session(payment.stripe_checkout_session_id)
                except Exception as e:
                    print(f"Auto-verify (Stripe) failed for {payment.id}: {e}")

            # Razorpay verification
            razorpay_payments = obj.payments.filter(
                provider=Payment.Provider.RAZORPAY, 
                status=Payment.Status.CREATED
            ).exclude(razorpay_order_id__isnull=True)

            for payment in razorpay_payments:
                try:
                    sync_razorpay_order_status(payment.razorpay_order_id)
                except Exception as e:
                    print(f"Auto-verify (Razorpay) failed for {payment.id}: {e}")
            
            obj.refresh_from_db()
        return obj


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
        print(f"QR View hit for booking {pk}")
        try:
            booking = Booking.objects.get(id=pk, user=request.user)
        except Booking.DoesNotExist:
            print("Booking not found")
            return Response(
                {"error": "Booking not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        print(f"Booking status is {booking.status}")
        if booking.status not in (Booking.Status.CONFIRMED, Booking.Status.ACTIVE):
            print("Booking status invalid for QR")
            return Response(
                {"error": "QR code only available for confirmed or active bookings."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        print("Generating QR image...")
        qr_image = generate_qr_image(booking.qr_code_token)
        print("QR image generated successfully")
        return HttpResponse(qr_image.getvalue(), content_type="image/png")


OVERSTAY_PENALTY_RATE = Decimal("0.20")  # 20% of booking amount per hour


class BookingOvertimeView(APIView):
    """Read-only: returns live overtime status for an active booking.
    Does NOT create a penalty — that only happens when the exit QR is scanned.
    The Flutter app uses this to show the red overtime counter and estimated charge.
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk):
        try:
            booking = Booking.objects.select_related("slot").get(
                id=pk, user=request.user
            )
        except Booking.DoesNotExist:
            return Response(
                {"error": "Booking not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Only active bookings (entry scanned, not yet exited) can be in overtime
        if booking.status != Booking.Status.ACTIVE:
            return Response(
                {
                    "is_overtime": False,
                    "overstay_minutes": 0,
                    "estimated_penalty_amount": "0.00",
                    "penalty_rate_per_hour": "0.00",
                }
            )

        now = timezone.now()
        is_overtime = now > booking.end_time
        overstay_minutes = 0
        estimated_penalty = Decimal("0.00")
        penalty_per_hour = Decimal("0.00")

        if is_overtime:
            overstay_minutes = int((now - booking.end_time).total_seconds() / 60)
            # 20% of booking amount per overstay hour (ceil hours)
            penalty_per_hour = booking.amount * OVERSTAY_PENALTY_RATE
            overstay_hours = Decimal(str(math.ceil(max(overstay_minutes, 1) / 60)))
            estimated_penalty = penalty_per_hour * overstay_hours

        return Response(
            {
                "is_overtime": is_overtime,
                "overstay_minutes": overstay_minutes,
                "estimated_penalty_amount": str(estimated_penalty.quantize(Decimal("0.01"))),
                "penalty_rate_per_hour": str(penalty_per_hour.quantize(Decimal("0.01"))),
            }
        )
