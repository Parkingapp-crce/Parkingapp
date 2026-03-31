from django.contrib.auth.models import User
from rest_framework import serializers
from .models import UserProfile, ParkingLot


class RegisterSerializer(serializers.ModelSerializer):
    name = serializers.CharField(write_only=True)
    password = serializers.CharField(write_only=True, min_length=6)

    class Meta:
        model = User
        fields = ('name', 'email', 'password')

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("Email already registered.")
        return value

    def create(self, validated_data):
        name = validated_data.pop('name')
        email = validated_data['email']
        password = validated_data['password']
        
        user = User.objects.create_user(username=email, email=email, password=password, first_name=name)
        
        UserProfile.objects.update_or_create(
            user=user, 
            defaults={'role': 'customer'}
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
            raise serializers.ValidationError("Email already registered.")
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
            defaults={'role': 'owner'}
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
        fields = ('id', 'name', 'address', 'city', 'total_slots', 'available_slots',
                  'price_per_hour', 'opening_time', 'closing_time', 'is_active', 'owner_name')