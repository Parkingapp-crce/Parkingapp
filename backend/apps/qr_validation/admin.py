from django.contrib import admin

from .models import ScanEvent


@admin.register(ScanEvent)
class ScanEventAdmin(admin.ModelAdmin):
    list_display = (
        "scanned_at",
        "event_type",
        "result",
        "guard",
        "society",
        "booking",
    )
    list_filter = ("event_type", "result", "society")
    search_fields = (
        "guard__full_name",
        "guard__email",
        "booking__booking_number",
        "booking__vehicle__registration_no",
    )
