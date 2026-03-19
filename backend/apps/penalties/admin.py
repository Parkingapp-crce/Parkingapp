from django.contrib import admin

from .models import Penalty


@admin.register(Penalty)
class PenaltyAdmin(admin.ModelAdmin):
    list_display = ("booking", "user", "overstay_minutes", "amount", "status", "created_at")
    list_filter = ("status",)
    search_fields = ("booking__booking_number", "user__email")
