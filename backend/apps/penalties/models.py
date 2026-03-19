import uuid

from django.db import models


class Penalty(models.Model):
    class Status(models.TextChoices):
        UNPAID = "unpaid", "Unpaid"
        PAID = "paid", "Paid"
        WAIVED = "waived", "Waived"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    booking = models.ForeignKey(
        "bookings.Booking", on_delete=models.CASCADE, related_name="penalties"
    )
    user = models.ForeignKey(
        "accounts.User", on_delete=models.CASCADE, related_name="penalties"
    )
    overstay_minutes = models.IntegerField()
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.UNPAID
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = "penalties"
        ordering = ["-created_at"]

    def __str__(self):
        return f"Penalty for {self.booking.booking_number} - {self.amount}"
