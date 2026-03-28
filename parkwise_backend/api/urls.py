from django.urls import path
from .views import (
    RegisterView, OwnerRegisterView, LoginView, ProfileView,
    OwnerDashboardView, AdminDashboardView, ParkingLotsView,
    ForgotPasswordView, VerifyOTPView, ResetPasswordView,
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
]