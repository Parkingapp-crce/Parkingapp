import 'package:flutter/foundation.dart';

enum Environment { dev, staging, prod }

class EnvConfig {
  final Environment environment;
  final String apiBaseUrl;
  final String razorpayKey;
  final String mapTilerApiKey;

  const EnvConfig._({
    required this.environment,
    required this.apiBaseUrl,
    this.razorpayKey = '',
    this.mapTilerApiKey = '',
  });

  static String get _devApiBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }

  static final dev = EnvConfig._(
    environment: Environment.dev,
    apiBaseUrl: _devApiBaseUrl,
    mapTilerApiKey: 'VIpJQZJV80pRnGGCFzcT',
  );

  static const staging = EnvConfig._(
    environment: Environment.staging,
    apiBaseUrl: 'https://staging-api.parking.com',
  );

  static const prod = EnvConfig._(
    environment: Environment.prod,
    apiBaseUrl: 'https://api.parking.com',
    razorpayKey: '',
    mapTilerApiKey: '',
  );

  bool get isDev => environment == Environment.dev;
}
