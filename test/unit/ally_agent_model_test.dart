import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/data/models/ally_agent_model.dart';

void main() {
  const json = {
    'id': 'agent_TU1ybVxi',
    'name': 'Ki',
    'handle': 'ki',
    'type': 'PRESENCE',
    'status': 'ACTIVE',
    'description': 'Ki is your companion inside Kiduna.',
    'tagline': 'Your companion in Kiduna',
    'accessLevel': 'PUBLIC',
    'tone': 'WISE',
    'presenceSubtype': 'ALLY',
    'isAlly': true,
    'wallet': 'SYSTEM',
  };

  test('fromJson parses all fields', () {
    final ally = AllyAgentModel.fromJson(json);
    expect(ally.id, 'agent_TU1ybVxi');
    expect(ally.name, 'Ki');
    expect(ally.handle, 'ki');
    expect(ally.status, 'ACTIVE');
    expect(ally.description, 'Ki is your companion inside Kiduna.');
    expect(ally.tagline, 'Your companion in Kiduna');
    expect(ally.wallet, 'SYSTEM');
    expect(ally.isAlly, isTrue);
    expect(ally.tone, 'WISE');
    expect(ally.accessLevel, 'PUBLIC');
    expect(ally.presenceSubtype, 'ALLY');
  });

  test('fromJson defaults missing optional fields', () {
    final ally = AllyAgentModel.fromJson(const {
      'id': 'agent_1',
      'name': 'Test',
      'handle': 'test',
      'description': 'desc',
      'tagline': 'tag',
      'wallet': 'W',
      'status': 'ACTIVE',
      'isAlly': true,
    });
    expect(ally.tone, '');
    expect(ally.accessLevel, '');
    expect(ally.presenceSubtype, '');
    expect(ally.knowledgeBaseIds, isEmpty);
  });

  test('fromJson parses knowledgeBaseIds', () {
    final ally = AllyAgentModel.fromJson(const {
      'id': 'agent_1',
      'name': 'Ki',
      'isAlly': true,
      'knowledgeBaseIds': <dynamic>['kb_1', 'kb_2'],
    });
    expect(ally.knowledgeBaseIds, ['kb_1', 'kb_2']);
  });

  test('fromJson defaults missing required fields to empty', () {
    final ally = AllyAgentModel.fromJson(const <String, dynamic>{});
    expect(ally.id, '');
    expect(ally.name, '');
    expect(ally.handle, '');
    expect(ally.isAlly, isFalse);
  });

  test('toJson produces the expected map', () {
    final ally = AllyAgentModel.fromJson(json);
    final output = ally.toJson();
    expect(output['id'], 'agent_TU1ybVxi');
    expect(output['name'], 'Ki');
    expect(output['handle'], 'ki');
    expect(output['isAlly'], isTrue);
    expect(output['tone'], 'WISE');
    expect(output['accessLevel'], 'PUBLIC');
    expect(output['presenceSubtype'], 'ALLY');
  });

  test('round-trip: fromJson(toJson) produces equal objects', () {
    final original = AllyAgentModel.fromJson(json);
    final roundTripped = AllyAgentModel.fromJson(original.toJson());
    expect(roundTripped, equals(original));
  });

  test('equality is based on all fields', () {
    final a = AllyAgentModel.fromJson(json);
    final b = AllyAgentModel.fromJson(json);
    expect(a, equals(b));
    expect(a.hashCode, b.hashCode);
  });

  test('inequality when any field differs', () {
    final a = AllyAgentModel.fromJson(json);
    final modified = Map<String, dynamic>.of(json)..['name'] = 'Other';
    final b = AllyAgentModel.fromJson(modified);
    expect(a, isNot(equals(b)));
  });

  test('toString includes id, name, handle, and status', () {
    final ally = AllyAgentModel.fromJson(json);
    final str = ally.toString();
    expect(str, contains('AllyAgentModel'));
    expect(str, contains('agent_TU1ybVxi'));
    expect(str, contains('Ki'));
    expect(str, contains('ki'));
    expect(str, contains('ACTIVE'));
  });
}
