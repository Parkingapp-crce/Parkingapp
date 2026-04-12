from django.contrib import admin
from .models import UserProfile, ParkingLot
from .models import Booking, QRCode, EntryLog


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

@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = ['id', 'customer', 'parking_lot', 'vehicle_number', 'status', 'start_time', 'end_time']
    list_filter = ['status']
    search_fields = ['customer__username', 'vehicle_number']

@admin.register(QRCode)
class QRCodeAdmin(admin.ModelAdmin):
    list_display = ['id', 'booking', 'code', 'is_used', 'expires_at']
    list_filter = ['is_used']

@admin.register(EntryLog)
class EntryLogAdmin(admin.ModelAdmin):
    list_display = ['id', 'qr_code', 'scanned_by', 'scanned_at', 'entry_status']
    list_filter = ['entry_status']