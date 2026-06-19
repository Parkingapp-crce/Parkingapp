from django.conf import settings
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.bookings.models import Booking

from .serializers import (
    PaymentInitiateSerializer,
    PaymentSerializer,
    PaymentVerifySerializer,
)
from .services import (
    create_stripe_checkout_session,
    handle_stripe_webhook,
    verify_checkout_session,
    create_razorpay_order,
    verify_razorpay_payment,
)


class PaymentInitiateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = PaymentInitiateSerializer(data=request.data)
        if not serializer.is_valid():
            print("Serializer errors:", serializer.errors)
        serializer.is_valid(raise_exception=True)

        try:
            booking = Booking.objects.get(
                id=serializer.validated_data["booking_id"],
                user=request.user,
                status=Booking.Status.PENDING_PAYMENT,
            )
        except Booking.DoesNotExist:
            print("Booking not found. Validated data:", serializer.validated_data)
            return Response(
                {"error": "Booking not found or not in pending payment state."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        gateway = serializer.validated_data.get("gateway", "stripe")
        embedded = serializer.validated_data.get("embedded", False)
        if gateway == "stripe":
            payment, checkout_url, checkout_client_secret = create_stripe_checkout_session(
                booking,
                request,
                embedded=embedded,
            )
            serializer = PaymentSerializer(
                payment,
                context={
                    "checkout_url": checkout_url,
                    "checkout_client_secret": checkout_client_secret,
                    "stripe_publishable_key": (
                        settings.STRIPE_PUBLISHABLE_KEY if embedded else None
                    ),
                },
            )
        else:  # razorpay
            payment, razorpay_order_id = create_razorpay_order(
                booking,
                request,
            )
            serializer = PaymentSerializer(payment)

        return Response(serializer.data, status=status.HTTP_201_CREATED)


class PaymentVerifyView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = PaymentVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        payment = verify_checkout_session(
            checkout_session_id=serializer.validated_data["checkout_session_id"],
            user=request.user,
        )
        return Response(PaymentSerializer(payment).data)


class PaymentVerifyRazorpayView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        razorpay_order_id = request.data.get("razorpay_order_id")
        razorpay_payment_id = request.data.get("razorpay_payment_id")
        razorpay_signature = request.data.get("razorpay_signature")

        if not all([razorpay_order_id, razorpay_payment_id, razorpay_signature]):
            return Response(
                {"error": "razorpay_order_id, razorpay_payment_id, and razorpay_signature are required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        payment = verify_razorpay_payment(
            razorpay_order_id=razorpay_order_id,
            razorpay_payment_id=razorpay_payment_id,
            razorpay_signature=razorpay_signature,
            user=request.user,
        )
        return Response(PaymentSerializer(payment).data)


class StripeWebhookView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        signature = request.headers.get("Stripe-Signature", "")
        body = request.body.decode("utf-8")

        handle_stripe_webhook(body, signature)
        return Response({"status": "ok"})


class ManualPaymentVerifyView(APIView):
    """Manual payment verification endpoint for testing without webhooks"""
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        """Manually verify a payment by checkout session ID"""
        checkout_session_id = request.data.get("checkout_session_id")
        if not checkout_session_id:
            return Response(
                {"error": "checkout_session_id is required"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            payment = verify_checkout_session(
                checkout_session_id=checkout_session_id,
                user=request.user,
            )
            return Response(PaymentSerializer(payment).data)
        except Exception as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_400_BAD_REQUEST,
            )
