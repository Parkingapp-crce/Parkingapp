import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'my_bookings_page.dart';

class QRCodePage extends StatelessWidget {
  final Map<String, dynamic> booking;
  final Map<String, dynamic> qrCode;

  const QRCodePage({super.key, required this.booking, required this.qrCode});

  final Color primaryGreen = const Color(0xFF1E7E34);
  final Color textDark = const Color(0xFF0D1B0F);
  final Color textGrey = const Color(0xFF6B7280);

  String formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return iso;
    }
  }

  String formatMoney(dynamic value) {
    final amount = double.tryParse('$value') ?? 0;
    return '₹${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';
  }

  @override
  Widget build(BuildContext context) {
    final code = qrCode['code']?.toString() ?? '';
    final status = booking['status']?.toString().toUpperCase() ?? '-';
    final isActive = booking['status'] == 'active';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Your QR Code',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MyBookingsPage()),
            ),
            child: Text(
              'My Bookings',
              style: TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code_rounded, color: primaryGreen, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isActive ? 'Use This For Exit' : 'Booking Confirmed',
                          style: TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          isActive
                              ? 'Show the same QR while leaving so the system can calculate any overstay.'
                              : 'Show this QR at entry and again at exit.',
                          style: TextStyle(color: textGrey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: code,
                    version: QrVersions.auto,
                    size: 220,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: primaryGreen,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    code.length > 8
                        ? '${code.substring(0, 8).toUpperCase()}...'
                        : code,
                    style: TextStyle(
                      color: textGrey,
                      fontSize: 13,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Details',
                    style: TextStyle(
                      color: textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _detailRow(
                    Icons.local_parking_rounded,
                    'Parking Lot',
                    booking['parking_lot_name'] ?? '-',
                  ),
                  _detailRow(
                    Icons.directions_car_rounded,
                    'Vehicle',
                    booking['vehicle_number'] ?? '-',
                  ),
                  _detailRow(
                    Icons.play_arrow_rounded,
                    'Start',
                    formatTime(booking['start_time'] ?? ''),
                  ),
                  _detailRow(
                    Icons.stop_rounded,
                    'End',
                    formatTime(booking['end_time'] ?? ''),
                  ),
                  _detailRow(
                    Icons.currency_rupee_rounded,
                    'Base Amount',
                    formatMoney(booking['amount']),
                  ),
                  if ((double.tryParse('${booking['penalty_amount']}') ?? 0) >
                      0)
                    _detailRow(
                      Icons.warning_amber_rounded,
                      'Penalty',
                      formatMoney(booking['penalty_amount']),
                      valueColor: Colors.red,
                    ),
                  if (booking['total_charge'] != null)
                    _detailRow(
                      Icons.receipt_long_rounded,
                      'Total',
                      formatMoney(booking['total_charge']),
                    ),
                  _detailRow(
                    Icons.info_outline_rounded,
                    'Status',
                    status,
                    valueColor: isActive
                        ? const Color(0xFF2563EB)
                        : primaryGreen,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1E7E34)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? const Color(0xFF0D1B0F),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
