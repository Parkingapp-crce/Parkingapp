from django.urls import path

from . import views

urlpatterns = [
    path("", views.PenaltyListView.as_view(), name="penalty-list"),
    path("<uuid:pk>/pay/", views.PenaltyPayView.as_view(), name="penalty-pay"),
]
