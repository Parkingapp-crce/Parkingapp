import 'package:flutter/widgets.dart';

const bool supportsEmbeddedCheckout = false;

class EmbeddedCheckoutView extends StatelessWidget {
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
  Widget build(BuildContext context) => const SizedBox.shrink();
}
