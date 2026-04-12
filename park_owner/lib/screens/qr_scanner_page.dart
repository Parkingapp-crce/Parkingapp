import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final Color primaryGreen = const Color(0xFF1E7E34);
  final Color textDark = const Color(0xFF0D1B0F);
  final Color textGrey = const Color(0xFF6B7280);

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
      setState(() {
        result = response;
        hasResult = true;
        isProcessing = false;
      });
    } catch (e) {
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Scan QR Code',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
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
            final barcode = capture.barcodes.first;
            final code = barcode.rawValue;
            if (code != null) onQRDetected(code);
          },
        ),

        CustomPaint(
          size: Size.infinite,
          painter: _ScannerOverlayPainter(),
        ),

        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Column(
            children: [
              if (isProcessing)
                const CircularProgressIndicator(color: Colors.white)
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Point camera at customer\'s QR code',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    // ✅ FIX: Extract values first to avoid ternary + null-aware conflict
    final entryStatus = result?['entry_status'] ?? 'denied';
    final isAllowed = entryStatus == 'allowed';
    final message = result?['message'] as String? ?? '';
    final reason = result?['reason'] as String? ?? 'Access denied';
    final customer = result?['customer'] as String? ?? '-';
    final vehicleNumber = result?['vehicle_number'] as String? ?? '-';
    final parkingLot = result?['parking_lot'] as String? ?? '-';
    final startTime = result?['start_time'] as String? ?? '';
    final endTime = result?['end_time'] as String? ?? '';

    return Container(
      color: const Color(0xFFF5F9F5),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Status icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isAllowed
                    ? primaryGreen.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAllowed
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                size: 60,
                color: isAllowed ? primaryGreen : Colors.red,
              ),
            ),

            const SizedBox(height: 20),

            // Status text
            Text(
              isAllowed ? 'ENTRY ALLOWED ✅' : 'ENTRY DENIED ❌',
              style: TextStyle(
                color: isAllowed ? primaryGreen : Colors.red,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              isAllowed ? message : reason,
              textAlign: TextAlign.center,
              style: TextStyle(color: textGrey, fontSize: 15),
            ),

            const SizedBox(height: 30),

            // Details card (only if allowed)
            if (isAllowed) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Entry Details',
                        style: TextStyle(
                            color: textDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                    const SizedBox(height: 16),
                    _detailRow(Icons.person_rounded, 'Customer', customer),
                    _detailRow(Icons.directions_car_rounded, 'Vehicle', vehicleNumber),
                    _detailRow(Icons.local_parking_rounded, 'Parking Lot', parkingLot),
                    _detailRow(Icons.play_arrow_rounded, 'Start', _formatTime(startTime)),
                    _detailRow(Icons.stop_rounded, 'End', _formatTime(endTime)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            // Scan again button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: resetScanner,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Scan Another QR',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primaryGreen),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: textGrey, fontSize: 13)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  color: textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ],
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

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    const frameSize = 260.0;
    final frameLeft = (size.width - frameSize) / 2;
    final frameTop = (size.height - frameSize) / 2;
    final frameRect = Rect.fromLTWH(frameLeft, frameTop, frameSize, frameSize);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(frameRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    final cornerPaint = Paint()
      ..color = const Color(0xFF1E7E34)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 28.0;
    final r = frameRect;

    canvas.drawLine(r.topLeft, r.topLeft + const Offset(cornerLen, 0), cornerPaint);
    canvas.drawLine(r.topLeft, r.topLeft + const Offset(0, cornerLen), cornerPaint);
    canvas.drawLine(r.topRight, r.topRight + const Offset(-cornerLen, 0), cornerPaint);
    canvas.drawLine(r.topRight, r.topRight + const Offset(0, cornerLen), cornerPaint);
    canvas.drawLine(r.bottomLeft, r.bottomLeft + const Offset(cornerLen, 0), cornerPaint);
    canvas.drawLine(r.bottomLeft, r.bottomLeft + const Offset(0, -cornerLen), cornerPaint);
    canvas.drawLine(r.bottomRight, r.bottomRight + const Offset(-cornerLen, 0), cornerPaint);
    canvas.drawLine(r.bottomRight, r.bottomRight + const Offset(0, -cornerLen), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}