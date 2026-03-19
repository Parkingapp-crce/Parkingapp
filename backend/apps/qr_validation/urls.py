from django.urls import path

from . import views

urlpatterns = [
    path("entry/", views.EntryValidationView.as_view(), name="qr-entry"),
    path("exit/", views.ExitValidationView.as_view(), name="qr-exit"),
]
