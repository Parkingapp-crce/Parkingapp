import uuid

from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.db import models

from .managers import UserManager


class User(AbstractBaseUser, PermissionsMixin):
    class Role(models.TextChoices):
        USER = "user", "User"
        SOCIETY_ADMIN = "society_admin", "Society Admin"
        GUARD = "guard", "Guard"
        SUPER_ADMIN = "super_admin", "Super Admin"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=15, unique=True)
    full_name = models.CharField(max_length=150)
    role = models.CharField(max_length=20, choices=Role.choices, default=Role.USER)
    society = models.ForeignKey(
        "societies.Society",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="members",
    )
    flat_number = models.CharField(max_length=20, blank=True)
    floor_number = models.CharField(max_length=10, blank=True)
    can_scan_entry = models.BooleanField(default=False)
    can_scan_exit = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    objects = UserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["full_name", "phone"]

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.full_name} ({self.email})"


class Vehicle(models.Model):
    class VehicleType(models.TextChoices):
        CAR = "car", "Car"
        BIKE = "bike", "Bike"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="vehicles")
    vehicle_type = models.CharField(max_length=10, choices=VehicleType.choices)
    registration_no = models.CharField(max_length=20, unique=True)
    make_model = models.CharField(max_length=100, blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["user", "is_active"])]

    def __str__(self):
        return f"{self.registration_no} ({self.vehicle_type})"


class UserNotification(models.Model):
    class NotificationType(models.TextChoices):
        JOIN_REQUEST = "join_request", "Join Request"
        JOIN_APPROVED = "join_approved", "Join Approved"
        JOIN_REJECTED = "join_rejected", "Join Rejected"
        SLOT_PENDING = "slot_pending", "Slot Pending"
        SLOT_APPROVED = "slot_approved", "Slot Approved"
        SLOT_REJECTED = "slot_rejected", "Slot Rejected"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="notifications",
    )
    notification_type = models.CharField(max_length=32, choices=NotificationType.choices)
    title = models.CharField(max_length=120)
    message = models.CharField(max_length=255)
    payload = models.JSONField(default=dict, blank=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["user", "is_read", "created_at"])]

    def __str__(self):
        return f"{self.user.email}: {self.title}"
