import secrets
import string

from django.db import transaction
from django.contrib.auth import get_user_model
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from .models import UserNotification, Vehicle
from apps.societies.models import Society, SocietyMembershipRequest

User = get_user_model()


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    role = serializers.ChoiceField(
        choices=[User.Role.USER, User.Role.SOCIETY_ADMIN],
        required=False,
        default=User.Role.USER,
    )
    society_name = serializers.CharField(required=False, allow_blank=False)
    society_address = serializers.CharField(required=False, allow_blank=False)
    society_city = serializers.CharField(required=False, allow_blank=False)
    society_state = serializers.CharField(required=False, allow_blank=False)
    society_pincode = serializers.CharField(required=False, allow_blank=False)
    society_latitude = serializers.DecimalField(
        max_digits=9,
        decimal_places=6,
        required=False,
    )
    society_longitude = serializers.DecimalField(
        max_digits=9,
        decimal_places=6,
        required=False,
    )
    society_join_code = serializers.CharField(required=False, allow_blank=False)
    flat_number = serializers.CharField(required=False, allow_blank=True)
    floor_number = serializers.CharField(required=False, allow_blank=True)

    class Meta:
        model = User
        fields = [
            "email",
            "phone",
            "full_name",
            "password",
            "role",
            "society_name",
            "society_address",
            "society_city",
            "society_state",
            "society_pincode",
            "society_latitude",
            "society_longitude",
            "society_join_code",
            "flat_number",
            "floor_number",
        ]

    def validate(self, attrs):
        role = attrs.get("role", User.Role.USER)
        if role == User.Role.SOCIETY_ADMIN:
            required_fields = [
                "society_name",
                "society_address",
                "society_city",
                "society_state",
                "society_pincode",
                "society_latitude",
                "society_longitude",
            ]
            missing_fields = [field for field in required_fields if attrs.get(field) in (None, "")]
            if missing_fields:
                raise serializers.ValidationError(
                    {
                        field: "This field is required for admin signup."
                        for field in missing_fields
                    }
                )

        join_code = attrs.get("society_join_code")
        if role == User.Role.USER and join_code:
            try:
                attrs["_target_society"] = Society.objects.get(
                    join_code=join_code,
                    is_active=True,
                )
            except Society.DoesNotExist:
                raise serializers.ValidationError(
                    {"society_join_code": "Invalid or inactive society code."}
                )
        return attrs

    def create(self, validated_data):
        role = validated_data.pop("role", User.Role.USER)
        society_data = {
            "name": validated_data.pop("society_name", None),
            "address": validated_data.pop("society_address", None),
            "city": validated_data.pop("society_city", None),
            "state": validated_data.pop("society_state", None),
            "pincode": validated_data.pop("society_pincode", None),
            "latitude": validated_data.pop("society_latitude", None),
            "longitude": validated_data.pop("society_longitude", None),
        }
        target_society = validated_data.pop("_target_society", None)
        validated_data.pop("society_join_code", None)

        with transaction.atomic():
            society = None
            if role == User.Role.SOCIETY_ADMIN:
                society = Society.objects.create(
                    name=society_data["name"],
                    address=society_data["address"],
                    city=society_data["city"],
                    state=society_data["state"],
                    pincode=society_data["pincode"],
                    latitude=society_data["latitude"],
                    longitude=society_data["longitude"],
                    contact_email=validated_data["email"],
                    contact_phone=validated_data["phone"],
                    is_active=True,
                )

            user = User.objects.create_user(
                **validated_data,
                role=role,
                society=society,
            )

            if role == User.Role.USER and target_society is not None:
                join_request = SocietyMembershipRequest.objects.create(
                    society=target_society,
                    user=user,
                    status=SocietyMembershipRequest.Status.PENDING,
                )
                admins = User.objects.filter(
                    role=User.Role.SOCIETY_ADMIN,
                    society=target_society,
                    is_active=True,
                )
                for admin in admins:
                    UserNotification.objects.create(
                        user=admin,
                        notification_type=UserNotification.NotificationType.JOIN_REQUEST,
                        title="New member join request",
                        message=f"{user.full_name} requested to join {target_society.name}.",
                        payload={
                            "join_request_id": str(join_request.id),
                            "user_id": str(user.id),
                            "society_id": str(target_society.id),
                        },
                    )

            return user


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        email_key = self.username_field
        email = attrs.get(email_key)

        if isinstance(email, str):
            normalized = email.strip()

            # Match user emails case-insensitively so credentials don't fail
            # when users enter different letter casing.
            try:
                user = User.objects.get(email__iexact=normalized)
                attrs[email_key] = user.email
            except User.DoesNotExist:
                attrs[email_key] = normalized

        return super().validate(attrs)

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token["role"] = user.role
        token["full_name"] = user.full_name
        if user.society_id:
            token["society_id"] = str(user.society_id)
        token["can_scan_entry"] = user.can_scan_entry
        token["can_scan_exit"] = user.can_scan_exit
        return token


