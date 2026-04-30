// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';

const bool supportsEmbeddedCheckout = true;

class EmbeddedCheckoutView extends StatefulWidget {
  final String publishableKey;
  final String clientSecret;
  final String sessionId;
  final ValueChanged<String> onComplete;
  final ValueChanged<String> onError;
  final double height;

  const EmbeddedCheckoutView({
    super.key,
    required this.publishableKey,
    required this.clientSecret,
    required this.sessionId,
    required this.onComplete,
    required this.onError,
    this.height = 720,
  });

  @override
  State<EmbeddedCheckoutView> createState() => _EmbeddedCheckoutViewState();
}

class _EmbeddedCheckoutViewState extends State<EmbeddedCheckoutView> {
  late final String _containerId =
      'park-ease-checkout-${DateTime.now().microsecondsSinceEpoch}';
  late final String _viewType = '$_containerId-view';
  StreamSubscription<html.Event>? _completeSubscription;
  StreamSubscription<html.Event>? _errorSubscription;

  @override
  void initState() {
    super.initState();
    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      return html.DivElement()
        ..id = _containerId
        ..style.width = '100%'
        ..style.minHeight = '${widget.height.toInt()}px';
    });
    _completeSubscription = html.window.on['parkEaseCheckoutComplete'].listen(
      _handleComplete,
    );
    _errorSubscription = html.window.on['parkEaseCheckoutError'].listen(
      _handleError,
    );
    _mountAfterLayout();
  }

  @override
  void didUpdateWidget(covariant EmbeddedCheckoutView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clientSecret != widget.clientSecret ||
        oldWidget.sessionId != widget.sessionId) {
      _destroyCheckout();
      _mountAfterLayout();
    }
  }

  @override
  void dispose() {
    _destroyCheckout();
    _completeSubscription?.cancel();
    _errorSubscription?.cancel();
    super.dispose();
  }

  void _mountAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      html.window.dispatchEvent(
        html.CustomEvent(
          'parkEaseMountCheckout',
          detail: jsonEncode({
            'containerId': _containerId,
            'publishableKey': widget.publishableKey,
            'clientSecret': widget.clientSecret,
            'sessionId': widget.sessionId,
          }),
        ),
      );
    });
  }

  void _destroyCheckout() {
    html.window.dispatchEvent(
      html.CustomEvent(
        'parkEaseDestroyCheckout',
        detail: jsonEncode({'containerId': _containerId}),
      ),
    );
  }

  void _handleComplete(html.Event event) {
    final detail = _decodeDetail(event);
    if (detail['containerId'] != _containerId) return;
    widget.onComplete((detail['sessionId'] ?? widget.sessionId).toString());
  }

  void _handleError(html.Event event) {
    final detail = _decodeDetail(event);
    if (detail['containerId'] != _containerId) return;
    widget.onError(
      (detail['message'] ?? 'Checkout could not load.').toString(),
    );
  }

  Map<String, dynamic> _decodeDetail(html.Event event) {
    final customEvent = event as html.CustomEvent;
    final detail = customEvent.detail;
    if (detail is String && detail.isNotEmpty) {
      final decoded = jsonDecode(detail);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    return const {};
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
