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

  static const dev = EnvConfig._(
    environment: Environment.dev,
    apiBaseUrl: 'http://10.0.2.2:8000', // Web/Chrome localhost
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
