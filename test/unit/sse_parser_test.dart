import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/core/utils/sse_parser.dart';
import 'package:kiduna/data/models/sse_event.dart';

/// Helper: encode a string as a single-element byte stream.
Stream<List<int>> _bytesFrom(String data) async* {
  yield utf8.encode(data);
}

/// Helper: encode a string split into multiple chunks.
Stream<List<int>> _chunkedBytesFrom(List<String> chunks) async* {
  for (final chunk in chunks) {
    yield utf8.encode(chunk);
  }
}

void main() {
  group('SseParser.parse', () {
    test('parses a single token event', () async {
      final stream = _bytesFrom('data: {"event":"token","token":"Hello"}\n\n');

      final events = await SseParser.parse(stream).toList();

      expect(events, hasLength(1));
      expect(events[0], isA<SseTokenEvent>());
      expect((events[0] as SseTokenEvent).token, 'Hello');
    });

    test('parses multiple events in one chunk', () async {
      final stream = _bytesFrom(
        'data: {"event":"token","token":"Hi"}\n\n'
        'data: {"event":"token","token":" there"}\n\n'
        'data: {"event":"done","fullResponse":"Hi there"}\n\n',
      );

      final events = await SseParser.parse(stream).toList();

      expect(events, hasLength(3));
      expect(events[0], isA<SseTokenEvent>());
      expect(events[1], isA<SseTokenEvent>());
      expect(events[2], isA<SseDoneEvent>());
      expect((events[2] as SseDoneEvent).fullResponse, 'Hi there');
    });

    test('parses standard CRLF-delimited events', () async {
      final stream = _bytesFrom(
        'data: {"event":"token","token":"Hi"}\r\n\r\n'
        'data: {"event":"done","fullResponse":"Hi"}\r\n\r\n',
      );

      final events = await SseParser.parse(stream).toList();

      expect(events, hasLength(2));
      expect((events[0] as SseTokenEvent).token, 'Hi');
      expect((events[1] as SseDoneEvent).fullResponse, 'Hi');
    });

    test('accepts Dio-style Uint8List response streams', () async {
      final Stream<Uint8List> dioStream = Stream.value(
        Uint8List.fromList(
          utf8.encode('data: {"event":"token","token":"Hi"}\r\n\r\n'),
        ),
      );
      final Stream<List<int>> stream = dioStream;

      final events = await SseParser.parse(stream).toList();

      expect(events, hasLength(1));
      expect((events.single as SseTokenEvent).token, 'Hi');
    });

    test('handles a CRLF frame boundary split across chunks', () async {
      final stream = _chunkedBytesFrom([
        'data: {"event":"token","token":"a"}\r',
        '\n\r',
        '\ndata: {"event":"token","token":"b"}\r\n\r\n',
      ]);

      final events = await SseParser.parse(stream).toList();

      expect(events, hasLength(2));
      expect((events[0] as SseTokenEvent).token, 'a');
      expect((events[1] as SseTokenEvent).token, 'b');
    });

    test('handles event split across two chunks', () async {
      final stream = _chunkedBytesFrom([
        'data: {"event":"tok',
        'en","token":"split"}\n\n',
      ]);

      final events = await SseParser.parse(stream).toList();

      expect(events, hasLength(1));
      expect(events[0], isA<SseTokenEvent>());
      expect((events[0] as SseTokenEvent).token, 'split');
    });

    test('handles double-newline split across chunks', () async {
      final stream = _chunkedBytesFrom([
        'data: {"event":"token","token":"a"}\n',
        '\ndata: {"event":"token","token":"b"}\n\n',
      ]);

      final events = await SseParser.parse(stream).toList();

      expect(events, hasLength(2));
      expect((events[0] as SseTokenEvent).token, 'a');
      expect((events[1] as SseTokenEvent).token, 'b');
    });

    test('parses error event', () async {
      final stream = _bytesFrom(
        'data: {"event":"error","error":"fail","code":"ERR"}\n\n',
      );

      final events = await SseParser.parse(stream).toList();

      expect(events, hasLength(1));
      expect(events[0], isA<SseErrorEvent>());
      final error = events[0] as SseErrorEvent;
      expect(error.error, 'fail');
      expect(error.code, 'ERR');
    });

    test('parses info events', () async {
      final stream = _bytesFrom('data: {"event":"start","data":"meta"}\n\n');

      final events = await SseParser.parse(stream).toList();

      expect(events, hasLength(1));
      expect(events[0], isA<SseInfoEvent>());
      expect((events[0] as SseInfoEvent).event, 'start');
    });

    test('skips empty frames', () async {
      final stream = _bytesFrom('\n\ndata: {"event":"token","token":"a"}\n\n');

      final events = await SseParser.parse(stream).toList();

      expect(events, hasLength(1));
      expect((events[0] as SseTokenEvent).token, 'a');
    });

    test('processes remaining data at end of stream', () async {
      final stream = _bytesFrom('data: {"event":"token","token":"final"}');

      final events = await SseParser.parse(stream).toList();

      expect(events, hasLength(1));
      expect((events[0] as SseTokenEvent).token, 'final');
    });

    test('skips malformed JSON frames', () async {
      final stream = _bytesFrom(
        'data: not-json\n\n'
        'data: {"event":"token","token":"ok"}\n\n',
      );

      final events = await SseParser.parse(stream).toList();

      expect(events, hasLength(1));
      expect((events[0] as SseTokenEvent).token, 'ok');
    });

    test('handles UTF-8 multibyte characters', () async {
      final stream = _bytesFrom(
        'data: {"event":"token","token":"Hello 🌍"}\n\n',
      );

      final events = await SseParser.parse(stream).toList();

      expect(events, hasLength(1));
      expect((events[0] as SseTokenEvent).token, 'Hello 🌍');
    });

    test('parses done event with usage', () async {
      final stream = _bytesFrom(
        'data: {"event":"done","fullResponse":"text","usage":{"inputTokens":10,"outputTokens":5}}\n\n',
      );

      final events = await SseParser.parse(stream).toList();

      expect(events, hasLength(1));
      final done = events[0] as SseDoneEvent;
      expect(done.fullResponse, 'text');
      expect(done.inputTokens, 10);
      expect(done.outputTokens, 5);
    });

    test('handles empty stream', () async {
      final stream = _bytesFrom('');

      final events = await SseParser.parse(stream).toList();

      expect(events, isEmpty);
    });

    test('handles frames without data: prefix', () async {
      final stream = _bytesFrom('comment: ignored\n\n');

      final events = await SseParser.parse(stream).toList();

      expect(events, isEmpty);
    });
  });
}
