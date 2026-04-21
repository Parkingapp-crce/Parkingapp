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

from django.utils.dateparse import parse_datetime
from .models import Booking, QRCode, EntryLog
from .serializers import BookingSerializer, QRCodeSerializer, EntryLogSerializer
from django.utils import timezone

import qrcode
import io
import base64
from django.http import HttpResponse


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


# ─── BOOK SLOT ───
class BookSlotView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        parking_lot_id = request.data.get('parking_lot_id')
        vehicle_number = request.data.get('vehicle_number')
        start_time     = request.data.get('start_time')
        end_time       = request.data.get('end_time')

        if not all([parking_lot_id, vehicle_number, start_time, end_time]):
            return Response({'error': 'parking_lot_id, vehicle_number, start_time, end_time are required.'}, status=400)

        try:
            parking_lot = ParkingLot.objects.get(id=parking_lot_id, is_active=True)
        except ParkingLot.DoesNotExist:
            return Response({'error': 'Parking lot not found.'}, status=404)

        start_dt = parse_datetime(start_time)
        end_dt   = parse_datetime(end_time)

        if not start_dt or not end_dt or start_dt >= end_dt:
            return Response({'error': 'Invalid start_time or end_time.'}, status=400)

        # Check availability
        overlapping = Booking.objects.filter(
            parking_lot=parking_lot,
            status__in=['pending', 'confirmed'],
            start_time__lt=end_dt,
            end_time__gt=start_dt,
        ).count()

        if overlapping >= parking_lot.total_slots:
            return Response({'error': 'No slots available for this time range.'}, status=400)

        # Calculate amount
        duration_hours = (end_dt - start_dt).total_seconds() / 3600
        amount = round(duration_hours * float(parking_lot.price_per_hour), 2)

        # Create booking + QR
        booking = Booking.objects.create(
            customer=request.user,
            parking_lot=parking_lot,
            vehicle_number=vehicle_number,
            start_time=start_dt,
            end_time=end_dt,
            amount=amount,
            status='confirmed',
        )
        qr = QRCode.objects.create(booking=booking, expires_at=end_dt)

        return Response({
            'message' : 'Booking confirmed!',
            'booking' : BookingSerializer(booking).data,
            'qr_code' : QRCodeSerializer(qr).data,
        }, status=201)


# ─── MY BOOKINGS ───
class MyBookingsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        bookings = Booking.objects.filter(customer=request.user).order_by('-created_at')
        return Response(BookingSerializer(bookings, many=True).data)


# ─── BOOKING QR ───
class BookingQRView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, booking_id):
        try:
            booking = Booking.objects.get(id=booking_id, customer=request.user)
            return Response(QRCodeSerializer(booking.qr_code).data)
        except Booking.DoesNotExist:
            return Response({'error': 'Booking not found.'}, status=404)
        except QRCode.DoesNotExist:
            return Response({'error': 'QR not found for this booking.'}, status=404)


# ─── CANCEL BOOKING ───
class CancelBookingView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        booking_id = request.data.get('booking_id')

        try:
            booking = Booking.objects.get(id=booking_id, customer=request.user)
        except Booking.DoesNotExist:
            return Response({'error': 'Booking not found.'}, status=404)

        if booking.status in ['completed', 'cancelled']:
            return Response({'error': f'Cannot cancel a {booking.status} booking.'}, status=400)

        booking.status = 'cancelled'
        booking.save()

        try:
            booking.qr_code.is_used = True
            booking.qr_code.save()
        except QRCode.DoesNotExist:
            pass

        return Response({'message': 'Booking cancelled successfully.'})


