import 'dart:async';
import 'dart:convert';

import '../../data/models/sse_event.dart';
import 'logger.dart';

class SseParser {
  const SseParser._();

  static Stream<SseEvent> parse(Stream<List<int>> byteStream) async* {
    final buffer = StringBuffer();

    // Decode the stream incrementally so a UTF-8 code point split across two
    // network chunks is not treated as malformed input.
    final textStream = byteStream
        .map<List<int>>((bytes) => bytes)
        .transform(utf8.decoder);
    await for (final chunk in textStream) {
      buffer.write(chunk);

      final raw = _normalizeLineEndings(buffer.toString());
      final frames = raw.split('\n\n');

      if (frames.length <= 1) {
        continue;
      }

      for (var i = 0; i < frames.length - 1; i++) {
        final event = _parseFrame(frames[i]);
        if (event != null) {
          yield event;
        }
      }

      buffer
        ..clear()
        ..write(frames.last);
    }

    final remaining = _normalizeLineEndings(
      buffer.toString(),
      streamComplete: true,
    ).trim();
    if (remaining.isNotEmpty) {
      final event = _parseFrame(remaining);
      if (event != null) {
        yield event;
      }
    }
  }

  /// SSE permits CRLF, LF, and CR line endings. Preserve a trailing CR while
  /// the stream is open because the matching LF may arrive in the next chunk.
  static String _normalizeLineEndings(
    String input, {
    bool streamComplete = false,
  }) {
    final preserveTrailingCr = !streamComplete && input.endsWith('\r');
    var normalized = preserveTrailingCr
        ? input.substring(0, input.length - 1)
        : input;
    normalized = normalized.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    return preserveTrailingCr ? '$normalized\r' : normalized;
  }

  static SseEvent? _parseFrame(String frame) {
    final trimmed = frame.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final dataLines = <String>[];
    for (final line in trimmed.split('\n')) {
      if (line.startsWith('data: ')) {
        dataLines.add(line.substring(6));
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring(5));
      }
    }

    if (dataLines.isEmpty) {
      return null;
    }

    final payload = dataLines.join('\n').trim();
    if (payload.isEmpty) {
      return null;
    }

    try {
      final json = jsonDecode(payload) as Map<String, dynamic>;
      return SseEvent.fromJson(json);
    } on FormatException catch (e) {
      AppLogger.warning(
        'Malformed SSE payload: ${e.message}',
        tag: 'SseParser',
      );
      return null;
    } catch (e) {
      AppLogger.warning('SSE parse error: $e', tag: 'SseParser');
      return null;
    }
  }
}