class GuardCredentialSerializer(serializers.Serializer):
    full_name = serializers.CharField(max_length=150)
    phone = serializers.CharField(max_length=15)
    email = serializers.EmailField(required=False, allow_blank=True)
    can_scan_entry = serializers.BooleanField(default=True)
    can_scan_exit = serializers.BooleanField(default=True)

    def validate(self, attrs):
        request = self.context["request"]
        admin = request.user

        if not admin.is_authenticated or admin.role != User.Role.SOCIETY_ADMIN:
            raise serializers.ValidationError("Only society admins can create guard credentials.")

        if admin.society_id is None:
            raise serializers.ValidationError("Admin must be linked to a society before creating guards.")

        if not attrs.get("can_scan_entry") and not attrs.get("can_scan_exit"):
            raise serializers.ValidationError(
                "Select at least one scan permission for the guard."
            )

        email = attrs.get("email")
        if email:
            if User.objects.filter(email__iexact=email).exists():
                raise serializers.ValidationError({"email": "A user with this email already exists."})
        else:
            attrs["email"] = self._build_email(admin.society_id)

        if User.objects.filter(phone=attrs["phone"]).exists():
            raise serializers.ValidationError({"phone": "A user with this phone number already exists."})

        return attrs

    def _build_email(self, society_id):
        society_prefix = str(society_id).replace("-", "")[:8]
        suffix = secrets.token_hex(2)
        return f"guard-{society_prefix}-{suffix}@parking.local"

    def _build_password(self):
        alphabet = string.ascii_letters + string.digits + "@#$%"
        return "".join(secrets.choice(alphabet) for _ in range(10))

    def create(self, validated_data):
        admin = self.context["request"].user
        password = self._build_password()

        user = User.objects.create_user(
            email=validated_data["email"],
            phone=validated_data["phone"],
            full_name=validated_data["full_name"],
            password=password,
            role=User.Role.GUARD,
            society=admin.society,
            can_scan_entry=validated_data.get("can_scan_entry", True),
            can_scan_exit=validated_data.get("can_scan_exit", True),
        )

        return {
            "user": user,
            "temporary_password": password,
        }


class GuardProfileSerializer(serializers.ModelSerializer):
    society_name = serializers.CharField(source="society.name", read_only=True)

    class Meta:
        model = User
        fields = [
            "id",
            "email",
            "phone",
            "full_name",
            "can_scan_entry",
            "can_scan_exit",
            "society_name",
            "created_at",
        ]


class GuardPermissionUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["can_scan_entry", "can_scan_exit"]

    def validate(self, attrs):
        can_scan_entry = attrs.get("can_scan_entry", self.instance.can_scan_entry)
        can_scan_exit = attrs.get("can_scan_exit", self.instance.can_scan_exit)

        if not can_scan_entry and not can_scan_exit:
            raise serializers.ValidationError(
                "Guard must have at least one scan permission enabled."
            )

        return attrs


class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            "id",
            "email",
            "phone",
            "full_name",
            "role",
            "society",
            "flat_number",
            "floor_number",
            "can_scan_entry",
            "can_scan_exit",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "email",
            "role",
            "society",
            "can_scan_entry",
            "can_scan_exit",
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


class UserNotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserNotification
        fields = [
            "id",
            "notification_type",
            "title",
            "message",
            "payload",
            "is_read",
            "created_at",
        ]
        read_only_fields = fields
