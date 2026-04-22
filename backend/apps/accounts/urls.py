from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from . import views

urlpatterns = [
    path("register/", views.RegisterView.as_view(), name="register"),
    path("guard/register/", views.GuardRegisterView.as_view(), name="guard-register"),
    path("login/", views.CustomTokenObtainPairView.as_view(), name="login"),
    path("token/refresh/", TokenRefreshView.as_view(), name="token-refresh"),
    path("profile/", views.ProfileView.as_view(), name="profile"),
    path("vehicles/", views.VehicleListCreateView.as_view(), name="vehicle-list-create"),
    path("vehicles/<uuid:pk>/", views.VehicleDestroyView.as_view(), name="vehicle-destroy"),
]
