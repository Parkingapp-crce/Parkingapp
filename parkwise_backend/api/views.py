from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.core.mail import send_mail
from django.core.cache import cache

from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .models import UserProfile, ParkingLot
from .serializers import RegisterSerializer, UserProfileSerializer, OwnerRegisterSerializer, ParkingLotSerializer

import random


def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {'refresh': str(refresh), 'access': str(refresh.access_token)}


def get_user_role(user):
    try:
        return user.profile.role
    except UserProfile.DoesNotExist:
        return 'customer'


# ─── CUSTOMER REGISTER ───
class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            tokens = get_tokens_for_user(user)
            return Response({
                'message': 'User registered successfully.',
                'user': {'id': user.id, 'name': user.first_name, 'email': user.email, 'role': 'customer'},
                'tokens': tokens,
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ─── OWNER REGISTER ───
class OwnerRegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = OwnerRegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            tokens = get_tokens_for_user(user)
            return Response({
                'message': 'Owner registered successfully.',
                'user': {'id': user.id, 'name': user.first_name, 'email': user.email, 'role': 'owner'},
                'tokens': tokens,
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ─── LOGIN (all roles) ───
class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip()
        password = request.data.get('password', '')

        if not email or not password:
            return Response({'error': 'Email and password are required.'}, status=status.HTTP_400_BAD_REQUEST)

        user = authenticate(request, username=email, password=password)

        if user is None:
            return Response({'error': 'Invalid email or password.'}, status=status.HTTP_401_UNAUTHORIZED)

        role = get_user_role(user)
        tokens = get_tokens_for_user(user)

        return Response({
            'message': 'Login successful.',
            'user': {'id': user.id, 'name': user.first_name, 'email': user.email, 'role': role},
            'tokens': tokens,
        }, status=status.HTTP_200_OK)


# ─── PROFILE ───
class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserProfileSerializer(request.user)
        return Response({'user': serializer.data}, status=status.HTTP_200_OK)


# ─── OWNER DASHBOARD ───
class OwnerDashboardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if get_user_role(request.user) != 'owner':
            return Response({'error': 'Access denied. Owners only.'}, status=status.HTTP_403_FORBIDDEN)
        try:
            lot = request.user.parking_lot
            serializer = ParkingLotSerializer(lot)
            return Response({'parking_lot': serializer.data}, status=status.HTTP_200_OK)
        except ParkingLot.DoesNotExist:
            return Response({'error': 'No parking lot found.'}, status=status.HTTP_404_NOT_FOUND)


# ─── ADMIN DASHBOARD ───
class AdminDashboardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if get_user_role(request.user) != 'admin':
            return Response({'error': 'Access denied. Admins only.'}, status=status.HTTP_403_FORBIDDEN)

        total_users = User.objects.count()
        total_owners = UserProfile.objects.filter(role='owner').count()
        total_customers = UserProfile.objects.filter(role='customer').count()
        total_lots = ParkingLot.objects.count()
        lots = ParkingLotSerializer(ParkingLot.objects.all(), many=True).data

        return Response({
            'stats': {
                'total_users': total_users,
                'total_owners': total_owners,
                'total_customers': total_customers,
                'total_lots': total_lots,
            },
            'parking_lots': lots,
        }, status=status.HTTP_200_OK)


# ─── ALL PARKING LOTS (for customers) ───
class ParkingLotsView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        lots = ParkingLot.objects.filter(is_active=True)
        serializer = ParkingLotSerializer(lots, many=True)
        return Response({'parking_lots': serializer.data}, status=status.HTTP_200_OK)


# ─── FORGOT PASSWORD ───
class ForgotPasswordView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip()
        if not email:
            return Response({'error': 'Email is required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({'message': 'If this email exists, a reset code has been sent.'}, status=status.HTTP_200_OK)

        otp = str(random.randint(100000, 999999))
        cache.set(f'otp_{email}', otp, timeout=600)

        send_mail(
            subject='ParkWise — Password Reset Code',
            message=f'Hi {user.first_name},\n\nYour password reset code is:\n\n{otp}\n\nThis code expires in 10 minutes.\n\n— ParkWise Team',
            from_email=None,
            recipient_list=[email],
            fail_silently=False,
        )
        return Response({'message': 'If this email exists, a reset code has been sent.'}, status=status.HTTP_200_OK)


# ─── VERIFY OTP ───
class VerifyOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip()
        otp = request.data.get('otp', '').strip()

        if not email or not otp:
            return Response({'error': 'Email and OTP are required.'}, status=status.HTTP_400_BAD_REQUEST)

        cached_otp = cache.get(f'otp_{email}')
        if cached_otp is None:
            return Response({'error': 'OTP expired. Please request a new one.'}, status=status.HTTP_400_BAD_REQUEST)
        if cached_otp != otp:
            return Response({'error': 'Invalid OTP. Please try again.'}, status=status.HTTP_400_BAD_REQUEST)

        cache.set(f'otp_verified_{email}', True, timeout=600)
        return Response({'message': 'OTP verified successfully.'}, status=status.HTTP_200_OK)


# ─── RESET PASSWORD ───
class ResetPasswordView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip()
        new_password = request.data.get('new_password', '')

        if not email or not new_password:
            return Response({'error': 'Email and new password are required.'}, status=status.HTTP_400_BAD_REQUEST)

        verified = cache.get(f'otp_verified_{email}')
        if not verified:
            return Response({'error': 'OTP not verified. Please verify OTP first.'}, status=status.HTTP_400_BAD_REQUEST)

        if len(new_password) < 6:
            return Response({'error': 'Password must be at least 6 characters.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            user = User.objects.get(email=email)
            user.set_password(new_password)
            user.save()
            cache.delete(f'otp_{email}')
            cache.delete(f'otp_verified_{email}')
            return Response({'message': 'Password reset successfully.'}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({'error': 'User not found.'}, status=status.HTTP_404_NOT_FOUND)
