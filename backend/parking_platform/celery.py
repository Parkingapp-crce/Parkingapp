import os

from celery import Celery

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "parking_platform.settings.development")

app = Celery("parking_platform")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()
