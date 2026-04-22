import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../screens/login_screen.dart';
import '../services/api_service.dart';

class GuardScannerPage extends StatefulWidget {
  final String guardName;

  const GuardScannerPage({super.key, required this.guardName});

  @override
  State<GuardScannerPage> createState() => _GuardScannerPageState();
}

class _GuardScannerPageState extends State<GuardScannerPage> {
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
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          automaticallyImplyLeading: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Guard Scanner',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              Text(
                '👮 ${widget.guardName}',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
              onPressed: () => _controller.toggleTorch(),
            ),
            IconButton(
              icon: const Icon(
                Icons.flip_camera_ios_rounded,
                color: Colors.white,
              ),
              onPressed: () => _controller.switchCamera(),
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white54),
              onPressed: () => _confirmLogout(context),
            ),
          ],
        ),
        body: hasResult ? _buildResult() : _buildScanner(),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
        CustomPaint(size: Size.infinite, painter: _ScannerOverlayPainter()),
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
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Point camera at customer\'s QR code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final entryStatus = result?['entry_status'] ?? 'denied';
    final isAllowed = entryStatus == 'allowed';
    final scanAction = result?['scan_action'] as String? ?? 'entry';
    final vehicleNumber = result?['vehicle_number'] as String? ?? 'Unknown';
    final message =
        result?['message'] as String? ?? 'Vehicle is authorized to enter';
    final reason = result?['reason'] as String? ?? 'Invalid or fake QR code';
    final totalAmount = result?['total_amount']?.toString() ?? '';
    final overstayMinutes = result?['overstay_minutes']?.toString() ?? '0';

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) resetScanner();
    });

    return Container(
      color: isAllowed ? const Color(0xFFF0FFF4) : const Color(0xFFFFF0F0),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: isAllowed
                    ? const Color(0xFF1E7E34).withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAllowed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 90,
                color: isAllowed ? const Color(0xFF1E7E34) : Colors.red,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              isAllowed
                  ? (scanAction == 'exit' ? 'Exit Recorded' : 'Entry Allowed')
                  : 'Entry Denied',
              style: TextStyle(
                color: isAllowed ? const Color(0xFF1E7E34) : Colors.red,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isAllowed ? message : reason,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 28),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isAllowed
                        ? (scanAction == 'exit'
                              ? Icons.logout_rounded
                              : Icons.directions_car_rounded)
                        : Icons.error_outline_rounded,
                    color: isAllowed ? const Color(0xFF1E7E34) : Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      isAllowed
                          ? scanAction == 'exit' && totalAmount.isNotEmpty
                                ? '$vehicleNumber | ₹$totalAmount'
                                : vehicleNumber
                          : reason,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D1B0F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isAllowed && scanAction == 'exit') ...[
              const SizedBox(height: 16),
              Text(
                'Overstay: $overstayMinutes min',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: _CountdownBar(
                duration: const Duration(seconds: 3),
                color: isAllowed ? const Color(0xFF1E7E34) : Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Returning to scanner in 3 seconds...',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownBar extends StatefulWidget {
  final Duration duration;
  final Color color;

  const _CountdownBar({required this.duration, required this.color});

  @override
  State<_CountdownBar> createState() => _CountdownBarState();
}

class _CountdownBarState extends State<_CountdownBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: 1 - _controller.value,
          backgroundColor: Colors.grey.shade200,
          color: widget.color,
          minHeight: 8,
        ),
      ),
    );
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

    canvas.drawLine(
      r.topLeft,
      r.topLeft + const Offset(cornerLen, 0),
      cornerPaint,
    );
    canvas.drawLine(
      r.topLeft,
      r.topLeft + const Offset(0, cornerLen),
      cornerPaint,
    );
    canvas.drawLine(
      r.topRight,
      r.topRight + const Offset(-cornerLen, 0),
      cornerPaint,
    );
    canvas.drawLine(
      r.topRight,
      r.topRight + const Offset(0, cornerLen),
      cornerPaint,
    );
    canvas.drawLine(
      r.bottomLeft,
      r.bottomLeft + const Offset(cornerLen, 0),
      cornerPaint,
    );
    canvas.drawLine(
      r.bottomLeft,
      r.bottomLeft + const Offset(0, -cornerLen),
      cornerPaint,
    );
    canvas.drawLine(
      r.bottomRight,
      r.bottomRight + const Offset(-cornerLen, 0),
      cornerPaint,
    );
    canvas.drawLine(
      r.bottomRight,
      r.bottomRight + const Offset(0, -cornerLen),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
