from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.payments.serializers import PaymentSerializer
from apps.payments.services import create_stripe_penalty_checkout_session

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

        gateway = request.data.get("gateway", "stripe")
        embedded = request.data.get("embedded", False)
        
        from django.conf import settings
        bypass_requested = request.data.get("bypass", False)
        bypass_allowed = getattr(
            settings,
            "PAYMENT_BYPASS",
            getattr(settings, "DEBUG", False),
        )
        allow_bypass = bypass_requested and bypass_allowed
        if allow_bypass:
            from apps.payments.services import create_bypass_penalty_payment
            payment = create_bypass_penalty_payment(penalty, request)
            serializer = PaymentSerializer(payment)
            return Response(serializer.data, status=status.HTTP_201_CREATED)

        if gateway == "stripe":
            payment, checkout_url, checkout_client_secret = create_stripe_penalty_checkout_session(
                penalty,
                request,
                embedded=embedded,
            )
            serializer = PaymentSerializer(
                payment,
                context={
                    "checkout_url": checkout_url,
                    "checkout_client_secret": checkout_client_secret,
                    "stripe_publishable_key": settings.STRIPE_PUBLISHABLE_KEY if embedded else None,
                },
            )
        else:
            from apps.payments.services import create_razorpay_penalty_order
            payment, razorpay_order_id = create_razorpay_penalty_order(penalty, request)
            serializer = PaymentSerializer(payment)

        return Response(serializer.data, status=status.HTTP_201_CREATED)
