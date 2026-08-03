import 'dart:async';
import 'dart:convert';

import '../../data/models/sse_event.dart';
import 'logger.dart';

/// Transforms a raw byte stream (from Dio's `ResponseType.stream`) into
/// a stream of [SseEvent] objects.
///
/// The SSE protocol sends frames as `data: <json>\n\n`. This parser:
/// 1. Decodes UTF-8 bytes into a string buffer.
/// 2. Splits on double-newline to find complete frames.
/// 3. Strips the `data: ` prefix.
/// 4. Parses each chunk as JSON and maps to an [SseEvent].
///
/// Partial frames are buffered until the next chunk completes them.
class SseParser {
  const SseParser._();

  /// Parse a raw byte stream into [SseEvent] objects.
  static Stream<SseEvent> parse(Stream<List<int>> byteStream) async* {
    final buffer = StringBuffer();

    await for (final chunk in byteStream.transform(utf8.decoder)) {
      buffer.write(chunk);

      final raw = buffer.toString();
      final frames = raw.split('\n\n');

      if (frames.length <= 1) {
        continue;
      }

      // All frames except the last are complete. The last may be partial.
      for (var i = 0; i < frames.length - 1; i++) {
        final event = _parseFrame(frames[i]);
        if (event != null) {
          yield event;
        }
      }

      // Keep the incomplete trailing frame in the buffer.
      buffer
        ..clear()
        ..write(frames.last);
    }

    // Process any remaining data in the buffer.
    final remaining = buffer.toString().trim();
    if (remaining.isNotEmpty) {
      final event = _parseFrame(remaining);
      if (event != null) {
        yield event;
      }
    }
  }

  static SseEvent? _parseFrame(String frame) {
    final trimmed = frame.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    // Extract the data payload — may span multiple lines prefixed with
    // `data: `, or be a single `data: {...}` line.
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
