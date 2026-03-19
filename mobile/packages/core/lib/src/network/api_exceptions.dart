class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException()
      : super(message: 'Session expired. Please login again.', statusCode: 401);
}

class NetworkException extends ApiException {
  const NetworkException()
      : super(message: 'No internet connection. Please check your network.');
}

class ServerException extends ApiException {
  const ServerException({String? message})
      : super(
          message: message ?? 'Server error. Please try again later.',
          statusCode: 500,
        );
}
