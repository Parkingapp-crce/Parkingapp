import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

enum Environment { dev, staging, prod }

class EnvConfig {
  final Environment environment;
  final String apiBaseUrl;
  final String razorpayKey;

  const EnvConfig._({
    required this.environment,
    required this.apiBaseUrl,
    this.razorpayKey = '',
  });

  static String get _defaultDevUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch (_) {} 
    return 'http://127.0.0.1:8000';
  }

  static final dev = EnvConfig._(
    environment: Environment.dev,
    apiBaseUrl: _defaultDevUrl,
  );

  static const staging = EnvConfig._(
    environment: Environment.staging,
    apiBaseUrl: 'https://staging-api.parking.com',
  );

  static const prod = EnvConfig._(
    environment: Environment.prod,
    apiBaseUrl: 'https://api.parking.com',
    razorpayKey: '',
  );

  bool get isDev => environment == Environment.dev;
}
