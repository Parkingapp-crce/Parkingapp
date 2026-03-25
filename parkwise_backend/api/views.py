import random
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from django.core.cache import cache
from django.core.mail import send_mail
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework_simplejwt.tokens import RefreshToken
from .serializers import RegisterSerializer, OwnerRegisterSerializer
from .models import UserProfile, ParkingLot

# ─────────────────────────────────────────────────────────────
# HELPER — Generate JWT tokens
# ─────────────────────────────────────────────────────────────
def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }

def get_user_role(user):
    try:
        return user.profile.role
    except UserProfile.DoesNotExist:
        return 'customer'

# ─────────────────────────────────────────────────────────────
# REGISTER — Customer
# ─────────────────────────────────────────────────────────────
class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            # Create customer profile
            UserProfile.objects.get_or_create(user=user, defaults={'role': 'customer'})
            tokens = get_tokens_for_user(user)
            return Response({
                'message': 'User registered successfully.',
                'user': {
                    'id': user.id,
                    'name': user.first_name,
                    'email': user.email,
                    'role': 'customer',
                },
                'tokens': tokens,
            }, status=201)
        return Response(serializer.errors, status=400)


# ─────────────────────────────────────────────────────────────
# REGISTER — Owner
# ─────────────────────────────────────────────────────────────
class OwnerRegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = OwnerRegisterSerializer(data=request.data)
        if serializer.is_valid():
            data = serializer.validated_data

            # Create user
            user = User.objects.create_user(
                username=data['email'],
                email=data['email'],
                password=data['password'],
                first_name=data['name'],
            )

            # Create owner profile
            UserProfile.objects.create(user=user, role='owner')

            # Create parking lot
            ParkingLot.objects.create(
                owner=user,
                name=data['lot_name'],
                address=data['address'],
                city=data['city'],
                total_slots=data['total_slots'],
                price_per_hour=data['price_per_hour'],
                opening_time=data['opening_time'],
                closing_time=data['closing_time'],
            )

            tokens = get_tokens_for_user(user)
            return Response({
                'message': 'Owner registered successfully.',
                'user': {
                    'id': user.id,
                    'name': user.first_name,
                    'email': user.email,
                    'role': 'owner',
                },
                'tokens': tokens,
            }, status=201)
        return Response(serializer.errors, status=400)


# ─────────────────────────────────────────────────────────────
# LOGIN — All roles
# ─────────────────────────────────────────────────────────────
class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email')
        password = request.data.get('password')

        if not email or not password:
            return Response({'error': 'Email and password required'}, status=400)

        user = authenticate(username=email, password=password)
        if user is None:
            # Try with email field
            try:
                u = User.objects.get(email=email)
                user = authenticate(username=u.username, password=password)
            except User.DoesNotExist:
                pass

        if user is None:
            return Response({'error': 'Invalid email or password'}, status=401)

        role = get_user_role(user)
        tokens = get_tokens_for_user(user)

        return Response({
            'message': 'Login successful.',
            'user': {
                'id': user.id,
                'name': user.first_name,
                'email': user.email,
                'role': role,
            },
            'tokens': tokens,
        })


# ─────────────────────────────────────────────────────────────
# PROFILE
# ─────────────────────────────────────────────────────────────
class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        role = get_user_role(user)
        return Response({
            'user': {
                'id': user.id,
                'name': user.first_name,
                'email': user.email,
                'role': role,
            }
        })


# ─────────────────────────────────────────────────────────────
# GOOGLE LOGIN
# ─────────────────────────────────────────────────────────────
class GoogleLoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email')
        name = request.data.get('name', '')

        if not email:
            return Response({'error': 'Email required'}, status=400)

        user, created = User.objects.get_or_create(
            username=email,
            defaults={'email': email, 'first_name': name}
        )
        if created:
            user.set_unusable_password()
            user.save()
            UserProfile.objects.create(user=user, role='customer')

        role = get_user_role(user)
        tokens = get_tokens_for_user(user)

        return Response({
            'message': 'Google login successful.',
            'user': {
                'id': user.id,
                'name': user.first_name,
                'email': user.email,
                'role': role,
            },
            'tokens': tokens,
        })


# ─────────────────────────────────────────────────────────────
# FORGOT PASSWORD
# ─────────────────────────────────────────────────────────────
class ForgotPasswordView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email')
        if not email:
            return Response({'error': 'Email required'}, status=400)

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({'message': 'If this email exists, a reset code has been sent.'})

        otp = str(random.randint(100000, 999999))
        cache.set(f'otp_{email}', otp, timeout=600)

        try:
            send_mail(
                subject='ParkWise — Password Reset Code',
                message=f'Your ParkWise password reset code is: {otp}\n\nThis code expires in 10 minutes.',
                from_email=None,
                recipient_list=[email],
                fail_silently=False,
            )
        except Exception as e:
            return Response({'error': f'Failed to send email: {str(e)}'}, status=500)

        return Response({'message': 'If this email exists, a reset code has been sent.'})


# ─────────────────────────────────────────────────────────────
# VERIFY OTP
# ─────────────────────────────────────────────────────────────
class VerifyOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email')
        otp = request.data.get('otp')

        if not email or not otp:
            return Response({'error': 'Email and OTP required'}, status=400)

        cached_otp = cache.get(f'otp_{email}')
        if not cached_otp:
            return Response({'error': 'OTP expired or invalid'}, status=400)

        if str(cached_otp) != str(otp):
            return Response({'error': 'Incorrect OTP'}, status=400)

        cache.set(f'otp_verified_{email}', True, timeout=600)
        return Response({'message': 'OTP verified successfully.'})


# ─────────────────────────────────────────────────────────────
# RESET PASSWORD
# ─────────────────────────────────────────────────────────────
class ResetPasswordView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email')
        new_password = request.data.get('new_password')

        if not email or not new_password:
            return Response({'error': 'Email and new password required'}, status=400)

        verified = cache.get(f'otp_verified_{email}')
        if not verified:
            return Response({'error': 'OTP not verified'}, status=400)

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=404)

        user.set_password(new_password)
        user.save()

        cache.delete(f'otp_{email}')
        cache.delete(f'otp_verified_{email}')

        return Response({'message': 'Password reset successfully.'})
