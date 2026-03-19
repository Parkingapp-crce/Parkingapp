from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.bookings.models import Booking

from .serializers import PaymentInitiateSerializer, PaymentVerifySerializer
from .services import create_razorpay_order, handle_razorpay_webhook, verify_payment


class PaymentInitiateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = PaymentInitiateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            booking = Booking.objects.get(
                id=serializer.validated_data["booking_id"],
                user=request.user,
                status=Booking.Status.PENDING_PAYMENT,
            )
        except Booking.DoesNotExist:
            return Response(
                {"error": "Booking not found or not in pending payment state."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        order_data = create_razorpay_order(booking)
        return Response(order_data, status=status.HTTP_201_CREATED)


class PaymentVerifyView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = PaymentVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        payment = verify_payment(
            razorpay_order_id=serializer.validated_data["razorpay_order_id"],
            razorpay_payment_id=serializer.validated_data["razorpay_payment_id"],
            razorpay_signature=serializer.validated_data["razorpay_signature"],
        )
        return Response(
            {"status": "payment_verified", "payment_id": str(payment.id)}
        )


class RazorpayWebhookView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        signature = request.headers.get("X-Razorpay-Signature", "")
        body = request.body.decode("utf-8")

        handle_razorpay_webhook(body, signature)
        return Response({"status": "ok"})
