import math
from decimal import Decimal

from .models import Penalty

# Overstay penalty: 20% of the booking's hourly rate per hour of overstay
OVERSTAY_PENALTY_RATE = Decimal("0.20")


def create_overstay_penalty(booking, overstay_minutes):
    overstay_hours = math.ceil(overstay_minutes / 60)
    # 20% of booking amount per hour of overstay
    penalty_per_hour = booking.amount * OVERSTAY_PENALTY_RATE
    amount = penalty_per_hour * overstay_hours

    penalty = Penalty.objects.create(
        booking=booking,
        user=booking.user,
        overstay_minutes=overstay_minutes,
        amount=amount,
    )
    return {
        "penalty_id": str(penalty.id),
        "amount": str(amount),
        "overstay_minutes": overstay_minutes,
        "overstay_hours": overstay_hours,
    }
