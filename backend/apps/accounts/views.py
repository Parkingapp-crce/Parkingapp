from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import UserNotification, Vehicle
from .serializers import (
    CustomTokenObtainPairSerializer,
    GuardCredentialSerializer,
    GuardPermissionUpdateSerializer,
    GuardProfileSerializer,
    RegisterSerializer,
    UserNotificationSerializer,
    UserProfileSerializer,
    VehicleSerializer,
)
from .permissions import IsSocietyAdmin


class RegisterView(generics.CreateAPIView):
    serializer_class = RegisterSerializer
    permission_classes = [permissions.AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        refresh = RefreshToken.for_user(user)
        return Response(
            {
                "user": UserProfileSerializer(user).data,
                "membership_status": "pending_approval" if user.society_id is None else "active",
                "tokens": {
                    "refresh": str(refresh),
                    "access": str(refresh.access_token),
                },
            },
            status=status.HTTP_201_CREATED,
        )


class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer


class ProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = UserProfileSerializer

    def get_object(self):
        return self.request.user


class VehicleListCreateView(generics.ListCreateAPIView):
    serializer_class = VehicleSerializer

    def get_queryset(self):
        return Vehicle.objects.filter(user=self.request.user, is_active=True)


class VehicleDestroyView(generics.DestroyAPIView):
    serializer_class = VehicleSerializer

    def get_queryset(self):
        return Vehicle.objects.filter(user=self.request.user)

    def perform_destroy(self, instance):
        instance.is_active = False
        instance.save(update_fields=["is_active"])


class GuardCredentialView(generics.ListCreateAPIView):
    permission_classes = [IsSocietyAdmin]

    def get_queryset(self):
        return self.request.user.society.members.filter(role="guard").order_by("-created_at")

    def get_serializer_class(self):
        if self.request.method == "GET":
            return GuardProfileSerializer
        return GuardCredentialSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = serializer.save()
        user = result["user"]

        return Response(
            {
                "guard": GuardProfileSerializer(user).data,
                "credentials": {
                    "email": user.email,
                    "temporary_password": result["temporary_password"],
                },
            },
            status=status.HTTP_201_CREATED,
        )


class GuardCredentialDetailView(generics.RetrieveUpdateAPIView):
    permission_classes = [IsSocietyAdmin]

    def get_queryset(self):
        return self.request.user.society.members.filter(role="guard")

    def get_serializer_class(self):
        if self.request.method in ["PUT", "PATCH"]:
            return GuardPermissionUpdateSerializer
        return GuardProfileSerializer


class NotificationListView(generics.ListAPIView):
    serializer_class = UserNotificationSerializer

    def get_queryset(self):
        return UserNotification.objects.filter(user=self.request.user)


class NotificationReadView(generics.UpdateAPIView):
    serializer_class = UserNotificationSerializer

    def get_queryset(self):
        return UserNotification.objects.filter(user=self.request.user)

    def patch(self, request, *args, **kwargs):
        notification = self.get_object()
        notification.is_read = True
        notification.save(update_fields=["is_read"])
        return Response(UserNotificationSerializer(notification).data)
