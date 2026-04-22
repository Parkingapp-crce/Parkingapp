import uuid

from django.contrib.auth.models import User
from django.db import models
from django.db.models.signals import post_save
from django.dispatch import receiver


class UserProfile(models.Model):
    ROLE_CHOICES = [
        ('customer', 'Customer'),
        ('owner', 'Owner'),
        ('admin', 'Admin'),
        ('guard', 'Guard'),
    ]

    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='profile',
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='customer')
    assigned_lot = models.ForeignKey(
        'ParkingLot',
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='guards',
    )

    def __str__(self):
        return f'{self.user.email} - {self.role}'


class ParkingLot(models.Model):
    owner = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='parking_lot',
    )
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
        return f'{self.name} - {self.city}'

    @property
    def available_slots(self):
        from django.utils import timezone

        booked = self.bookings.filter(
            status__in=['confirmed', 'active'],
            end_time__gt=timezone.now(),
        ).count()
        return self.total_slots - booked


class Booking(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('active', 'Active'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]

    VEHICLE_TYPE_CHOICES = [
        ('2-wheeler', '2-Wheeler'),
        ('4-wheeler', '4-Wheeler'),
    ]

    customer = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='bookings',
    )
    parking_lot = models.ForeignKey(
        ParkingLot,
        on_delete=models.CASCADE,
        related_name='bookings',
    )
    vehicle_number = models.CharField(max_length=20)
    vehicle_type = models.CharField(
        max_length=20,
        choices=VEHICLE_TYPE_CHOICES,
        default='4-wheeler',
    )
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()
    amount = models.DecimalField(max_digits=8, decimal_places=2)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    checked_in_at = models.DateTimeField(null=True, blank=True)
    checked_out_at = models.DateTimeField(null=True, blank=True)
    overstay_minutes = models.PositiveIntegerField(default=0)
    penalty_amount = models.DecimalField(max_digits=8, decimal_places=2, default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'Booking #{self.id} - {self.customer.username} @ {self.parking_lot.name}'

    @property
    def total_charge(self):
        return self.amount + self.penalty_amount

    @property
    def is_overstayed(self):
        from django.utils import timezone

        return bool(
            self.overstay_minutes > 0 or (
                self.checked_in_at and
                not self.checked_out_at and
                timezone.now() > self.end_time
            )
        )


class QRCode(models.Model):
    booking = models.OneToOneField(
        Booking,
        on_delete=models.CASCADE,
        related_name='qr_code',
    )
    code = models.UUIDField(default=uuid.uuid4, unique=True, editable=False)
    is_used = models.BooleanField(default=False)
    expires_at = models.DateTimeField()

    def __str__(self):
        return f"QR #{self.booking.id} - {'Used' if self.is_used else 'Active'}"


class EntryLog(models.Model):
    ENTRY_STATUS_CHOICES = [
        ('allowed', 'Allowed'),
        ('denied', 'Denied'),
    ]

    qr_code = models.ForeignKey(
        QRCode,
        on_delete=models.CASCADE,
        related_name='entry_logs',
    )
    scanned_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='scanned_logs',
    )
    scanned_at = models.DateTimeField(auto_now_add=True)
    entry_status = models.CharField(max_length=10, choices=ENTRY_STATUS_CHOICES)

    def __str__(self):
        return f'EntryLog - {self.entry_status} at {self.scanned_at}'


@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        role = 'admin' if instance.is_superuser else 'customer'
        UserProfile.objects.get_or_create(user=instance, defaults={'role': role})