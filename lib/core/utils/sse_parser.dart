import 'dart:async';
import 'dart:convert';

import '../../data/models/sse_event.dart';
import 'logger.dart';

class SseParser {
  const SseParser._();

  static Stream<SseEvent> parse(Stream<List<int>> byteStream) async* {
    final buffer = StringBuffer();

    await for (final bytes in byteStream) {
      final chunk = utf8.decode(bytes);
      buffer.write(chunk);

      final raw = buffer.toString();
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
