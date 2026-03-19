from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.payments.services import create_razorpay_order

from .models import Penalty
from .serializers import PenaltySerializer


class PenaltyListView(generics.ListAPIView):
    serializer_class = PenaltySerializer

    def get_queryset(self):
        qs = Penalty.objects.filter(user=self.request.user).select_related("booking")
        status_filter = self.request.query_params.get("status")
        if status_filter:
            qs = qs.filter(status=status_filter)
        return qs


class PenaltyPayView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        try:
            penalty = Penalty.objects.get(
                id=pk, user=request.user, status=Penalty.Status.UNPAID
            )
        except Penalty.DoesNotExist:
            return Response(
                {"error": "Penalty not found or already paid."},
                status=status.HTTP_404_NOT_FOUND,
            )

        # Create a mock booking-like object for Razorpay order creation
        # We reuse the payment flow — create order with penalty amount
        from apps.payments.models import Payment

        import razorpay
        from django.conf import settings

        if not settings.RAZORPAY_KEY_ID:
            return Response(
                {"error": "Payment not configured."},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        client = razorpay.Client(
            auth=(settings.RAZORPAY_KEY_ID, settings.RAZORPAY_KEY_SECRET)
        )
        order_data = {
            "amount": int(penalty.amount * 100),
            "currency": "INR",
            "receipt": f"PENALTY-{penalty.id}",
            "notes": {"penalty_id": str(penalty.id)},
        }
        razorpay_order = client.order.create(data=order_data)

        Payment.objects.create(
            penalty=penalty,
            payment_type=Payment.PaymentType.PENALTY,
            amount=penalty.amount,
            razorpay_order_id=razorpay_order["id"],
        )

        return Response(
            {
                "order_id": razorpay_order["id"],
                "amount": razorpay_order["amount"],
                "currency": razorpay_order["currency"],
                "key_id": settings.RAZORPAY_KEY_ID,
            },
            status=status.HTTP_201_CREATED,
        )
