import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/features/ki_chat/controllers/ki_chat_controller.dart';

/// The backend has shipped `toolResult.output` both as raw JSON and as a
/// stringified LangChain ToolMessage. Both must decode, or a generated video
/// silently never reaches the chat.
void main() {
  test('decodes raw JSON output', () {
    final r = KiChatController.decodeToolPayload(
      '{"success": true, "job_id": "abc", "status": "generating"}',
    );
    expect(r, isNotNull);
    expect(r!['success'], isTrue);
    expect(r['job_id'], 'abc');
  });

  test('decodes a stringified ToolMessage wrapper', () {
    const wrapped =
        "content='{\"success\": true, \"job_id\": \"8504a3dd\", "
        "\"duration_seconds\": 8}' name='generate_video' "
        "tool_call_id='call_eUT5yOT7'";
    final r = KiChatController.decodeToolPayload(wrapped);
    expect(r, isNotNull);
    expect(r!['job_id'], '8504a3dd');
    expect(r['duration_seconds'], 8);
  });

  test('decodes a failure payload from a wrapper', () {
    const wrapped =
        "content='{\"success\": false, \"error\": \"insufficient_kiduna\"}' "
        "name='generate_video'";
    final r = KiChatController.decodeToolPayload(wrapped);
    expect(r, isNotNull);
    expect(r!['success'], isFalse);
    expect(r['error'], 'insufficient_kiduna');
  });

  test('ignores braces inside string values', () {
    final r = KiChatController.decodeToolPayload(
      '{"prompt": "a {weird} prompt", "job_id": "x"}',
    );
    expect(r, isNotNull);
    expect(r!['prompt'], 'a {weird} prompt');
    expect(r['job_id'], 'x');
  });

  test('returns null on empty or object-free output', () {
    expect(KiChatController.decodeToolPayload(''), isNull);
    expect(KiChatController.decodeToolPayload('   '), isNull);
    expect(KiChatController.decodeToolPayload('no json here'), isNull);
  });

  test('returns null on a truncated object', () {
    expect(
      KiChatController.decodeToolPayload('{"job_id": "abc", "status":'),
      isNull,
    );
  });
}
