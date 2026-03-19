from django.urls import path

from . import views

urlpatterns = [
    path("", views.BookingCreateView.as_view(), name="booking-create"),
    path("list/", views.BookingListView.as_view(), name="booking-list"),
    path("<uuid:pk>/", views.BookingDetailView.as_view(), name="booking-detail"),
    path("<uuid:pk>/cancel/", views.BookingCancelView.as_view(), name="booking-cancel"),
    path("<uuid:pk>/qr/", views.BookingQRView.as_view(), name="booking-qr"),
]
