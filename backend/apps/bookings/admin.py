from django.contrib import admin

from .models import Booking


@admin.register(Booking)
class BookingAdmin(admin.ModelAdmin):
    list_display = ("booking_number", "user", "slot", "status", "start_time", "end_time", "amount")
    list_filter = ("status",)
    search_fields = ("booking_number", "user__email", "vehicle__registration_no")
    readonly_fields = ("booking_number", "qr_code_token")
