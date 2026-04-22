import base64
import io
import math
import random
from decimal import Decimal, ROUND_HALF_UP

import qrcode
from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.core.cache import cache
from django.core.mail import send_mail
from django.utils import timezone
from django.utils.dateparse import parse_datetime
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .models import Booking, EntryLog, ParkingLot, QRCode, UserProfile
from .serializers import (
    BookingSerializer,
    EntryLogSerializer,
    OwnerRegisterSerializer,
    ParkingLotSerializer,
    QRCodeSerializer,
    RegisterSerializer,
    UserProfileSerializer,
)


MONEY_STEP = Decimal('0.01')


def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {'refresh': str(refresh), 'access': str(refresh.access_token)}


def get_user_role(user):
    try:
        return user.profile.role
    except UserProfile.DoesNotExist:
        return 'customer'


def quantize_money(value):
    return Decimal(value).quantize(MONEY_STEP, rounding=ROUND_HALF_UP)


def decimal_to_float(value):
    return float(quantize_money(value))


def calculate_booking_amount(parking_lot, start_dt, end_dt):
    duration_hours = Decimal(str((end_dt - start_dt).total_seconds() / 3600))
    return quantize_money(parking_lot.price_per_hour * duration_hours)


def calculate_overstay_penalty(booking, checkout_at):
    if checkout_at <= booking.end_time:
        return 0, Decimal('0.00')

    extra_seconds = (checkout_at - booking.end_time).total_seconds()
    overstay_minutes = max(1, math.ceil(extra_seconds / 60))
    extra_hours = Decimal((overstay_minutes + 59) // 60)
    penalty_amount = quantize_money(booking.parking_lot.price_per_hour * extra_hours)
    return overstay_minutes, penalty_amount


def sum_booking_total(bookings):
    total = Decimal('0.00')
    for booking in bookings:
        total += booking.total_charge
    return quantize_money(total)


def build_lot_summaries(bookings, lots, month_start, now):
    bookings_by_lot = {}
    for booking in bookings:
        bookings_by_lot.setdefault(booking.parking_lot_id, []).append(booking)

    lot_summaries = []
    for lot in lots:
        lot_bookings = bookings_by_lot.get(lot.id, [])
        monthly_bookings = [
            booking for booking in lot_bookings if booking.created_at >= month_start
        ]
        active_sessions = [
            booking for booking in lot_bookings if booking.status == 'active'
        ]
        overstay_alerts = [
            booking for booking in active_sessions if booking.end_time < now
        ]

        summary = ParkingLotSerializer(lot).data
        summary.update({
            'total_earnings': decimal_to_float(sum_booking_total(lot_bookings)),
            'monthly_earnings': decimal_to_float(sum_booking_total(monthly_bookings)),
            'active_sessions': len(active_sessions),
            'overstay_alerts': len(overstay_alerts),
        })
        lot_summaries.append(summary)

    return lot_summaries


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
                    'role': 'customer',
                },
                'tokens': tokens,
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class OwnerRegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = OwnerRegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
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
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip()
        password = request.data.get('password', '')

        if not email or not password:
            return Response(
                {'error': 'Email and password are required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = authenticate(request, username=email, password=password)
        if user is None:
            return Response(
                {'error': 'Invalid email or password.'},
                status=status.HTTP_401_UNAUTHORIZED,
            )

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
        }, status=status.HTTP_200_OK)


class ProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserProfileSerializer(request.user)
        return Response({'user': serializer.data}, status=status.HTTP_200_OK)


class OwnerDashboardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if get_user_role(request.user) != 'owner':
            return Response(
                {'error': 'Access denied. Owners only.'},
                status=status.HTTP_403_FORBIDDEN,
            )
        try:
            lot = request.user.parking_lot
            serializer = ParkingLotSerializer(lot)
            return Response({'parking_lot': serializer.data}, status=status.HTTP_200_OK)
        except ParkingLot.DoesNotExist:
            return Response(
                {'error': 'No parking lot found.'},
                status=status.HTTP_404_NOT_FOUND,
            )


