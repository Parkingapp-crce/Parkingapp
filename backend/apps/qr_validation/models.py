import uuid

from django.db import models


class ScanEvent(models.Model):
    class EventType(models.TextChoices):
        ENTRY = "entry", "Entry"
        EXIT = "exit", "Exit"

    class Result(models.TextChoices):
        APPROVED = "approved", "Approved"
        DENIED = "denied", "Denied"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    booking = models.ForeignKey(
        "bookings.Booking",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="scan_events",
    )
    guard = models.ForeignKey(
        "accounts.User",
        on_delete=models.CASCADE,
        related_name="scan_events",
    )
    society = models.ForeignKey(
        "societies.Society",
        on_delete=models.CASCADE,
        related_name="scan_events",
    )
    event_type = models.CharField(max_length=10, choices=EventType.choices)
    result = models.CharField(max_length=10, choices=Result.choices)
    error_message = models.CharField(max_length=255, blank=True)
    scanned_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-scanned_at"]
        indexes = [
            models.Index(fields=["society", "scanned_at"]),
            models.Index(fields=["guard", "event_type", "scanned_at"]),
        ]

    def __str__(self):
        return f"{self.get_event_type_display()} {self.get_result_display()} - {self.scanned_at}"
