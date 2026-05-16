import uuid
import secrets

from django.db import models


def generate_society_join_code():
    return secrets.token_hex(4).upper()


class Society(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200)
    address = models.TextField()
    city = models.CharField(max_length=100)
    state = models.CharField(max_length=100)
    pincode = models.CharField(max_length=10)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    contact_email = models.EmailField()
    contact_phone = models.CharField(max_length=15)
    join_code = models.CharField(
        max_length=12,
        unique=True,
        default=generate_society_join_code,
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = "societies"
        ordering = ["name"]

    def __str__(self):
        return f"{self.name} - {self.city}"

    def save(self, *args, **kwargs):
        if not self.join_code:
            self.join_code = generate_society_join_code()
        super().save(*args, **kwargs)


class ParkingSlot(models.Model):
    class SlotState(models.TextChoices):
        AVAILABLE = "available", "Available"
        RESERVED = "reserved", "Reserved"
        OCCUPIED = "occupied", "Occupied"
        BLOCKED = "blocked", "Blocked"

    class SlotType(models.TextChoices):
        CAR = "car", "Car"
        BIKE = "bike", "Bike"

    class OwnershipType(models.TextChoices):
        SOCIETY = "society", "Society"
        RESIDENT = "resident", "Resident"

    class ApprovalStatus(models.TextChoices):
        PENDING = "pending", "Pending"
        APPROVED = "approved", "Approved"
        REJECTED = "rejected", "Rejected"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    society = models.ForeignKey(Society, on_delete=models.CASCADE, related_name="slots")
    slot_number = models.CharField(max_length=50)
    floor = models.CharField(max_length=10, blank=True)
    slot_type = models.CharField(max_length=10, choices=SlotType.choices)
    state = models.CharField(
        max_length=20, choices=SlotState.choices, default=SlotState.AVAILABLE
    )
    ownership_type = models.CharField(
        max_length=20, choices=OwnershipType.choices, default=OwnershipType.SOCIETY
    )
    owner = models.ForeignKey(
        "accounts.User",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="owned_slots",
    )
    created_by = models.ForeignKey(
        "accounts.User",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="created_slots",
    )
    approval_status = models.CharField(
        max_length=20,
        choices=ApprovalStatus.choices,
        default=ApprovalStatus.APPROVED,
        db_index=True,
    )
    approval_notes = models.CharField(max_length=255, blank=True)
    approved_by = models.ForeignKey(
        "accounts.User",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="approved_slots",
    )
    approved_at = models.DateTimeField(null=True, blank=True)
    hourly_rate = models.DecimalField(max_digits=8, decimal_places=2)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = [("society", "slot_number")]
        indexes = [
            models.Index(fields=["society", "state", "slot_type"]),
            models.Index(fields=["state"]),
        ]

    def __str__(self):
        return f"{self.society.name} - {self.slot_number}"


class SocietyMembershipRequest(models.Model):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        APPROVED = "approved", "Approved"
        REJECTED = "rejected", "Rejected"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    society = models.ForeignKey(
        Society,
        on_delete=models.CASCADE,
        related_name="membership_requests",
    )
    user = models.ForeignKey(
        "accounts.User",
        on_delete=models.CASCADE,
        related_name="membership_requests",
    )
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
        db_index=True,
    )
    notes = models.CharField(max_length=255, blank=True)
    reviewed_by = models.ForeignKey(
        "accounts.User",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="reviewed_membership_requests",
    )
    reviewed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["society", "user"],
                condition=models.Q(status="pending"),
                name="unique_pending_membership_request_per_user_society",
            )
        ]

    def __str__(self):
        return f"{self.user.full_name} -> {self.society.name} ({self.status})"


class SlotAvailabilityWindow(models.Model):
    DAY_CHOICES = [
        (0, "Monday"),
        (1, "Tuesday"),
        (2, "Wednesday"),
        (3, "Thursday"),
        (4, "Friday"),
        (5, "Saturday"),
        (6, "Sunday"),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    slot = models.ForeignKey(
        ParkingSlot, on_delete=models.CASCADE, related_name="availability_windows"
    )
    day_of_week = models.IntegerField(choices=DAY_CHOICES)
    start_time = models.TimeField()
    end_time = models.TimeField()
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["day_of_week", "start_time"]

    def __str__(self):
        return f"{self.slot.slot_number} - Day {self.day_of_week}: {self.start_time}-{self.end_time}"