# ─── GET QR IMAGE (returns actual QR image) ───
class BookingQRImageView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, booking_id):
        try:
            booking = Booking.objects.get(id=booking_id, customer=request.user)
            qr = booking.qr_code
        except Booking.DoesNotExist:
            return Response({'error': 'Booking not found.'}, status=404)
        except QRCode.DoesNotExist:
            return Response({'error': 'QR not found.'}, status=404)

        # ✅ Check if QR is expired
        now = timezone.now()
        if now > qr.expires_at:
            return Response({
                'error': 'QR code has expired.',
                'expired': True,
            }, status=400)

        # ✅ Check if QR already used
        if qr.is_used:
            return Response({
                'error': 'QR code has already been used.',
                'expired': True,
            }, status=400)

        # ✅ Check if booking cancelled
        if booking.status == 'cancelled':
            return Response({
                'error': 'Booking was cancelled.',
                'expired': True,
            }, status=400)

        # Generate QR image from the UUID code
        qr_image = qrcode.make(str(qr.code))

        # Convert to base64 so Flutter can display it
        buffer = io.BytesIO()
        qr_image.save(buffer, format='PNG')
        buffer.seek(0)
        img_base64 = base64.b64encode(buffer.getvalue()).decode('utf-8')

        return Response({
            'booking_id' : booking.id,
            'qr_code'    : str(qr.code),
            'qr_image'   : img_base64,
            'is_used'    : qr.is_used,
            'expires_at' : qr.expires_at,
        })


# ─── VALIDATE QR (owner or guard scans QR) ───
class ValidateQRView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        # ✅ Allow both owners and guards
        role = get_user_role(request.user)
        if role not in ['owner', 'guard']:
            return Response({'error': 'Access denied. Owners and guards only.'}, status=403)

        code = request.data.get('code')
        if not code:
            return Response({'error': 'QR code is required.'}, status=400)

        try:
            qr = QRCode.objects.select_related('booking__parking_lot').get(code=code)
        except QRCode.DoesNotExist:
            return Response({
                'entry_status' : 'denied',
                'reason'       : 'Invalid QR code.',
            }, status=400)

        booking = qr.booking
        now     = timezone.now()

        # ✅ Get parking lot based on role
        try:
            if role == 'owner':
                owner_lot = request.user.parking_lot
            elif role == 'guard':
                owner_lot = request.user.profile.assigned_lot
        except (ParkingLot.DoesNotExist, AttributeError):
            return Response({'error': 'No parking lot assigned.'}, status=404)

        if booking.parking_lot != owner_lot:
            EntryLog.objects.create(qr_code=qr, scanned_by=request.user, entry_status='denied')
            return Response({
                'entry_status' : 'denied',
                'reason'       : 'This booking is not for your parking lot.',
            }, status=403)

        # Check: already used
        if qr.is_used:
            EntryLog.objects.create(qr_code=qr, scanned_by=request.user, entry_status='denied')
            return Response({
                'entry_status' : 'denied',
                'reason'       : 'QR already used.',
            }, status=400)

        # Check: expired
        if now > qr.expires_at:
            EntryLog.objects.create(qr_code=qr, scanned_by=request.user, entry_status='denied')
            return Response({
                'entry_status' : 'denied',
                'reason'       : 'QR code has expired.',
            }, status=400)

        # Check: booking cancelled
        if booking.status == 'cancelled':
            EntryLog.objects.create(qr_code=qr, scanned_by=request.user, entry_status='denied')
            return Response({
                'entry_status' : 'denied',
                'reason'       : 'Booking was cancelled.',
            }, status=400)

        # ✅ All checks passed — ALLOW entry
        qr.is_used = True
        qr.save()

        booking.status = 'completed'
        booking.save()

        EntryLog.objects.create(qr_code=qr, scanned_by=request.user, entry_status='allowed')

        return Response({
            'entry_status'   : 'allowed',
            'message'        : 'Entry allowed!',
            'vehicle_number' : booking.vehicle_number,
            'customer'       : booking.customer.first_name,
            'parking_lot'    : booking.parking_lot.name,
            'start_time'     : booking.start_time,
            'end_time'       : booking.end_time,
        })


# ─── OWNER ENTRY LOGS ───
class OwnerEntryLogsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if get_user_role(request.user) != 'owner':
            return Response({'error': 'Access denied. Owners only.'}, status=403)

        try:
            owner_lot = request.user.parking_lot
        except ParkingLot.DoesNotExist:
            return Response({'error': 'No parking lot found.'}, status=404)

        logs = EntryLog.objects.filter(
            qr_code__booking__parking_lot=owner_lot
        ).order_by('-scanned_at')

        return Response(EntryLogSerializer(logs, many=True).data)