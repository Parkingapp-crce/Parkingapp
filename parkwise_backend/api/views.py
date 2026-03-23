from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.core.mail import send_mail
from django.core.cache import cache

from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from rest_framework_simplejwt.tokens import RefreshToken

from .serializers import RegisterSerializer, UserProfileSerializer

import random


def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }


# ─────────────────────────────────────────────
# POST /register
# ─────────────────────────────────────────────
class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            tokens = get_tokens_for_user(user)
            return Response({
                'message': 'User registered successfully.',
                'user': {
                    'id': user.id,
                    'name': user.first_name,
                    'email': user.email,
                },
                'tokens': tokens,
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ─────────────────────────────────────────────
# POST /login
# ─────────────────────────────────────────────
class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip()
        password = request.data.get('password', '')

        if not email or not password:
            return Response(
                {'error': 'Email and password are required.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        user = authenticate(request, username=email, password=password)

        if user is None:
            return Response(
                {'error': 'Invalid email or password.'},
                status=status.HTTP_401_UNAUTHORIZED
            )

        tokens = get_tokens_for_user(user)
        return Response({
            'message': 'Login successful.',
            'user': {
                'id': user.id,
                'name': user.first_name,
                'email': user.email,
            },
            'tokens': tokens,
        }, status=status.HTTP_200_OK)


# ─────────────────────────────────────────────
# GET /profile
# ─────────────────────────────────────────────
class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserProfileSerializer(request.user)
        return Response({'user': serializer.data}, status=status.HTTP_200_OK)


# ─────────────────────────────────────────────
# POST /forgot-password
# Body: { email }
# ─────────────────────────────────────────────
class ForgotPasswordView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip()

        if not email:
            return Response(
                {'error': 'Email is required.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check if user exists
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            # Don't reveal if email exists or not (security)
            return Response(
                {'message': 'If this email exists, a reset code has been sent.'},
                status=status.HTTP_200_OK
            )

        # Generate 6-digit OTP
        otp = str(random.randint(100000, 999999))

        # Store OTP in cache for 10 minutes
        cache.set(f'otp_{email}', otp, timeout=600)

        # Send email
        send_mail(
            subject='ParkWise — Password Reset Code',
            message=f'''Hi {user.first_name},

Your password reset code is:

{otp}

This code expires in 10 minutes.

If you did not request this, please ignore this email.

— ParkWise Team''',
            from_email=None,
            recipient_list=[email],
            fail_silently=False,
        )

        return Response(
            {'message': 'If this email exists, a reset code has been sent.'},
            status=status.HTTP_200_OK
        )


# ─────────────────────────────────────────────
# POST /verify-otp
# Body: { email, otp }
# ─────────────────────────────────────────────
class VerifyOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip()
        otp = request.data.get('otp', '').strip()

        if not email or not otp:
            return Response(
                {'error': 'Email and OTP are required.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        cached_otp = cache.get(f'otp_{email}')

        if cached_otp is None:
            return Response(
                {'error': 'OTP expired. Please request a new one.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if cached_otp != otp:
            return Response(
                {'error': 'Invalid OTP. Please try again.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # OTP verified — store verified state for 10 minutes
        cache.set(f'otp_verified_{email}', True, timeout=600)

        return Response(
            {'message': 'OTP verified successfully.'},
            status=status.HTTP_200_OK
        )


# ─────────────────────────────────────────────
# POST /reset-password
# Body: { email, new_password }
# ─────────────────────────────────────────────
class ResetPasswordView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip()
        new_password = request.data.get('new_password', '')

        if not email or not new_password:
            return Response(
                {'error': 'Email and new password are required.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Check OTP was verified
        verified = cache.get(f'otp_verified_{email}')
        if not verified:
            return Response(
                {'error': 'OTP not verified. Please verify OTP first.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        if len(new_password) < 6:
            return Response(
                {'error': 'Password must be at least 6 characters.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            user = User.objects.get(email=email)
            user.set_password(new_password)
            user.save()

            # Clear cache
            cache.delete(f'otp_{email}')
            cache.delete(f'otp_verified_{email}')

            return Response(
                {'message': 'Password reset successfully.'},
                status=status.HTTP_200_OK
            )
        except User.DoesNotExist:
            return Response(
                {'error': 'User not found.'},
                status=status.HTTP_404_NOT_FOUND
            )


# ─────────────────────────────────────────────
# POST /register
# Body: { name, email, password }
# ─────────────────────────────────────────────
class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            tokens = get_tokens_for_user(user)
            return Response({
                'message': 'User registered successfully.',
                'user': {
                    'id': user.id,
                    'name': user.first_name,
                    'email': user.email,
                },
                'tokens': tokens,
            }, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# ─────────────────────────────────────────────
# POST /login
# Body: { email, password }
# ─────────────────────────────────────────────
class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip()
        password = request.data.get('password', '')

        if not email or not password:
            return Response(
                {'error': 'Email and password are required.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Django uses username internally — we store email as username
        user = authenticate(request, username=email, password=password)

        if user is None:
            return Response(
                {'error': 'Invalid email or password.'},
                status=status.HTTP_401_UNAUTHORIZED
            )

        tokens = get_tokens_for_user(user)
        return Response({
            'message': 'Login successful.',
            'user': {
                'id': user.id,
                'name': user.first_name,
                'email': user.email,
            },
            'tokens': tokens,
        }, status=status.HTTP_200_OK)


# ─────────────────────────────────────────────
# GET /profile
# Header: Authorization: Bearer <access_token>
# ─────────────────────────────────────────────
class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserProfileSerializer(request.user)
        return Response({
            'user': serializer.data
        }, status=status.HTTP_200_OK)
