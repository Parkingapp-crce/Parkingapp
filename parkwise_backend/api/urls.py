from django.urls import path
from .views import (
    RegisterView, OwnerRegisterView, LoginView, ProfileView,
    OwnerDashboardView, AdminDashboardView, ParkingLotsView,
    ForgotPasswordView, VerifyOTPView, ResetPasswordView,
    BookSlotView, MyBookingsView, BookingQRView, CancelBookingView,
    BookingQRImageView, ValidateQRView, OwnerEntryLogsView,
)

urlpatterns = [
    # Auth
    path('register', RegisterView.as_view()),
    path('register-owner', OwnerRegisterView.as_view()),
    path('login', LoginView.as_view()),
    path('profile', ProfileView.as_view()),

    # Password reset
    path('forgot-password', ForgotPasswordView.as_view()),
    path('verify-otp', VerifyOTPView.as_view()),
    path('reset-password', ResetPasswordView.as_view()),

    # Dashboards
    path('owner/dashboard', OwnerDashboardView.as_view()),
    path('admin/dashboard', AdminDashboardView.as_view()),

    # Parking lots
    path('parking-lots', ParkingLotsView.as_view()),

    path('book-slot',                   BookSlotView.as_view(),    name='book-slot'),
    path('my-bookings',                 MyBookingsView.as_view(),  name='my-bookings'),
    path('booking/<int:booking_id>/qr', BookingQRView.as_view(),   name='booking-qr'),
    path('cancel-booking',              CancelBookingView.as_view(), name='cancel-booking'),

    path('booking/<int:booking_id>/qr-image', BookingQRImageView.as_view(), name='booking-qr-image'),
    path('validate-qr',                        ValidateQRView.as_view(),     name='validate-qr'),
    path('owner/entry-logs',                   OwnerEntryLogsView.as_view(), name='owner-entry-logs'),
]