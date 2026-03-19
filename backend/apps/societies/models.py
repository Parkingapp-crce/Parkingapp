import uuid

from django.db import models


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
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = "societies"
        ordering = ["name"]

    def __str__(self):
        return f"{self.name} - {self.city}"


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
