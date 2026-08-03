import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/data/models/ally_agent_model.dart';

/// AllyService integration tests require a running backend and Dio setup.
/// These tests validate the response shape the service parses — the same
/// JSON that AllyService.fetchAlly() receives from `GET /api/agents/ally`.
void main() {
  group('AllyAgentModel response parsing', () {
    test('parses the standard backend response', () {
      const json = {
        'id': 'agent_TU1ybVxi',
        'name': 'Ki',
        'handle': 'ki',
        'type': 'PRESENCE',
        'status': 'ACTIVE',
        'description':
            'Ki is your companion inside Kiduna — a presence that knows who you are.',
        'tagline': 'Your companion in Kiduna',
        'accessLevel': 'PUBLIC',
        'tone': 'WISE',
        'presenceSubtype': 'ALLY',
        'systemPrompt': 'You are Ki, the companion presence inside Kiduna.',
        'knowledgeBaseIds': <dynamic>[],
        'tools': <dynamic>[],
        'skillIds': <dynamic>[],
        'templateIds': <dynamic>[],
        'isPrimaryMember': false,
        'isAlly': true,
        'wallet': 'SYSTEM',
        'createdAt': '2026-07-31T10:45:30.947738',
        'updatedAt': '2026-07-31T10:45:30.947738',
      };

      final ally = AllyAgentModel.fromJson(json);

      expect(ally.id, 'agent_TU1ybVxi');
      expect(ally.name, 'Ki');
      expect(ally.handle, 'ki');
      expect(ally.isAlly, isTrue);
      expect(ally.status, 'ACTIVE');
      expect(ally.wallet, 'SYSTEM');
      expect(ally.tone, 'WISE');
      expect(ally.presenceSubtype, 'ALLY');
    });

    test('handles minimal response with only required fields', () {
      const json = {'id': 'agent_min', 'name': 'Test', 'isAlly': true};

      final ally = AllyAgentModel.fromJson(json);

      expect(ally.id, 'agent_min');
      expect(ally.name, 'Test');
      expect(ally.handle, '');
      expect(ally.description, '');
      expect(ally.tagline, '');
      expect(ally.wallet, '');
      expect(ally.status, '');
      expect(ally.isAlly, isTrue);
    });

    test('ignores unknown keys in the response', () {
      const json = {
        'id': 'agent_1',
        'name': 'Ki',
        'handle': 'ki',
        'isAlly': true,
        'unknownField': 'ignored',
        'anotherUnknown': 42,
      };

      final ally = AllyAgentModel.fromJson(json);

      expect(ally.id, 'agent_1');
      expect(ally.name, 'Ki');
    });
  });
}
