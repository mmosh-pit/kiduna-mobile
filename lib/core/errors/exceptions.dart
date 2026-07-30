/// Base class for typed exceptions thrown by the data layer.
///
/// Services throw these; repositories and controllers catch and translate them
/// into failures or user-facing messages. Never surface these to the UI raw.
abstract class AppException implements Exception {
  const AppException([this.message]);

  final String? message;

  @override
  String toString() => '$runtimeType${message != null ? ': $message' : ''}';
}

/// API returned a 5xx response.
class ServerException extends AppException {
  const ServerException([super.message]);
}

/// API returned 401/403.
class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message]);
}

/// API returned 404.
class NotFoundException extends AppException {
  const NotFoundException([super.message]);
}

/// No internet connection or request timed out.
class NetworkException extends AppException {
  const NetworkException([super.message]);
}

/// Local storage read/write failed.
class CacheException extends AppException {
  const CacheException([super.message]);
}

/// Input failed validation.
class ValidationException extends AppException {
  const ValidationException([super.message]);
}
