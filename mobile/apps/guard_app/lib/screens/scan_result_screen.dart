import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScanResultScreen extends StatelessWidget {
  final bool isSuccess;
  final Map<String, dynamic>? data;
  final String? errorMessage;
  final bool isEntry;

  const ScanResultScreen({
    super.key,
    required this.isSuccess,
    this.data,
    this.errorMessage,
    required this.isEntry,
  });

  @override
  Widget build(BuildContext context) {
    final scanType = isEntry ? 'Entry' : 'Exit';

    return Scaffold(
      appBar: AppBar(
        title: Text('$scanType Result'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              // Status icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: (isSuccess ? AppColors.success : AppColors.error)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle : Icons.cancel,
                  size: 96,
                  color: isSuccess ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(height: 24),

              // Status text
              Text(
                isSuccess ? '$scanType Approved' : '$scanType Denied',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(height: 32),

              // Details
              if (isSuccess && data != null)
                _SuccessDetails(data: data!, isEntry: isEntry),

              if (!isSuccess && errorMessage != null)
                _ErrorDetails(message: errorMessage!),

              const Spacer(),

              // Scan another button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.qr_code_scanner, size: 24),
                  label: const Text(
                    'Scan Another',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Go home button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => context.go('/home'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessDetails extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isEntry;

  const _SuccessDetails({required this.data, required this.isEntry});

  @override
  Widget build(BuildContext context) {
    final bookingNumber = data['booking_number']?.toString() ?? '-';
    final vehicleNumber = data['vehicle_number']?.toString() ?? '-';
    final slotLabel = data['slot_number']?.toString() ?? '-';
    final ownerName = data['owner_name']?.toString() ?? '-';
    final ownerPhone = data['owner_phone']?.toString() ?? '-';
    final ownerEmail = data['owner_email']?.toString() ?? '-';
    final paymentStatus = data['payment_status']?.toString() ?? '-';
    final entryTime = data['entry_time']?.toString();
    final exitTime = data['exit_time']?.toString();
    final processedAt = data['processed_at']?.toString() ?? '-';
    final penaltyMap = data['penalty'] as Map<String, dynamic>?;
    final penaltyAmount = penaltyMap?['amount']?.toString();
    final hasPenalty = penaltyAmount != null && penaltyAmount != '0';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          _DetailRow(label: 'Booking', value: bookingNumber),
          const Divider(height: 24),
          _DetailRow(label: 'Vehicle', value: vehicleNumber),
          const Divider(height: 24),
          _DetailRow(label: 'Owner', value: ownerName),
          const Divider(height: 24),
          _DetailRow(label: 'Phone', value: ownerPhone),
          const Divider(height: 24),
          _DetailRow(label: 'Email', value: ownerEmail),
          const Divider(height: 24),
          _DetailRow(label: 'Slot', value: slotLabel),
          const Divider(height: 24),
          _DetailRow(
            label: 'Payment',
            value: paymentStatus.replaceAll('_', ' '),
          ),
          const Divider(height: 24),
          _DetailRow(
            label: isEntry ? 'Entry Time' : 'Exit Time',
            value: (isEntry ? entryTime : exitTime) ?? processedAt,
          ),
          if (!isEntry && entryTime != null) ...[
            const Divider(height: 24),
            _DetailRow(label: 'Recorded Entry', value: entryTime),
          ],
          if (hasPenalty && !isEntry) ...[
            const Divider(height: 24),
            _DetailRow(
              label: 'Overstay Penalty',
              value: 'Rs. $penaltyAmount',
              valueColor: AppColors.error,
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorDetails extends StatelessWidget {
  final String message;

  const _ErrorDetails({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, color: AppColors.error, size: 28),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
