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

        payment, checkout_url = create_stripe_penalty_checkout_session(
            penalty,
            request,
        )
        serializer = PaymentSerializer(
            payment,
            context={"checkout_url": checkout_url},
        )
        return Response(serializer.data, status=status.HTTP_201_CREATED)
