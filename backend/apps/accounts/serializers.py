from django.contrib.auth import get_user_model
from rest_framework import serializers
from rest_framework.exceptions import AuthenticationFailed
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from apps.societies.models import Society

from .models import Vehicle

User = get_user_model()


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)

    class Meta:
        model = User
        fields = ["email", "phone", "full_name", "password"]

    def create(self, validated_data):
        return User.objects.create_user(**validated_data)


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token["role"] = user.role
        token["full_name"] = user.full_name
        token["approval_status"] = user.approval_status
        if user.society_id:
            token["society_id"] = str(user.society_id)
        return token

    def validate(self, attrs):
        data = super().validate(attrs)

        if (
            self.user.role == User.Role.GUARD
            and self.user.approval_status != User.ApprovalStatus.APPROVED
        ):
            status_label = self.user.get_approval_status_display().lower()
            raise AuthenticationFailed(
                f"Guard access is {status_label}. Please contact your society admin."
            )

        return data


class GuardRegistrationSerializer(serializers.Serializer):
    full_name = serializers.CharField(max_length=150)
    email = serializers.EmailField()
    phone = serializers.CharField(max_length=15)
    password = serializers.CharField(write_only=True, min_length=8)
    society_id = serializers.UUIDField()

    def validate_email(self, value):
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value

    def validate_phone(self, value):
        if User.objects.filter(phone=value).exists():
            raise serializers.ValidationError("A user with this phone number already exists.")
        return value

    def validate_society_id(self, value):
        try:
            society = Society.objects.get(id=value, is_active=True)
        except Society.DoesNotExist as exc:
            raise serializers.ValidationError("Selected society was not found.") from exc
        self.context["selected_society"] = society
        return value

    def create(self, validated_data):
        society = self.context["selected_society"]
        user = User.objects.create_user(
            email=validated_data["email"],
            password=validated_data["password"],
            full_name=validated_data["full_name"],
            phone=validated_data["phone"],
            role=User.Role.GUARD,
            approval_status=User.ApprovalStatus.PENDING,
            society=society,
        )
        user.approval_notes = "Awaiting approval from society admin."
        user.save(update_fields=["approval_notes"])
        return user


class UserProfileSerializer(serializers.ModelSerializer):
    society_name = serializers.CharField(source="society.name", read_only=True)

    class Meta:
        model = User
        fields = [
            "id",
            "email",
            "phone",
            "full_name",
            "role",
            "approval_status",
            "approval_notes",
            "approved_at",
            "society",
            "society_name",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "email",
            "role",
            "approval_status",
            "approval_notes",
            "approved_at",
            "society",
            "society_name",
            "created_at",
        ]


class VehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehicle
        fields = ["id", "vehicle_type", "registration_no", "make_model", "is_active", "created_at"]
        read_only_fields = ["id", "is_active", "created_at"]

    def create(self, validated_data):
        validated_data["user"] = self.context["request"].user
        return super().create(validated_data)
