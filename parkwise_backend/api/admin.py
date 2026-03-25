from django.contrib import admin
from .models import UserProfile, ParkingLot


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'role')
    list_filter = ('role',)
    search_fields = ('user__email',)


@admin.register(ParkingLot)
class ParkingLotAdmin(admin.ModelAdmin):
    list_display = ('name', 'city', 'total_slots', 'price_per_hour', 'is_active')
    list_filter = ('city', 'is_active')
    search_fields = ('name', 'city')
