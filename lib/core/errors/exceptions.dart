abstract class AppException implements Exception {
  const AppException([this.message]);

  final String? message;

  @override
  String toString() => '$runtimeType${message != null ? ': $message' : ''}';
}

class ServerException extends AppException {
  const ServerException([super.message]);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message]);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message]);
}

class NetworkException extends AppException {
  const NetworkException([super.message]);
}

class ApiTimeoutException extends AppException {
  const ApiTimeoutException([super.message]);
}

class CacheException extends AppException {
  const CacheException([super.message]);
}

class ValidationException extends AppException {
  const ValidationException([super.message]);
}

class ConflictException extends AppException {
  const ConflictException([super.message]);
}
