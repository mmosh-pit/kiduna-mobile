import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/data/models/chat_message_model.dart';

void main() {
  const json = {
    'id': 'msg_1',
    'role': 'user',
    'content': 'Hello Ki',
    'timestamp': '2026-07-31T10:45:30',
  };

  test('fromJson parses all fields', () {
    final message = ChatMessageModel.fromJson(json);
    expect(message.id, 'msg_1');
    expect(message.role, ChatRole.user);
    expect(message.content, 'Hello Ki');
    expect(message.timestamp, '2026-07-31T10:45:30');
    expect(message.status, ChatMessageStatus.complete);
  });

  test('fromJson defaults missing fields', () {
    final message = ChatMessageModel.fromJson(const <String, dynamic>{});
    expect(message.id, '');
    expect(message.role, ChatRole.assistant);
    expect(message.content, '');
    expect(message.timestamp, isNull);
  });

  test('fromJson parses assistant role', () {
    final message = ChatMessageModel.fromJson(const {
      'id': 'msg_2',
      'role': 'assistant',
      'content': 'Hello!',
    });
    expect(message.role, ChatRole.assistant);
  });

  test('fromJson parses system role', () {
    final message = ChatMessageModel.fromJson(const {
      'role': 'system',
      'content': 'System message',
    });
    expect(message.role, ChatRole.system);
  });

  test('fromJson defaults unknown role to assistant', () {
    final message = ChatMessageModel.fromJson(const {
      'role': 'unknown_role',
      'content': 'test',
    });
    expect(message.role, ChatRole.assistant);
  });

  test('toJson produces the expected map', () {
    final message = ChatMessageModel.fromJson(json);
    final output = message.toJson();
    expect(output['id'], 'msg_1');
    expect(output['role'], 'user');
    expect(output['content'], 'Hello Ki');
    expect(output['timestamp'], '2026-07-31T10:45:30');
  });

  test('toJson omits timestamp when null', () {
    final message = ChatMessageModel.fromJson(const {
      'id': 'msg_1',
      'role': 'user',
      'content': 'test',
    });
    final output = message.toJson();
    expect(output.containsKey('timestamp'), isFalse);
  });

  test('round-trip: fromJson(toJson) produces equal objects', () {
    final original = ChatMessageModel.fromJson(json);
    final roundTripped = ChatMessageModel.fromJson(original.toJson());
    expect(roundTripped, equals(original));
  });

  test('copyWith preserves fields', () {
    final message = ChatMessageModel.fromJson(json);
    final updated = message.copyWith(content: 'Updated');
    expect(updated.id, 'msg_1');
    expect(updated.role, ChatRole.user);
    expect(updated.content, 'Updated');
    expect(updated.timestamp, '2026-07-31T10:45:30');
  });

  test('copyWith clearTimestamp sets timestamp to null', () {
    final message = ChatMessageModel.fromJson(json);
    final cleared = message.copyWith(clearTimestamp: true);
    expect(cleared.timestamp, isNull);
  });

  test('copyWith updates status', () {
    final message = ChatMessageModel.fromJson(json);
    final streaming = message.copyWith(status: ChatMessageStatus.streaming);
    expect(streaming.status, ChatMessageStatus.streaming);
  });

  test('equality based on all fields', () {
    final a = ChatMessageModel.fromJson(json);
    final b = ChatMessageModel.fromJson(json);
    expect(a, equals(b));
    expect(a.hashCode, b.hashCode);
  });

  test('inequality when content differs', () {
    final a = ChatMessageModel.fromJson(json);
    final b = a.copyWith(content: 'Different');
    expect(a, isNot(equals(b)));
  });

  test('toString includes id, role, and status', () {
    final message = ChatMessageModel.fromJson(json);
    final str = message.toString();
    expect(str, contains('ChatMessageModel'));
    expect(str, contains('msg_1'));
    expect(str, contains('user'));
    expect(str, contains('complete'));
  });

  group('ChatRole', () {
    test('fromString resolves all valid roles', () {
      expect(ChatRole.fromString('user'), ChatRole.user);
      expect(ChatRole.fromString('assistant'), ChatRole.assistant);
      expect(ChatRole.fromString('system'), ChatRole.system);
      expect(ChatRole.fromString('tool'), ChatRole.tool);
    });

    test('fromString defaults unknown to assistant', () {
      expect(ChatRole.fromString('invalid'), ChatRole.assistant);
    });
  });
}
