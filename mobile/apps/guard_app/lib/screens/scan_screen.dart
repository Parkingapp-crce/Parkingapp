import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../cubits/scan_cubit.dart';
import '../main.dart';

class ScanScreen extends StatefulWidget {
  final bool isEntry;

  const ScanScreen({super.key, required this.isEntry});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  late final MobileScannerController _scannerController;
  late final ScanCubit _scanCubit;
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
    _scanCubit = ScanCubit(apiClient: getIt<ApiClient>());
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _scanCubit.close();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final value = barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;

    setState(() {
      _hasScanned = true;
    });

    _scannerController.stop();

    if (widget.isEntry) {
      _scanCubit.validateEntry(value);
    } else {
      _scanCubit.validateExit(value);
    }
  }

  void _resetScanner() {
    setState(() {
      _hasScanned = false;
    });
    _scanCubit.reset();
    _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    final scanType = widget.isEntry ? 'Entry' : 'Exit';

    return BlocListener<ScanCubit, ScanState>(
      bloc: _scanCubit,
      listener: (context, state) {
        if (state is ScanSuccess) {
          context.push('/result', extra: {
            'isSuccess': true,
            'data': state.data,
            'errorMessage': null,
            'isEntry': widget.isEntry,
          });
          // Reset scanner when coming back
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _resetScanner();
          });
        } else if (state is ScanError) {
          context.push('/result', extra: {
            'isSuccess': false,
            'data': null,
            'errorMessage': state.message,
            'isEntry': widget.isEntry,
          });
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _resetScanner();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Scan $scanType QR'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            // Torch toggle
            IconButton(
              icon: const Icon(Icons.flash_on),
              tooltip: 'Toggle Flash',
              onPressed: () => _scannerController.toggleTorch(),
            ),
            // Camera switch
            IconButton(
              icon: const Icon(Icons.cameraswitch),
              tooltip: 'Switch Camera',
              onPressed: () => _scannerController.switchCamera(),
            ),
          ],
        ),
        body: Stack(
          children: [
            // Camera preview
            MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),

            // Scan overlay
            _ScanOverlay(scanType: scanType),

            // Loading overlay
            BlocBuilder<ScanCubit, ScanState>(
              bloc: _scanCubit,
              builder: (context, state) {
                if (state is ScanLoading) {
                  return Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Validating...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  final String scanType;

  const _ScanOverlay({required this.scanType});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        // Bottom instruction
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.qr_code_scanner,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Point camera at $scanType QR code',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
