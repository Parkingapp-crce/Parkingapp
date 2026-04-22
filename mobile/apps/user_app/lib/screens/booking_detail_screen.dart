import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:core/core.dart';

import '../cubits/bookings_cubit.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late final Razorpay _razorpay;
  BookingDetailCubit? _cubit;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_cubit == null) return;
    final verified = await _cubit!.verifyPayment(
      razorpayOrderId: response.orderId ?? '',
      paymentId: response.paymentId ?? '',
      signature: response.signature ?? '',
    );
    if (verified && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful!'),
          backgroundColor: AppColors.success,
        ),
      );
      _cubit!.loadBooking(widget.bookingId);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment failed: ${response.message ?? "Unknown error"}',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External wallet: ${response.walletName ?? ""}'),
        ),
      );
    }
  }

  void _initiatePayment(BookingDetailCubit cubit, BookingModel booking) async {
    _cubit = cubit;
    final payment = await cubit.initiatePayment(booking.id);
    if (payment == null) return;

    final options = {
      'key': EnvConfig.dev.razorpayKey,
      'amount': (double.tryParse(payment.amount) ?? 0) * 100,
      'order_id': payment.razorpayOrderId,
      'name': 'ParkEase',
      'description': 'Booking #${booking.bookingNumber}',
      'prefill': {},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open payment: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          BookingDetailCubit(GetIt.instance<ApiClient>())
            ..loadBooking(widget.bookingId),
      child: Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: BlocBuilder<BookingDetailCubit, BookingDetailState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const LoadingWidget(message: 'Loading booking...');
            }

            if (state.error != null && state.booking == null) {
              return AppErrorWidget(
                message: state.error!,
                onRetry: () => context.read<BookingDetailCubit>().loadBooking(
                  widget.bookingId,
                ),
              );
            }

            final booking = state.booking;
            if (booking == null) {
              return const EmptyStateWidget(title: 'Booking not found');
            }

            return RefreshIndicator(
              onRefresh: () => context.read<BookingDetailCubit>().loadBooking(
                widget.bookingId,
              ),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatusHeader(booking: booking),
                    const SizedBox(height: 16),
                    _QrSection(
                      booking: booking,
                      qrImageBytes: state.qrImageBytes,
                      isLoadingQr: state.isLoadingQr,
                    ),
                    const SizedBox(height: 16),
                    _BookingInfoCard(booking: booking),
                    const SizedBox(height: 16),
                    _TimeCard(booking: booking),
                    if (booking.vehicle != null) ...[
                      const SizedBox(height: 16),
                      _VehicleCard(vehicle: booking.vehicle!),
                    ],
                    const SizedBox(height: 24),
                    _ActionButtons(
                      booking: booking,
                      state: state,
                      onPay: () => _initiatePayment(
                        context.read<BookingDetailCubit>(),
                        booking,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final BookingModel booking;

  const _StatusHeader({required this.booking});

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.success;
      case 'active':
        return AppColors.primary;
      case 'pending_payment':
        return AppColors.warning;
      case 'completed':
        return AppColors.textSecondary;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending_payment':
        return 'PENDING PAYMENT';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _statusColor(booking.status).withValues(alpha: 0.1),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _statusIcon(booking.status),
              color: _statusColor(booking.status),
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${booking.bookingNumber}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(booking.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _statusLabel(booking.status),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '\u20B9${booking.amount}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle;
      case 'active':
        return Icons.play_circle;
      case 'pending_payment':
        return Icons.payment;
      case 'completed':
        return Icons.task_alt;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}

class _QrSection extends StatelessWidget {
  final BookingModel booking;
  final Uint8List? qrImageBytes;
  final bool isLoadingQr;

  const _QrSection({
    required this.booking,
    required this.qrImageBytes,
    required this.isLoadingQr,
  });

  @override
  Widget build(BuildContext context) {
    final canShowQr = booking.isConfirmed || booking.isActive;
    if (!canShowQr) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Scan at Entry/Exit',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            if (isLoadingQr)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: CircularProgressIndicator(),
              )
            else if (qrImageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  qrImageBytes!,
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              )
            else
              Container(
                width: 220,
                height: 220,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'QR is unavailable right now. Pull to refresh and try again.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              booking.bookingNumber,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This QR is generated by the server and matches the guard scanner validation.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingInfoCard extends StatelessWidget {
  final BookingModel booking;

  const _BookingInfoCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Information',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (booking.societyName != null)
              _DetailTile(
                icon: Icons.apartment,
                label: 'Society',
                value: booking.societyName!,
              ),
            if (booking.slotNumber != null)
              _DetailTile(
                icon: Icons.grid_view,
                label: 'Slot',
                value: booking.slotNumber!,
              ),
          ],
        ),
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  final BookingModel booking;

  const _TimeCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    DateTime? startDt;
    DateTime? endDt;
    DateTime? entryDt;
    DateTime? exitDt;
    try {
      startDt = DateTime.parse(booking.startTime).toLocal();
      endDt = DateTime.parse(booking.endTime).toLocal();
      if (booking.actualEntry != null) {
        entryDt = DateTime.parse(booking.actualEntry!).toLocal();
      }
      if (booking.actualExit != null) {
        exitDt = DateTime.parse(booking.actualExit!).toLocal();
      }
    } catch (_) {}

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (startDt != null)
              _DetailTile(
                icon: Icons.calendar_today,
                label: 'Date',
                value: dateFormat.format(startDt),
              ),
            if (startDt != null)
              _DetailTile(
                icon: Icons.access_time,
                label: 'Start',
                value: timeFormat.format(startDt),
              ),
            if (endDt != null)
              _DetailTile(
                icon: Icons.access_time_filled,
                label: 'End',
                value: timeFormat.format(endDt),
              ),
            if (entryDt != null)
              _DetailTile(
                icon: Icons.login,
                label: 'Actual Entry',
                value:
                    '${dateFormat.format(entryDt)} ${timeFormat.format(entryDt)}',
              ),
            if (exitDt != null)
              _DetailTile(
                icon: Icons.logout,
                label: 'Actual Exit',
                value:
                    '${dateFormat.format(exitDt)} ${timeFormat.format(exitDt)}',
              ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;

  const _VehicleCard({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vehicle',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _DetailTile(
              icon: vehicle.vehicleType == 'bike'
                  ? Icons.two_wheeler
                  : Icons.directions_car,
              label: 'Type',
              value: vehicle.vehicleType.toUpperCase(),
            ),
            _DetailTile(
              icon: Icons.confirmation_number,
              label: 'Registration',
              value: vehicle.registrationNo,
            ),
            if (vehicle.makeModel.isNotEmpty)
              _DetailTile(
                icon: Icons.info_outline,
                label: 'Make/Model',
                value: vehicle.makeModel,
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final BookingModel booking;
  final BookingDetailState state;
  final VoidCallback onPay;

  const _ActionButtons({
    required this.booking,
    required this.state,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final canCancel = booking.isPendingPayment || booking.isConfirmed;
    final canPay = booking.isPendingPayment;

    if (!canCancel && !canPay) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canPay)
          PrimaryButton(
            label: 'Pay Now',
            isLoading: state.isInitiatingPayment,
            onPressed: onPay,
            icon: Icons.payment,
          ),
        if (canPay && canCancel) const SizedBox(height: 12),
        if (canCancel)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: state.isCancelling
                  ? null
                  : () => _showCancelDialog(context),
              icon: state.isCancelling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cancel_outlined),
              label: const Text('Cancel Booking'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('No, Keep'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<BookingDetailCubit>().cancelBooking(booking.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
