import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:core/core.dart';
import '../services/api_service.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool isProcessing = false;
  bool hasResult = false;
  Map<String, dynamic>? result;

  Future<void> onQRDetected(String code) async {
    if (isProcessing || hasResult) return;
    setState(() => isProcessing = true);
    _controller.stop();

    try {
      final response = await ApiService.validateQR(code);
      if (!mounted) return;
      setState(() {
        result = response;
        hasResult = true;
        isProcessing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        result = {'entry_status': 'denied', 'reason': 'Server error.'};
        hasResult = true;
        isProcessing = false;
      });
    }
  }

  void resetScanner() {
    setState(() {
      hasResult = false;
      result = null;
      isProcessing = false;
    });
    _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan QR',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flashlight_on_rounded, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: hasResult ? _buildResult() : _buildScanner(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            final code = capture.barcodes.first.rawValue;
            if (code != null) onQRDetected(code);
          },
        ),
        CustomPaint(size: Size.infinite, painter: _ScannerOverlayPainter()),
        // Processing spinner
        if (isProcessing)
          const Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5),
            ),
          ),
        // Hint label
        if (!isProcessing)
          Positioned(
            bottom: 56,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Text(
                  'Point at the resident\'s QR code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResult() {
    final entryStatus = result?['entry_status'] ?? 'denied';
    final isAllowed = entryStatus == 'allowed';
    final scanAction = result?['scan_action'] as String? ?? 'entry';
    final message = result?['message'] as String? ?? '';
    final reason = result?['reason'] as String? ?? 'Access denied';
    final customer = result?['customer'] as String? ?? '-';
    final vehicleNumber = result?['vehicle_number'] as String? ?? '-';
    final parkingLot = result?['parking_lot'] as String? ?? '-';
    final startTime = result?['start_time'] as String? ?? '';
    final endTime = result?['end_time'] as String? ?? '';
    final overstayMinutes = result?['overstay_minutes']?.toString() ?? '0';
    final penaltyAmount = result?['penalty_amount']?.toString() ?? '0';
    final totalAmount = result?['total_amount']?.toString() ?? '';

    final isExit = scanAction == 'exit';
    final hasOverstay =
        isExit && int.tryParse(overstayMinutes) != null && int.parse(overstayMinutes) > 0;

    final heading = !isAllowed
        ? 'ACCESS DENIED'
        : isExit
            ? 'EXIT RECORDED'
            : 'ENTRY ALLOWED';

    final headingColor = !isAllowed
        ? const Color(0xFFFF4444)
        : const Color(0xFF22C55E);

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
        child: Column(
          children: [
            // ── Status icon ───────────────────────────────────────────────
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: headingColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: headingColor.withValues(alpha: 0.35), width: 1.5),
              ),
              child: Icon(
                !isAllowed
                    ? Icons.cancel_outlined
                    : isExit
                        ? Icons.logout_rounded
                        : Icons.login_rounded,
                size: 44,
                color: headingColor,
              ),
            ),
            const SizedBox(height: 20),

            // ── Heading ───────────────────────────────────────────────────
            Text(
              heading,
              style: TextStyle(
                color: headingColor,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAllowed ? message : reason,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontFamily: 'Inter',
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),

            // ── Details card (only when allowed) ─────────────────────────
            if (isAllowed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isExit ? 'EXIT DETAILS' : 'ENTRY DETAILS',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Resident',
                        value: customer),
                    _DetailRow(
                        icon: Icons.directions_car_outlined,
                        label: 'Vehicle',
                        value: vehicleNumber),
                    _DetailRow(
                        icon: Icons.location_on_outlined,
                        label: 'Society',
                        value: parkingLot),
                    _DetailRow(
                        icon: Icons.swap_horiz_rounded,
                        label: 'Scan type',
                        value: scanAction.toUpperCase()),
                    _DetailRow(
                        icon: Icons.play_circle_outline_rounded,
                        label: 'Start',
                        value: _formatTime(startTime)),
                    _DetailRow(
                        icon: Icons.stop_circle_outlined,
                        label: 'End',
                        value: _formatTime(endTime)),
                    if (isExit) ...[
                      if (hasOverstay) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF2222).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFFF4444)
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            children: [
                              _DetailRow(
                                icon: Icons.warning_amber_rounded,
                                label: 'Overstay',
                                value: '$overstayMinutes min',
                                valueColor: const Color(0xFFFF6B6B),
                              ),
                              _DetailRow(
                                icon: Icons.currency_rupee_rounded,
                                label: 'Penalty',
                                value: '₹$penaltyAmount',
                                valueColor: const Color(0xFFFF6B6B),
                              ),
                            ],
                          ),
                        ),
                      ] else
                        _DetailRow(
                            icon: Icons.check_circle_outline_rounded,
                            label: 'Overstay',
                            value: 'None',
                            valueColor: AppColors.success),
                    ],
                    if (totalAmount.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _DetailRow(
                          icon: Icons.receipt_long_rounded,
                          label: 'Total',
                          value: '₹$totalAmount'),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 28),

            // ── Scan another button ───────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: resetScanner,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text(
                  'Scan Another QR',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail row used inside the result card
// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryLight),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontFamily: 'Inter',
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scanner overlay painter — brackets only (no opaque overlay)
// ─────────────────────────────────────────────────────────────────────────────

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    const frameSize = 260.0;
    final frameLeft = (size.width - frameSize) / 2;
    final frameTop = (size.height - frameSize) / 2;
    final frameRect =
        Rect.fromLTWH(frameLeft, frameTop, frameSize, frameSize);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
          RRect.fromRectAndRadius(frameRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    // Corner brackets in periwinkle
    final cornerPaint = Paint()
      ..color = AppColors.primaryLight
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 28.0;
    final r = frameRect;
    for (final points in [
      [r.topLeft, r.topLeft + const Offset(len, 0)],
      [r.topLeft, r.topLeft + const Offset(0, len)],
      [r.topRight, r.topRight + const Offset(-len, 0)],
      [r.topRight, r.topRight + const Offset(0, len)],
      [r.bottomLeft, r.bottomLeft + const Offset(len, 0)],
      [r.bottomLeft, r.bottomLeft + const Offset(0, -len)],
      [r.bottomRight, r.bottomRight + const Offset(-len, 0)],
      [r.bottomRight, r.bottomRight + const Offset(0, -len)],
    ]) {
      canvas.drawLine(points[0], points[1], cornerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
