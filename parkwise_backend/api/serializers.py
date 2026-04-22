from django.contrib.auth.models import User
from rest_framework import serializers

from .models import Booking, EntryLog, ParkingLot, QRCode, UserProfile


class RegisterSerializer(serializers.ModelSerializer):
    name = serializers.CharField(write_only=True)
    password = serializers.CharField(write_only=True, min_length=6)

    class Meta:
        model = User
        fields = ('name', 'email', 'password')

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError('Email already registered.')
        return value

    def create(self, validated_data):
        name = validated_data.pop('name')
        email = validated_data['email']
        password = validated_data['password']

        user = User.objects.create_user(
            username=email,
            email=email,
            password=password,
            first_name=name,
        )

        UserProfile.objects.update_or_create(
            user=user,
            defaults={'role': 'customer'},
        )

        return user


class OwnerRegisterSerializer(serializers.Serializer):
    name = serializers.CharField()
    email = serializers.EmailField()
    password = serializers.CharField(min_length=6)
    parking_name = serializers.CharField()
    address = serializers.CharField()
    city = serializers.CharField()
    total_slots = serializers.IntegerField(min_value=1)
    price_per_hour = serializers.DecimalField(max_digits=6, decimal_places=2)
    opening_time = serializers.TimeField()
    closing_time = serializers.TimeField()

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError('Email already registered.')
        return value

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['email'],
            email=validated_data['email'],
            password=validated_data['password'],
            first_name=validated_data['name'],
        )

        UserProfile.objects.update_or_create(
            user=user,
            defaults={'role': 'owner'},
        )

        ParkingLot.objects.create(
            owner=user,
            name=validated_data['parking_name'],
            address=validated_data['address'],
            city=validated_data['city'],
            total_slots=validated_data['total_slots'],
            price_per_hour=validated_data['price_per_hour'],
            opening_time=validated_data['opening_time'],
            closing_time=validated_data['closing_time'],
        )

        return user


class UserProfileSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source='first_name')
    role = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ('id', 'name', 'email', 'role')

    def get_role(self, obj):
        try:
            return obj.profile.role
        except UserProfile.DoesNotExist:
            return 'customer'


class ParkingLotSerializer(serializers.ModelSerializer):
    available_slots = serializers.ReadOnlyField()
    owner_name = serializers.CharField(source='owner.first_name', read_only=True)

    class Meta:
        model = ParkingLot
        fields = (
            'id',
            'name',
            'address',
            'city',
            'total_slots',
            'available_slots',
            'price_per_hour',
            'opening_time',
            'closing_time',
            'is_active',
            'owner_name',
        )


class BookingSerializer(serializers.ModelSerializer):
    customer_name = serializers.CharField(source='customer.username', read_only=True)
    parking_lot_name = serializers.CharField(source='parking_lot.name', read_only=True)
    total_charge = serializers.DecimalField(max_digits=8, decimal_places=2, read_only=True)
    is_overstayed = serializers.BooleanField(read_only=True)
    qr_code_value = serializers.SerializerMethodField()

    class Meta:
        model = Booking
        fields = [
            'id',
            'customer',
            'customer_name',
            'parking_lot',
            'parking_lot_name',
            'vehicle_number',
            'start_time',
            'end_time',
            'amount',
            'penalty_amount',
            'total_charge',
            'status',
            'checked_in_at',
            'checked_out_at',
            'overstay_minutes',
            'is_overstayed',
            'qr_code_value',
            'created_at',
        ]
        read_only_fields = [
            'customer',
            'amount',
            'penalty_amount',
            'total_charge',
            'status',
            'checked_in_at',
            'checked_out_at',
            'overstay_minutes',
            'is_overstayed',
            'qr_code_value',
            'created_at',
        ]

    def get_qr_code_value(self, obj):
        try:
            return str(obj.qr_code.code)
        except QRCode.DoesNotExist:
            return None


class QRCodeSerializer(serializers.ModelSerializer):
    class Meta:
        model = QRCode
        fields = ['id', 'booking', 'code', 'is_used', 'expires_at']
        read_only_fields = ['code', 'is_used', 'expires_at']


class EntryLogSerializer(serializers.ModelSerializer):
    scanned_by_name = serializers.CharField(source='scanned_by.username', read_only=True)

    class Meta:
        model = EntryLog
        fields = ['id', 'qr_code', 'scanned_by', 'scanned_by_name', 'scanned_at', 'entry_status']
        read_only_fields = ['scanned_by', 'scanned_at']
