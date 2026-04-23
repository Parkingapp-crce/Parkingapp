import uuid

from django.db import models


class Booking(models.Model):
    class Status(models.TextChoices):
        PENDING_PAYMENT = "pending_payment", "Pending Payment"
        CONFIRMED = "confirmed", "Confirmed"
        ACTIVE = "active", "Active"
        COMPLETED = "completed", "Completed"
        CANCELLED = "cancelled", "Cancelled"
        NO_SHOW = "no_show", "No Show"
        EXPIRED = "expired", "Expired"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    booking_number = models.CharField(max_length=20, unique=True, db_index=True)
    user = models.ForeignKey(
        "accounts.User", on_delete=models.CASCADE, related_name="bookings"
    )
    vehicle = models.ForeignKey(
        "accounts.Vehicle", on_delete=models.CASCADE, related_name="bookings"
    )
    slot = models.ForeignKey(
        "societies.ParkingSlot", on_delete=models.CASCADE, related_name="bookings"
    )
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()
    actual_entry = models.DateTimeField(null=True, blank=True)
    actual_exit = models.DateTimeField(null=True, blank=True)
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.PENDING_PAYMENT
    )
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    qr_code_token = models.TextField(unique=True)
    lock_expires_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["slot", "start_time", "end_time"]),
            models.Index(fields=["user", "status"]),
            models.Index(fields=["status", "end_time"]),
        ]

    def __str__(self):
        return f"{self.booking_number} - {self.slot.slot_number}"
