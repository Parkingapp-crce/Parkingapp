from django.utils import timezone


def is_within_advance_window(dt, max_hours=24):
    now = timezone.now()
    return now <= dt <= now + timezone.timedelta(hours=max_hours)
