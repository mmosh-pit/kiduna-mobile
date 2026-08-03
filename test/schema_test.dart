import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';

/// Every fixture must validate against the published contract. If a fixture
/// and the schema disagree, one of them is wrong — and the dev team inherits
/// whichever we shipped.
void main() {
  const fixtures = ['alice', 'coverage', 'empty', 'edge'];

  late JsonSchema snapshotSchema;
  late JsonSchema eventSchema;

  setUpAll(() {
    snapshotSchema = JsonSchema.create(
      File('../contracts/field-snapshot.schema.json').readAsStringSync(),
      schemaVersion: SchemaVersion.draft2020_12,
    );
    eventSchema = JsonSchema.create(
      File('../contracts/field-event.schema.json').readAsStringSync(),
      schemaVersion: SchemaVersion.draft2020_12,
    );
  });

  group('field-snapshot.schema.json', () {
    for (final name in fixtures) {
      test('$name-snapshot.json validates', () {
        final data = jsonDecode(
          File('assets/fixtures/$name-snapshot.json').readAsStringSync(),
        );
        final result = snapshotSchema.validate(data);
        expect(
          result.isValid,
          isTrue,
          reason: result.errors.map((e) => e.toString()).join('\n'),
        );
      });
    }

    test('a Realm missing a required field is rejected', () {
      final result = snapshotSchema.validate({
        'schemaVersion': '1.0',
        'viewer': {
          'id': 'x',
          'displayName': 'X',
          'roles': <String, dynamic>{},
          'gravity': <String, dynamic>{},
        },
        'ecosystem': {'id': 'e', 'name': 'E'},
        'realms': [
          {'id': 'r', 'name': 'R', 'type': 'Community'}, // no clusterId/mass
        ],
        'clusters': <dynamic>[],
        'bridges': <dynamic>[],
      });
      expect(result.isValid, isFalse);
    });

    test('Gravity outside 1-5 is rejected', () {
      final result = snapshotSchema.validate({
        'schemaVersion': '1.0',
        'viewer': {
          'id': 'x',
          'displayName': 'X',
          'roles': <String, dynamic>{},
          'gravity': {'r': 9},
        },
        'ecosystem': {'id': 'e', 'name': 'E'},
        'realms': <dynamic>[],
        'clusters': <dynamic>[],
        'bridges': <dynamic>[],
      });
      expect(result.isValid, isFalse);
    });

    test('an unknown Realm type is ACCEPTED — forward compatibility', () {
      final data = jsonDecode(
        File('assets/fixtures/edge-snapshot.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final types = (data['realms'] as List)
          .map((r) => (r as Map<String, dynamic>)['type'])
          .toList();
      expect(types, contains('Constellation'));
      expect(
        snapshotSchema.validate(data).isValid,
        isTrue,
        reason: 'Realm.type is deliberately not an enum: a server adding a '
            'type must not become a breaking change.',
      );
    });
  });

  group('field-event.schema.json', () {
    final now = DateTime.utc(2026, 8, 2, 12).toIso8601String();

    final valid = <String, Map<String, dynamic>>{
      'RealmSelected': {'type': 'RealmSelected', 'realmId': 'r', 'at': now},
      'RealmDeselected': {'type': 'RealmDeselected', 'at': now},
      'RealmActivated': {'type': 'RealmActivated', 'realmId': 'r', 'at': now},
      'GravityChanged': {
        'type': 'GravityChanged',
        'realmId': 'r',
        'from': 1,
        'to': 5,
        'at': now,
      },
      'CameraChanged': {
        'type': 'CameraChanged',
        'x': 0.0,
        'y': 0.0,
        'zoom': 1.0,
        'at': now,
      },
      'FieldFocusChanged': {
        'type': 'FieldFocusChanged',
        'dimmed': true,
        'at': now,
      },
    };

    for (final entry in valid.entries) {
      test('${entry.key} validates', () {
        final result = eventSchema.validate(entry.value);
        expect(
          result.isValid,
          isTrue,
          reason: result.errors.map((e) => e.toString()).join('\n'),
        );
      });
    }

    test('RealmEntered is NOT a valid event', () {
      final result = eventSchema.validate({
        'type': 'RealmEntered',
        'realmId': 'r',
        'at': now,
      });
      expect(
        result.isValid,
        isFalse,
        reason: 'Entry is a consequential Action this build does not perform. '
            'Its absence from the vocabulary is deliberate.',
      );
    });

    test('zoom outside 0.7-2.4 is rejected', () {
      final result = eventSchema.validate({
        'type': 'CameraChanged',
        'x': 0.0,
        'y': 0.0,
        'zoom': 5.0,
        'at': now,
      });
      expect(result.isValid, isFalse);
    });
  });
}
