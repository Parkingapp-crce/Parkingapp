from rest_framework import serializers


class QRScanSerializer(serializers.Serializer):
    qr_token = serializers.CharField()
