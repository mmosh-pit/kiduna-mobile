import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

class AppLogger {
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
  }
}
