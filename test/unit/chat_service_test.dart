import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/data/models/chat_message_model.dart';

/// ChatService integration tests require a running backend and Dio setup.
/// These tests validate the response shapes the service parses — the same
/// JSON that ChatService.fetchHistory() and streamChat() produce.
void main() {
  group('ChatMessageModel response parsing', () {
    test('parses the conversation history response', () {
      const json = {
        'id': 'conv_1',
        'userWallet': 'E3KbfsgoFCt51LeKsSgyZ6GtUbrxkooy2E48TdbGxYUm',
        'presenceId': 'agent_TU1ybVxi',
        'messages': [
          {
            'id': 'msg_1',
            'role': 'user',
            'content': 'Hello Ki',
            'timestamp': '2026-07-31T10:45:30',
          },
          {
            'id': 'msg_2',
            'role': 'assistant',
            'content': 'Hello! How can I help?',
            'timestamp': '2026-07-31T10:45:32',
          },
        ],
        'messageCount': 2,
        'createdAt': '2026-07-31T10:45:30',
        'updatedAt': '2026-07-31T10:45:32',
      };

      final messages = (json['messages']! as List<Map<String, String>>)
          .map(ChatMessageModel.fromJson)
          .toList();

      expect(messages, hasLength(2));
      expect(messages[0].role, ChatRole.user);
      expect(messages[0].content, 'Hello Ki');
      expect(messages[1].role, ChatRole.assistant);
      expect(messages[1].content, 'Hello! How can I help?');
    });

    test('handles empty messages list', () {
      const json = {
        'id': 'conv_2',
        'messages': <Map<String, dynamic>>[],
        'messageCount': 0,
      };

      final messages = (json['messages']! as List<Map<String, dynamic>>)
          .map(ChatMessageModel.fromJson)
          .toList();

      expect(messages, isEmpty);
    });

    test('handles messages with missing optional fields', () {
      const messageJson = {
        'role': 'assistant',
        'content': 'No id or timestamp',
      };

      final message = ChatMessageModel.fromJson(messageJson);

      expect(message.id, '');
      expect(message.role, ChatRole.assistant);
      expect(message.content, 'No id or timestamp');
      expect(message.timestamp, isNull);
    });
  });
}