class AdminDashboardView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if get_user_role(request.user) != 'admin':
            return Response(
                {'error': 'Access denied. Admins only.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        now = timezone.now()
        local_now = timezone.localtime(now)
        month_start = local_now.replace(
            day=1,
            hour=0,
            minute=0,
            second=0,
            microsecond=0,
        )

        lots = list(ParkingLot.objects.select_related('owner').all())
        bookings = list(
            Booking.objects.select_related('parking_lot', 'customer')
            .exclude(status='cancelled')
            .order_by('-created_at')
        )
        monthly_bookings = [booking for booking in bookings if booking.created_at >= month_start]
        active_bookings = [booking for booking in bookings if booking.status == 'active']
        completed_bookings = [booking for booking in bookings if booking.status == 'completed']
        overstay_alerts = [booking for booking in active_bookings if booking.end_time < now]

        return Response({
            'stats': {
                'total_users': User.objects.count(),
                'total_owners': UserProfile.objects.filter(role='owner').count(),
                'total_customers': UserProfile.objects.filter(role='customer').count(),
                'total_lots': len(lots),
                'total_bookings': len(bookings),
                'active_sessions': len(active_bookings),
                'completed_bookings': len(completed_bookings),
                'overstay_alerts': len(overstay_alerts),
                'total_earnings': decimal_to_float(sum_booking_total(bookings)),
                'monthly_earnings': decimal_to_float(sum_booking_total(monthly_bookings)),
                'penalties_collected': decimal_to_float(
                    sum((booking.penalty_amount for booking in bookings), Decimal('0.00'))
                ),
                'monthly_penalties': decimal_to_float(
                    sum((booking.penalty_amount for booking in monthly_bookings), Decimal('0.00'))
                ),
            },
            'penalty_policy': {
                'enabled': True,
                'rule': 'Overstay is charged at one extra hourly rate for every started extra hour.',
                'exit_scan_required': True,
            },
            'parking_lots': build_lot_summaries(bookings, lots, month_start, now),
        }, status=status.HTTP_200_OK)


class ParkingLotsView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        lots = ParkingLot.objects.filter(is_active=True)
        serializer = ParkingLotSerializer(lots, many=True)
        return Response({'parking_lots': serializer.data}, status=status.HTTP_200_OK)


class ForgotPasswordView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip()
        if not email:
            return Response(
                {'error': 'Email is required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response(
                {'message': 'If this email exists, a reset code has been sent.'},
                status=status.HTTP_200_OK,
            )

        otp = str(random.randint(100000, 999999))
        cache.set(f'otp_{email}', otp, timeout=600)

        send_mail(
            subject='ParkWise - Password Reset Code',
            message=(
                f'Hi {user.first_name},\n\n'
                f'Your password reset code is:\n\n{otp}\n\n'
                'This code expires in 10 minutes.\n\n'
                '- ParkWise Team'
            ),
            from_email=None,
            recipient_list=[email],
            fail_silently=False,
        )
        return Response(
            {'message': 'If this email exists, a reset code has been sent.'},
            status=status.HTTP_200_OK,
        )


class VerifyOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip()
        otp = request.data.get('otp', '').strip()

        if not email or not otp:
            return Response(
                {'error': 'Email and OTP are required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        cached_otp = cache.get(f'otp_{email}')
        if cached_otp is None:
            return Response(
                {'error': 'OTP expired. Please request a new one.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if cached_otp != otp:
            return Response(
                {'error': 'Invalid OTP. Please try again.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        cache.set(f'otp_verified_{email}', True, timeout=600)
        return Response({'message': 'OTP verified successfully.'}, status=status.HTTP_200_OK)


class ResetPasswordView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip()
        new_password = request.data.get('new_password', '')

        if not email or not new_password:
            return Response(
                {'error': 'Email and new password are required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        verified = cache.get(f'otp_verified_{email}')
        if not verified:
            return Response(
                {'error': 'OTP not verified. Please verify OTP first.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if len(new_password) < 6:
            return Response(
                {'error': 'Password must be at least 6 characters.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            user = User.objects.get(email=email)
            user.set_password(new_password)
            user.save()
            cache.delete(f'otp_{email}')
            cache.delete(f'otp_verified_{email}')
            return Response(
                {'message': 'Password reset successfully.'},
                status=status.HTTP_200_OK,
            )
        except User.DoesNotExist:
            return Response(
                {'error': 'User not found.'},
                status=status.HTTP_404_NOT_FOUND,
            )


class BookSlotView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        parking_lot_id = request.data.get('parking_lot_id')
        vehicle_number = request.data.get('vehicle_number')
        start_time = request.data.get('start_time')
        end_time = request.data.get('end_time')

        if not all([parking_lot_id, vehicle_number, start_time, end_time]):
            return Response(
                {'error': 'parking_lot_id, vehicle_number, start_time, end_time are required.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            parking_lot = ParkingLot.objects.get(id=parking_lot_id, is_active=True)
        except ParkingLot.DoesNotExist:
            return Response({'error': 'Parking lot not found.'}, status=status.HTTP_404_NOT_FOUND)

        start_dt = parse_datetime(start_time)
        end_dt = parse_datetime(end_time)

        if not start_dt or not end_dt or start_dt >= end_dt:
            return Response(
                {'error': 'Invalid start_time or end_time.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        overlapping = Booking.objects.filter(
            parking_lot=parking_lot,
            status__in=['pending', 'confirmed', 'active'],
            start_time__lt=end_dt,
            end_time__gt=start_dt,
        ).count()

        if overlapping >= parking_lot.total_slots:
            return Response(
                {'error': 'No slots available for this time range.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        amount = calculate_booking_amount(parking_lot, start_dt, end_dt)

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
            'message': 'Booking confirmed!',
            'booking': BookingSerializer(booking).data,
            'qr_code': QRCodeSerializer(qr).data,
        }, status=status.HTTP_201_CREATED)


class MyBookingsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        bookings = Booking.objects.filter(customer=request.user).order_by('-created_at')
        return Response(BookingSerializer(bookings, many=True).data)


class BookingQRView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, booking_id):
        try:
            booking = Booking.objects.get(id=booking_id, customer=request.user)
            return Response(QRCodeSerializer(booking.qr_code).data)
        except Booking.DoesNotExist:
            return Response({'error': 'Booking not found.'}, status=status.HTTP_404_NOT_FOUND)
        except QRCode.DoesNotExist:
            return Response({'error': 'QR not found for this booking.'}, status=status.HTTP_404_NOT_FOUND)


class CancelBookingView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        booking_id = request.data.get('booking_id')

        try:
            booking = Booking.objects.get(id=booking_id, customer=request.user)
        except Booking.DoesNotExist:
            return Response({'error': 'Booking not found.'}, status=status.HTTP_404_NOT_FOUND)

        if booking.status in ['active', 'completed', 'cancelled']:
            return Response(
                {'error': f'Cannot cancel a {booking.status} booking.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        booking.status = 'cancelled'
        booking.save(update_fields=['status'])

        try:
            booking.qr_code.is_used = True
            booking.qr_code.save(update_fields=['is_used'])
        except QRCode.DoesNotExist:
            pass

        return Response({'message': 'Booking cancelled successfully.'})


class BookingQRImageView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, booking_id):
        try:
            booking = Booking.objects.get(id=booking_id, customer=request.user)
            qr = booking.qr_code
        except Booking.DoesNotExist:
            return Response({'error': 'Booking not found.'}, status=status.HTTP_404_NOT_FOUND)
        except QRCode.DoesNotExist:
            return Response({'error': 'QR not found.'}, status=status.HTTP_404_NOT_FOUND)

        now = timezone.now()

        if booking.status == 'cancelled':
            return Response({
                'error': 'Booking was cancelled.',
                'expired': True,
            }, status=status.HTTP_400_BAD_REQUEST)

        if booking.status == 'completed' or (qr.is_used and booking.status != 'active'):
            return Response({
                'error': 'QR code has already been used.',
                'expired': True,
            }, status=status.HTTP_400_BAD_REQUEST)

        if booking.status == 'confirmed' and now > qr.expires_at:
            return Response({
                'error': 'QR code has expired.',
                'expired': True,
            }, status=status.HTTP_400_BAD_REQUEST)

        qr_image = qrcode.make(str(qr.code))
        buffer = io.BytesIO()
        qr_image.save(buffer, format='PNG')
        buffer.seek(0)
        img_base64 = base64.b64encode(buffer.getvalue()).decode('utf-8')

        return Response({
            'booking_id': booking.id,
            'qr_code': str(qr.code),
            'qr_image': img_base64,
            'is_used': qr.is_used,
            'expires_at': qr.expires_at,
            'status': booking.status,
            'checked_in_at': booking.checked_in_at,
            'checked_out_at': booking.checked_out_at,
        })


class ValidateQRView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        role = get_user_role(request.user)
        if role not in ['owner', 'guard']:
            return Response(
                {'error': 'Access denied. Owners and guards only.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        code = request.data.get('code')
        if not code:
            return Response({'error': 'QR code is required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            qr = QRCode.objects.select_related('booking__parking_lot', 'booking__customer').get(code=code)
        except QRCode.DoesNotExist:
            return Response({
                'entry_status': 'denied',
                'reason': 'Invalid QR code.',
            }, status=status.HTTP_400_BAD_REQUEST)

        booking = qr.booking
        now = timezone.now()

        try:
            if role == 'owner':
                owner_lot = request.user.parking_lot
            else:
                owner_lot = request.user.profile.assigned_lot
        except (ParkingLot.DoesNotExist, AttributeError):
            return Response({'error': 'No parking lot assigned.'}, status=status.HTTP_404_NOT_FOUND)

        if booking.parking_lot != owner_lot:
            EntryLog.objects.create(qr_code=qr, scanned_by=request.user, entry_status='denied')
            return Response({
                'entry_status': 'denied',
                'reason': 'This booking is not for your parking lot.',
            }, status=status.HTTP_403_FORBIDDEN)

        if booking.status == 'cancelled':
            EntryLog.objects.create(qr_code=qr, scanned_by=request.user, entry_status='denied')
            return Response({
                'entry_status': 'denied',
                'reason': 'Booking was cancelled.',
            }, status=status.HTTP_400_BAD_REQUEST)

        if booking.status == 'completed':
            EntryLog.objects.create(qr_code=qr, scanned_by=request.user, entry_status='denied')
            return Response({
                'entry_status': 'denied',
                'reason': 'Vehicle has already checked out.',
            }, status=status.HTTP_400_BAD_REQUEST)

        if booking.status == 'confirmed':
            if now > qr.expires_at:
                EntryLog.objects.create(qr_code=qr, scanned_by=request.user, entry_status='denied')
                return Response({
                    'entry_status': 'denied',
                    'reason': 'Booking window has expired.',
                }, status=status.HTTP_400_BAD_REQUEST)

            booking.status = 'active'
            booking.checked_in_at = now
            booking.save(update_fields=['status', 'checked_in_at'])

            EntryLog.objects.create(qr_code=qr, scanned_by=request.user, entry_status='allowed')
            return Response({
                'entry_status': 'allowed',
                'scan_action': 'entry',
                'message': 'Entry allowed. Scan the same QR again during exit.',
                'vehicle_number': booking.vehicle_number,
                'customer': booking.customer.first_name,
                'parking_lot': booking.parking_lot.name,
                'start_time': booking.start_time,
                'end_time': booking.end_time,
                'overstay_minutes': 0,
                'penalty_amount': 0,
                'total_amount': decimal_to_float(booking.total_charge),
            })

        if booking.status == 'active':
            overstay_minutes, penalty_amount = calculate_overstay_penalty(booking, now)
            booking.checked_out_at = now
            booking.overstay_minutes = overstay_minutes
            booking.penalty_amount = penalty_amount
            booking.status = 'completed'
            booking.save(update_fields=[
                'checked_out_at',
                'overstay_minutes',
                'penalty_amount',
                'status',
            ])

            qr.is_used = True
            qr.save(update_fields=['is_used'])

            EntryLog.objects.create(qr_code=qr, scanned_by=request.user, entry_status='allowed')

            penalty_note = ''
            if overstay_minutes > 0:
                penalty_note = f' Overstay penalty applied: Rs {decimal_to_float(penalty_amount):.2f}.'

            return Response({
                'entry_status': 'allowed',
                'scan_action': 'exit',
                'message': f'Exit recorded successfully.{penalty_note}'.strip(),
                'vehicle_number': booking.vehicle_number,
                'customer': booking.customer.first_name,
                'parking_lot': booking.parking_lot.name,
                'start_time': booking.start_time,
                'end_time': booking.end_time,
                'checked_out_at': booking.checked_out_at,
                'overstay_minutes': booking.overstay_minutes,
                'penalty_amount': decimal_to_float(booking.penalty_amount),
                'total_amount': decimal_to_float(booking.total_charge),
            })

        EntryLog.objects.create(qr_code=qr, scanned_by=request.user, entry_status='denied')
        return Response({
            'entry_status': 'denied',
            'reason': f'Booking is in {booking.status} state and cannot be scanned.',
        }, status=status.HTTP_400_BAD_REQUEST)


class OwnerEntryLogsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if get_user_role(request.user) != 'owner':
            return Response(
                {'error': 'Access denied. Owners only.'},
                status=status.HTTP_403_FORBIDDEN,
            )

        try:
            owner_lot = request.user.parking_lot
        except ParkingLot.DoesNotExist:
            return Response({'error': 'No parking lot found.'}, status=status.HTTP_404_NOT_FOUND)

        logs = EntryLog.objects.filter(
            qr_code__booking__parking_lot=owner_lot
        ).order_by('-scanned_at')

        return Response(EntryLogSerializer(logs, many=True).data)
