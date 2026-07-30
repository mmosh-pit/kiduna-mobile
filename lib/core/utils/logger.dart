import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

/// Application logger — the ONLY sanctioned way to log.
///
/// Never use `print`, `debugPrint`, or `stdout`. Debug/info/warning logs are
/// stripped in release; errors always log and should be forwarded to a crash
/// reporter in release builds.
abstract class AppLogger {
  const AppLogger._();

  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      dev.log('💚 [DEBUG] ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      dev.log('💙 [INFO] ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void warning(String message, {String? tag}) {
    if (kDebugMode) {
      dev.log('🟡 [WARN] ${tag != null ? '[$tag] ' : ''}$message');
    }
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    dev.log(
      '🔴 [ERROR] ${tag != null ? '[$tag] ' : ''}$message',
      error: error,
      stackTrace: stackTrace,
    );
    // TODO(KID-1): Forward to a crash reporter (Sentry/Crashlytics) in release.
    // if (kReleaseMode) { CrashReporting.recordError(error, stackTrace); }
  }
}
