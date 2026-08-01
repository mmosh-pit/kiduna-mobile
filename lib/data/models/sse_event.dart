import 'package:flutter/foundation.dart';

/// A parsed Server-Sent Event from `POST /api/chatmessages/stream`.
///
/// The stream sends JSON lines prefixed with `data: `. Each has an `event`
/// field that determines the subtype. Only the three completion-relevant
/// events are modeled as concrete subtypes; orchestration/tool events are
/// captured by [SseInfoEvent].
sealed class SseEvent {
  const SseEvent();

  factory SseEvent.fromJson(Map<String, dynamic> json) {
    final event = json['event'] as String? ?? '';
    return switch (event) {
      'token' => SseTokenEvent(token: (json['token'] ?? '') as String),
      'done' => SseDoneEvent(
        fullResponse: (json['fullResponse'] ?? '') as String,
        inputTokens: _intField(
          (json['usage'] as Map<String, dynamic>?)?['inputTokens'],
        ),
        outputTokens: _intField(
          (json['usage'] as Map<String, dynamic>?)?['outputTokens'],
        ),
      ),
      'error' => SseErrorEvent(
        error: (json['error'] ?? 'Unknown error') as String,
        code: (json['code'] ?? '') as String,
      ),
      _ => SseInfoEvent(event: event, data: json),
    };
  }

  /// Safely convert a JSON number to [int].
  ///
  /// On web, `jsonDecode` produces `double` for all numbers (JavaScript has
  /// no integer type), so a bare `as int` throws `_TypeError`.
  static int _intField(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}

/// Incremental text token from the assistant's response.
@immutable
class SseTokenEvent extends SseEvent {
  const SseTokenEvent({required this.token});

  final String token;

  @override
  String toString() => 'SseTokenEvent(token: $token)';
}

/// The stream is complete — contains the full assembled response.
@immutable
class SseDoneEvent extends SseEvent {
  const SseDoneEvent({
    required this.fullResponse,
    this.inputTokens = 0,
    this.outputTokens = 0,
  });

  final String fullResponse;
  final int inputTokens;
  final int outputTokens;

  @override
  String toString() =>
      'SseDoneEvent(length: ${fullResponse.length}, in: $inputTokens, out: $outputTokens)';
}

/// An error occurred during streaming.
@immutable
class SseErrorEvent extends SseEvent {
  const SseErrorEvent({required this.error, this.code = ''});

  final String error;
  final String code;

  @override
  String toString() => 'SseErrorEvent(code: $code, error: $error)';
}

/// An informational event (start, intent, routing, toolCall, etc.)
/// that the UI does not need to act on directly.
@immutable
class SseInfoEvent extends SseEvent {
  const SseInfoEvent({required this.event, required this.data});

  final String event;
  final Map<String, dynamic> data;

  @override
  String toString() => 'SseInfoEvent(event: $event)';
}
