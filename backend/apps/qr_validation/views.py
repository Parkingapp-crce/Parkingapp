from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.permissions import CanScanEntry, CanScanExit

from .serializers import QRScanSerializer
from .services import validate_entry, validate_exit


class EntryValidationView(APIView):
    permission_classes = [CanScanEntry]

    def post(self, request):
        serializer = QRScanSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        result = validate_entry(serializer.validated_data["qr_token"])
        return Response(result)


class ExitValidationView(APIView):
    permission_classes = [CanScanExit]

    def post(self, request):
        serializer = QRScanSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        result = validate_exit(serializer.validated_data["qr_token"])
        return Response(result)
