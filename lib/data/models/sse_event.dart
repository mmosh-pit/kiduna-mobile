import 'package:flutter/foundation.dart';

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

  static int _intField(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}

@immutable
class SseTokenEvent extends SseEvent {
  const SseTokenEvent({required this.token});

  final String token;

  @override
  String toString() => 'SseTokenEvent(token: $token)';
}

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

@immutable
class SseErrorEvent extends SseEvent {
  const SseErrorEvent({required this.error, this.code = ''});

  final String error;
  final String code;

  @override
  String toString() => 'SseErrorEvent(code: $code, error: $error)';
}

@immutable
class SseInfoEvent extends SseEvent {
  const SseInfoEvent({required this.event, required this.data});

  final String event;
  final Map<String, dynamic> data;

  @override
  String toString() => 'SseInfoEvent(event: $event)';
}
