import uuid
from django.db import models
from django.contrib.auth.models import User
from django.db.models.signals import post_save
from django.dispatch import receiver


# ─────────────────────────────────────────────
# USER PROFILE — adds role to every user
# ─────────────────────────────────────────────
class UserProfile(models.Model):
    ROLE_CHOICES = [
        ('customer', 'Customer'),
        ('owner', 'Owner'),
        ('admin', 'Admin'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='customer')

    def __str__(self):
        return f"{self.user.email} — {self.role}"


# ─────────────────────────────────────────────
# PARKING LOT — owned by an owner
# ─────────────────────────────────────────────
class ParkingLot(models.Model):
    owner = models.OneToOneField(User, on_delete=models.CASCADE, related_name='parking_lot')
    name = models.CharField(max_length=255)
    address = models.TextField()
    city = models.CharField(max_length=100)
    total_slots = models.PositiveIntegerField()
    price_per_hour = models.DecimalField(max_digits=6, decimal_places=2)
    opening_time = models.TimeField()
    closing_time = models.TimeField()
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.name} — {self.city}"

    @property
    def available_slots(self):
        from django.utils import timezone
        booked = self.bookings.filter(
            status='confirmed',
            end_time__gt=timezone.now()
        ).count()
        return self.total_slots - booked

# ─────────────────────────────────────────────
# BOOKING — customer books a parking slot
# ─────────────────────────────────────────────
class Booking(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]

    customer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='bookings')
    parking_lot = models.ForeignKey(ParkingLot, on_delete=models.CASCADE, related_name='bookings')
    vehicle_number = models.CharField(max_length=20)
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()
    amount = models.DecimalField(max_digits=8, decimal_places=2)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Booking #{self.id} — {self.customer.username} @ {self.parking_lot.name}"


# ─────────────────────────────────────────────
# QR CODE — generated after booking confirmed
# ─────────────────────────────────────────────
class QRCode(models.Model):
    booking = models.OneToOneField(Booking, on_delete=models.CASCADE, related_name='qr_code')
    code = models.UUIDField(default=uuid.uuid4, unique=True, editable=False)
    is_used = models.BooleanField(default=False)
    expires_at = models.DateTimeField()

    def __str__(self):
        return f"QR #{self.booking.id} — {'Used' if self.is_used else 'Active'}"


# ─────────────────────────────────────────────
# ENTRY LOG — recorded when owner scans QR
# ─────────────────────────────────────────────
class EntryLog(models.Model):
    ENTRY_STATUS_CHOICES = [
        ('allowed', 'Allowed'),
        ('denied', 'Denied'),
    ]

    qr_code = models.ForeignKey(QRCode, on_delete=models.CASCADE, related_name='entry_logs')
    scanned_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='scanned_logs')
    scanned_at = models.DateTimeField(auto_now_add=True)
    entry_status = models.CharField(max_length=10, choices=ENTRY_STATUS_CHOICES)

    def __str__(self):
        return f"EntryLog — {self.entry_status} at {self.scanned_at}"

# ─────────────────────────────────────────────
# SIGNAL — auto create UserProfile on user creation
# ─────────────────────────────────────────────
@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        role = 'admin' if instance.is_superuser else 'customer'
        UserProfile.objects.get_or_create(user=instance, defaults={'role': role})