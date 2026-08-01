import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/data/models/sse_event.dart';

void main() {
  group('SseTokenEvent', () {
    test('fromJson parses token event', () {
      final event = SseEvent.fromJson(const {
        'event': 'token',
        'token': 'Hello',
      });
      expect(event, isA<SseTokenEvent>());
      expect((event as SseTokenEvent).token, 'Hello');
    });

    test('fromJson defaults missing token to empty', () {
      final event = SseEvent.fromJson(const {'event': 'token'});
      expect(event, isA<SseTokenEvent>());
      expect((event as SseTokenEvent).token, '');
    });

    test('toString includes token', () {
      const event = SseTokenEvent(token: 'Hi');
      expect(event.toString(), contains('Hi'));
    });
  });

  group('SseDoneEvent', () {
    test('fromJson parses done event with usage', () {
      final event = SseEvent.fromJson(const {
        'event': 'done',
        'fullResponse': 'Hello Alice!',
        'usage': {'inputTokens': 100, 'outputTokens': 50},
      });
      expect(event, isA<SseDoneEvent>());
      final done = event as SseDoneEvent;
      expect(done.fullResponse, 'Hello Alice!');
      expect(done.inputTokens, 100);
      expect(done.outputTokens, 50);
    });

    test('fromJson handles done event without usage', () {
      final event = SseEvent.fromJson(const {
        'event': 'done',
        'fullResponse': 'Response text',
      });
      expect(event, isA<SseDoneEvent>());
      final done = event as SseDoneEvent;
      expect(done.fullResponse, 'Response text');
      expect(done.inputTokens, 0);
      expect(done.outputTokens, 0);
    });

    test('fromJson defaults missing fullResponse to empty', () {
      final event = SseEvent.fromJson(const {'event': 'done'});
      expect(event, isA<SseDoneEvent>());
      expect((event as SseDoneEvent).fullResponse, '');
    });

    test('fromJson handles double token counts (web runtime)', () {
      final event = SseEvent.fromJson({
        'event': 'done',
        'fullResponse': 'text',
        'usage': {'inputTokens': 9030.0, 'outputTokens': 24.0},
      });
      expect(event, isA<SseDoneEvent>());
      final done = event as SseDoneEvent;
      expect(done.inputTokens, 9030);
      expect(done.outputTokens, 24);
    });

    test('toString includes length and token counts', () {
      const event = SseDoneEvent(
        fullResponse: 'Hello',
        inputTokens: 10,
        outputTokens: 5,
      );
      expect(event.toString(), contains('length: 5'));
      expect(event.toString(), contains('in: 10'));
      expect(event.toString(), contains('out: 5'));
    });
  });

  group('SseErrorEvent', () {
    test('fromJson parses error event', () {
      final event = SseEvent.fromJson(const {
        'event': 'error',
        'error': 'Something went wrong',
        'code': 'ORCHESTRATION_ERROR',
      });
      expect(event, isA<SseErrorEvent>());
      final error = event as SseErrorEvent;
      expect(error.error, 'Something went wrong');
      expect(error.code, 'ORCHESTRATION_ERROR');
    });

    test('fromJson defaults missing fields', () {
      final event = SseEvent.fromJson(const {'event': 'error'});
      expect(event, isA<SseErrorEvent>());
      final error = event as SseErrorEvent;
      expect(error.error, 'Unknown error');
      expect(error.code, '');
    });

    test('toString includes code and error', () {
      const event = SseErrorEvent(error: 'fail', code: 'ERR');
      expect(event.toString(), contains('ERR'));
      expect(event.toString(), contains('fail'));
    });
  });

  group('SseInfoEvent', () {
    test('fromJson maps unknown event types to SseInfoEvent', () {
      final event = SseEvent.fromJson(const {
        'event': 'start',
        'data': 'metadata',
      });
      expect(event, isA<SseInfoEvent>());
      expect((event as SseInfoEvent).event, 'start');
    });

    test('fromJson handles routing event', () {
      final event = SseEvent.fromJson(const {
        'event': 'routing',
        'target': 'agent_1',
      });
      expect(event, isA<SseInfoEvent>());
      expect((event as SseInfoEvent).event, 'routing');
    });

    test('fromJson handles toolCall event', () {
      final event = SseEvent.fromJson(const {
        'event': 'toolCall',
        'tool': 'search',
      });
      expect(event, isA<SseInfoEvent>());
      expect((event as SseInfoEvent).event, 'toolCall');
    });

    test('fromJson handles missing event field', () {
      final event = SseEvent.fromJson(const {'data': 'something'});
      expect(event, isA<SseInfoEvent>());
      expect((event as SseInfoEvent).event, '');
    });

    test('toString includes event type', () {
      const event = SseInfoEvent(event: 'intent', data: {'type': 'chat'});
      expect(event.toString(), contains('intent'));
    });
  });
}
