from django.urls import path
from .views import (
    RegisterView, OwnerRegisterView, LoginView,
    ProfileView, GoogleLoginView,
    ForgotPasswordView, VerifyOTPView, ResetPasswordView,
)

urlpatterns = [
    path('register', RegisterView.as_view()),
    path('register-owner', OwnerRegisterView.as_view()),
    path('login', LoginView.as_view()),
    path('profile', ProfileView.as_view()),
    path('google-login', GoogleLoginView.as_view()),
    path('forgot-password', ForgotPasswordView.as_view()),
    path('verify-otp', VerifyOTPView.as_view()),
    path('reset-password', ResetPasswordView.as_view()),
]