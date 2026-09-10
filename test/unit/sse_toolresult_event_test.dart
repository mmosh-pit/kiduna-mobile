import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/data/models/sse_event.dart';

/// The chat stream already emitted `toolResult`; before Theater it fell
/// through to SseInfoEvent and was dropped. These lock in the parse.
void main() {
  group('SseToolResultEvent', () {
    test('fromJson parses a successful tool result', () {
      final event = SseEvent.fromJson(const {
        'event': 'toolResult',
        'toolName': 'generate_video',
        'success': true,
        'output': '{"success": true, "job_id": "job_1"}',
        'callId': 'run_9',
      });

      expect(event, isA<SseToolResultEvent>());
      final result = event as SseToolResultEvent;
      expect(result.toolName, 'generate_video');
      expect(result.success, isTrue);
      expect(result.output, contains('job_1'));
      expect(result.callId, 'run_9');
    });

    test('fromJson parses a failed tool result', () {
      final event = SseEvent.fromJson(const {
        'event': 'toolResult',
        'toolName': 'generate_video',
        'success': false,
        'output': '{"success": false, "error": "insufficient_kiduna"}',
      }) as SseToolResultEvent;

      expect(event.success, isFalse);
      expect(event.output, contains('insufficient_kiduna'));
    });

    test('fromJson defaults success to true when the field is absent', () {
      final event = SseEvent.fromJson(const {
        'event': 'toolResult',
        'toolName': 'other_tool',
      }) as SseToolResultEvent;

      expect(event.success, isTrue);
      expect(event.output, '');
      expect(event.callId, '');
    });

    test('toString names the tool', () {
      const event = SseToolResultEvent(
        toolName: 'generate_video',
        success: true,
        output: '',
      );
      expect(event.toString(), contains('generate_video'));
    });
  });
}
