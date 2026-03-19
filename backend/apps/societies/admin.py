from django.contrib import admin

from .models import ParkingSlot, SlotAvailabilityWindow, Society


@admin.register(Society)
class SocietyAdmin(admin.ModelAdmin):
    list_display = ("name", "city", "is_active", "created_at")
    list_filter = ("is_active", "city")
    search_fields = ("name", "city")


@admin.register(ParkingSlot)
class ParkingSlotAdmin(admin.ModelAdmin):
    list_display = ("slot_number", "society", "slot_type", "state", "ownership_type", "hourly_rate")
    list_filter = ("state", "slot_type", "ownership_type")
    search_fields = ("slot_number", "society__name")


@admin.register(SlotAvailabilityWindow)
class SlotAvailabilityWindowAdmin(admin.ModelAdmin):
    list_display = ("slot", "day_of_week", "start_time", "end_time", "is_active")
    list_filter = ("day_of_week", "is_active")
