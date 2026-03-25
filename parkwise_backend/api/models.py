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
            status='active',
            end_time__gt=timezone.now()
        ).count()
        return self.total_slots - booked


# ─────────────────────────────────────────────
# SIGNAL — auto create UserProfile on user creation
# ─────────────────────────────────────────────
@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        role = 'admin' if instance.is_superuser else 'customer'
        UserProfile.objects.get_or_create(user=instance, defaults={'role': role})