import io

import jwt
import qrcode
from qrcode.constants import ERROR_CORRECT_M
from django.conf import settings
from django.utils import timezone


def generate_qr_token(booking):
    # Keep payload minimal so rendered QR remains easy to scan across devices.
    payload = {
        "booking_id": str(booking.id),
        "iat": int(timezone.now().timestamp()),
    }
    return jwt.encode(payload, settings.QR_SIGNING_SECRET, algorithm="HS256")


def decode_qr_token(token):
    return jwt.decode(token, settings.QR_SIGNING_SECRET, algorithms=["HS256"])


def generate_qr_image(qr_token):
    qr = qrcode.QRCode(
        version=None,
        error_correction=ERROR_CORRECT_M,
        box_size=10,
        border=4,
    )
    qr.add_data(qr_token)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")
    buffer = io.BytesIO()
    img.save(buffer, format="PNG")
    buffer.seek(0)
    return buffer
