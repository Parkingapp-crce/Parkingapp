import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:core/core.dart';

import '../cubits/bookings_cubit.dart';
import '../widgets/embedded_checkout.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  final String? checkoutSessionId;
  final String? checkoutStatus;
  final bool autoPay;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
    this.checkoutSessionId,
    this.checkoutStatus,
    this.autoPay = false,
  });

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool _handledCheckoutReturn = false;
  bool _hasAutoPaid = false;
  PaymentModel? _activeEmbeddedPayment;
  bool _isCompletingEmbeddedCheckout = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleCheckoutReturn(BookingDetailCubit cubit) async {
    if (_handledCheckoutReturn) {
      return;
    }
    _handledCheckoutReturn = true;

    if (widget.checkoutStatus == 'success' &&
        widget.checkoutSessionId != null) {
      final verified = await cubit.verifyPayment(
        checkoutSessionId: widget.checkoutSessionId!,
      );
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            verified
                ? 'Payment completed successfully.'
                : 'Checkout returned, but payment verification is still pending.',
          ),
          backgroundColor: verified ? AppColors.success : AppColors.warning,
        ),
      );
      await cubit.loadBooking(widget.bookingId);
      return;
    }

    if (widget.checkoutStatus == 'cancelled' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checkout was cancelled.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  Future<void> _initiatePayment(
    BookingDetailCubit cubit,
    BookingModel booking,
  ) async {
    final payment = await cubit.initiatePayment(
      booking.id,
      embedded: supportsEmbeddedCheckout,
    );
    if (payment == null) return;

    if (supportsEmbeddedCheckout) {
      final publishableKey = payment.stripePublishableKey;
      final clientSecret = payment.checkoutClientSecret;
      final sessionId = payment.stripeCheckoutSessionId;

      if (publishableKey == null ||
          publishableKey.isEmpty ||
          clientSecret == null ||
          clientSecret.isEmpty ||
          sessionId == null ||
          sessionId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Embedded checkout configuration is missing.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      cubit.startPolling(booking.id);
      setState(() {
        _activeEmbeddedPayment = payment;
        _isCompletingEmbeddedCheckout = false;
      });
      return;
    }

    final checkoutUrl = payment.checkoutUrl;
    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checkout URL is missing.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    try {
      cubit.startPolling(booking.id);
      final launched = await launchUrl(
        Uri.parse(checkoutUrl),
        mode: LaunchMode.platformDefault,
      );
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Checkout.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open Checkout: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleEmbeddedCheckoutComplete(
    BookingDetailCubit cubit,
    String checkoutSessionId,
  ) async {
    if (_isCompletingEmbeddedCheckout) return;

    setState(() => _isCompletingEmbeddedCheckout = true);
    final verified = await cubit.verifyPayment(
      checkoutSessionId: checkoutSessionId,
    );
    await cubit.loadBooking(widget.bookingId);

    if (!mounted) return;
    setState(() {
      _activeEmbeddedPayment = null;
      _isCompletingEmbeddedCheckout = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          verified
              ? 'Payment completed successfully.'
              : 'Payment completion is syncing. The booking will update shortly.',
        ),
        backgroundColor: verified ? AppColors.success : AppColors.warning,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          BookingDetailCubit(GetIt.instance<ApiClient>())
            ..loadBooking(widget.bookingId),
      child: Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: BlocConsumer<BookingDetailCubit, BookingDetailState>(
          listener: (context, state) {
            final booking = state.booking;
            
            if (widget.autoPay && 
                !_hasAutoPaid && 
                booking != null && 
                booking.isPendingPayment) {
              _hasAutoPaid = true;
              Future.microtask(() {
                _initiatePayment(context.read<BookingDetailCubit>(), booking);
              });
            }

            if (_activeEmbeddedPayment != null &&
                !_isCompletingEmbeddedCheckout &&
                booking != null &&
                !booking.isPendingPayment) {
              setState(() => _activeEmbeddedPayment = null);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment completed successfully.'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
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

            if (!_handledCheckoutReturn && widget.checkoutStatus != null) {
              final detailCubit = context.read<BookingDetailCubit>();
              Future.microtask(() {
                _handleCheckoutReturn(detailCubit);
              });
            }

            return Stack(
              children: [
                RefreshIndicator(
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
                          isCheckoutOpen: _activeEmbeddedPayment != null,
                          onPay: () => _initiatePayment(
                            context.read<BookingDetailCubit>(),
                            booking,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_activeEmbeddedPayment != null)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.6),
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 800),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _EmbeddedCheckoutPanel(
                            payment: _activeEmbeddedPayment!,
                            isCompleting: _isCompletingEmbeddedCheckout,
                            onComplete: (sessionId) =>
                                _handleEmbeddedCheckoutComplete(
                                  context.read<BookingDetailCubit>(),
                                  sessionId,
                                ),
                            onError: (message) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            },
                            onClose: _isCompletingEmbeddedCheckout
                                ? null
                                : () {
                                    setState(() => _activeEmbeddedPayment = null);
                                  },
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
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

  Color _bookingStatusColor(String status) {
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

  Color _paymentStatusColor(String? status) {
    switch (status) {
      case 'captured':
        return AppColors.success;
      case 'failed':
        return AppColors.error;
      case 'refunded':
        return AppColors.textSecondary;
      case 'created':
      case 'unpaid':
      case null:
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _bookingStatusLabel(String status) {
    switch (status) {
      case 'pending_payment':
        return 'BOOKING PENDING';
      default:
        return 'BOOKING ${status.toUpperCase()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentColor = _paymentStatusColor(booking.paymentStatus);
    final bookingColor = _bookingStatusColor(booking.status);

    return Card(
      color: paymentColor.withValues(alpha: 0.1),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _paymentStatusIcon(booking.paymentStatus),
              color: paymentColor,
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeaderChip(
                        label: booking.paymentStatusLabel,
                        color: paymentColor,
                      ),
                      _HeaderChip(
                        label: _bookingStatusLabel(booking.status),
                        color: bookingColor,
                        filled: false,
                      ),
                    ],
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

  IconData _paymentStatusIcon(String? status) {
    switch (status) {
      case 'captured':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      case 'refunded':
        return Icons.replay_circle_filled;
      default:
        return Icons.payment;
    }
  }
}

class _HeaderChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;

  const _HeaderChip({
    required this.label,
    required this.color,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: filled ? Colors.white : color,
        ),
      ),
    );
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
  final bool isCheckoutOpen;
  final VoidCallback? onPay;

  const _ActionButtons({
    required this.booking,
    required this.state,
    required this.isCheckoutOpen,
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
            onPressed: isCheckoutOpen ? null : onPay,
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

class _EmbeddedCheckoutPanel extends StatelessWidget {
  final PaymentModel payment;
  final bool isCompleting;
  final ValueChanged<String> onComplete;
  final ValueChanged<String> onError;
  final VoidCallback? onClose;

  const _EmbeddedCheckoutPanel({
    required this.payment,
    required this.isCompleting,
    required this.onComplete,
    required this.onError,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final sessionId = payment.stripeCheckoutSessionId!;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Secure Checkout',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close checkout',
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (isCompleting) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 12),
            EmbeddedCheckoutView(
              key: ValueKey(sessionId),
              publishableKey: payment.stripePublishableKey!,
              clientSecret: payment.checkoutClientSecret!,
              sessionId: sessionId,
              onComplete: onComplete,
              onError: onError,
            ),
          ],
        ),
      ),
    );
  }
}
