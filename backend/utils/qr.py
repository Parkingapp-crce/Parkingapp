import io

import jwt
import qrcode
from django.conf import settings
from django.utils import timezone


def generate_qr_token(booking):
    payload = {
        "booking_id": str(booking.id),
        "booking_number": booking.booking_number,
        "user_id": str(booking.user_id),
        "vehicle_reg": booking.vehicle.registration_no,
        "slot_id": str(booking.slot_id),
        "slot_number": booking.slot.slot_number,
        "start_time": booking.start_time.isoformat(),
        "end_time": booking.end_time.isoformat(),
        "iat": int(timezone.now().timestamp()),
    }
    return jwt.encode(payload, settings.QR_SIGNING_SECRET, algorithm="HS256")


def decode_qr_token(token):
    return jwt.decode(token, settings.QR_SIGNING_SECRET, algorithms=["HS256"])


def generate_qr_image(qr_token):
    img = qrcode.make(qr_token)
    buffer = io.BytesIO()
    img.save(buffer, format="PNG")
    buffer.seek(0)
    return buffer
