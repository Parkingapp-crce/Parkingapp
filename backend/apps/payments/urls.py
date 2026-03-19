from django.urls import path

from . import views

urlpatterns = [
    path("initiate/", views.PaymentInitiateView.as_view(), name="payment-initiate"),
    path("verify/", views.PaymentVerifyView.as_view(), name="payment-verify"),
    path("webhook/", views.RazorpayWebhookView.as_view(), name="payment-webhook"),
]
