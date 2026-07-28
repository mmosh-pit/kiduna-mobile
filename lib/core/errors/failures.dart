/// Base type for recoverable failures surfaced to the presentation layer.
///
/// Repositories translate exceptions into failures; controllers turn failures
/// into user-facing messages. Failures are value types — they compare equal
/// when their runtime type and message match.
abstract class Failure {
  const Failure(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      other is Failure &&
      other.runtimeType == runtimeType &&
      other.message == message;

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() => '$runtimeType: $message';
}

/// The server returned an error (5xx).
class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'A server error occurred. Please try again.',
  ]);
}

/// The device is offline or the request timed out.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

/// Authentication is missing or expired (401/403).
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Session expired. Please sign in again.',
  ]);
}

/// The requested resource does not exist (404).
class NotFoundFailure extends Failure {
  const NotFoundFailure([
    super.message = 'The requested resource was not found.',
  ]);
}

/// Reading from or writing to local storage failed.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Failed to read local data.']);
}

/// Input did not pass validation.
class ValidationFailure extends Failure {
  const ValidationFailure([
    super.message = 'Please check your input and try again.',
  ]);
}

/// An unexpected error with no more specific cause.
class UnknownFailure extends Failure {
  const UnknownFailure([
    super.message = 'Something went wrong. Please try again.',
  ]);
}
