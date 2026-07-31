import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../errors/exceptions.dart';
import '../utils/logger.dart';

/// Injects the `Authorization: Bearer <token>` header into every request when
/// a token is available.
///
/// The token is supplied via [tokenProvider] — a simple getter callback. This
/// avoids a direct import of the secure-storage singleton, making the
/// interceptor testable with a stub.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.tokenProvider});

  /// Returns the current auth token, or `null` when unauthenticated.
  final Future<String?> Function() tokenProvider;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenProvider();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Maps [DioException] types to the app's typed exception hierarchy.
///
/// Every HTTP error category becomes the matching [AppException] subclass so
/// callers only deal with the seven exception types defined in
/// `core/errors/exceptions.dart`.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const ApiTimeoutException('Request timed out'),
          type: err.type,
        ),
      );
      return;
    }

    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.unknown) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const NetworkException(
            'Unable to connect. Please check your internet.',
          ),
          type: err.type,
        ),
      );
      return;
    }

    if (statusCode != null) {
      final detail = _extractDetail(err);
      AppException mapped;
      if (statusCode == 401 || statusCode == 403) {
        mapped = UnauthorizedException(detail);
      } else if (statusCode == 404) {
        mapped = NotFoundException(detail);
      } else if (statusCode >= 500) {
        mapped = ServerException(detail);
      } else {
        mapped = ServerException(detail ?? 'Request failed ($statusCode)');
      }
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          error: mapped,
          type: err.type,
        ),
      );
      return;
    }

    handler.next(err);
  }

  String? _extractDetail(DioException err) {
    try {
      final data = err.response?.data;
      if (data is Map<String, dynamic>) {
        return (data['detail'] ?? data['message'] ?? data['error']) as String?;
      }
    } catch (_) {
      // Ignore parse errors — fall through to null.
    }
    return null;
  }
}

/// Logs request/response details in debug builds only.
///
/// Never logs tokens, emails, or other PII (CLAUDE.md Section 6).
class AppLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      AppLogger.debug('→ ${options.method} ${options.uri}', tag: 'HTTP');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      AppLogger.debug(
        '← ${response.statusCode} ${response.requestOptions.uri}',
        tag: 'HTTP',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      AppLogger.warning(
        '✕ ${err.response?.statusCode ?? 'NETWORK'} '
        '${err.requestOptions.uri} — ${err.message}',
        tag: 'HTTP',
      );
    }
    handler.next(err);
  }
}
