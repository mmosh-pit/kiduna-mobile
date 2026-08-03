import 'dart:convert';
import 'dart:io';

import 'package:aev_flutter/design/tokens.dart';
import 'package:aev_flutter/field/events.dart';
import 'package:aev_flutter/field/render/motion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';

/// Every event the Field emits must satisfy the published contract, because
/// the receiving team will build against the schema, not against our Dart.
void main() {
  late JsonSchema schema;
  final at = DateTime.utc(2026, 8, 2, 14, 30);

  setUpAll(() {
    schema = JsonSchema.create(
      File('../contracts/field-event.schema.json').readAsStringSync(),
      schemaVersion: SchemaVersion.draft2020_12,
    );
  });

  void expectValid(FieldEvent event) {
    // Round-trip through JSON so the test sees exactly what a transport would.
    final encoded = jsonDecode(jsonEncode(event.toJson()));
    final result = schema.validate(encoded);
    expect(
      result.isValid,
      isTrue,
      reason: '${event.type}: ${result.errors.map((e) => '$e').join('; ')}',
    );
  }

  group('every emitted event validates against the schema', () {
    test('RealmSelected', () => expectValid(RealmSelected('dunaversity', at)));
    test('RealmDeselected', () => expectValid(RealmDeselected(at)));
    test('RealmActivated', () => expectValid(RealmActivated('agency', at)));
    test('GravityChanged', () {
      expectValid(GravityChanged('agency', Gravity.quiet, Gravity.vital, at));
    });
    test('CameraChanged', () => expectValid(CameraChanged(12, -8, 1.4, at)));
    test('FieldFocusChanged', () => expectValid(FieldFocusChanged(true, at)));
  });

  group('payload shape', () {
    test('GravityChanged carries levels, not enum names', () {
      final json =
          GravityChanged('r', Gravity.available, Gravity.central, at).toJson();
      expect(json['from'], 2);
      expect(json['to'], 4);
    });

    test('timestamps are ISO 8601 UTC', () {
      final json = RealmSelected('r', DateTime.utc(2026, 1, 2, 3, 4, 5)).toJson();
      expect(json['at'], '2026-01-02T03:04:05.000Z');
    });

    test('a local timestamp is normalised to UTC', () {
      final local = DateTime(2026, 5, 5, 12);
      final json = RealmSelected('r', local).toJson();
      expect((json['at'] as String).endsWith('Z'), isTrue);
    });
  });

  group('the vocabulary is deliberately incomplete', () {
    test('there is no RealmEntered event type', () {
      // Entry is a consequential Action with authority, confirmation and
      // recovery boundaries this build does not implement. Its absence is a
      // decision; if this test ever fails, that decision was reversed without
      // the review it needs.
      const names = {
        'RealmSelected',
        'RealmDeselected',
        'RealmActivated',
        'GravityChanged',
        'CameraChanged',
        'FieldFocusChanged',
      };
      final defs = (jsonDecode(
        File('../contracts/field-event.schema.json').readAsStringSync(),
      ) as Map<String, dynamic>)[r'$defs'] as Map<String, dynamic>;

      final declared = <String>{};
      for (final entry in defs.entries) {
        final props = (entry.value as Map<String, dynamic>)['properties']
            as Map<String, dynamic>?;
        final type = props?['type'] as Map<String, dynamic>?;
        if (type?.containsKey('const') ?? false) {
          declared.add(type!['const'] as String);
        }
      }
      expect(declared, names);
      expect(declared, isNot(contains('RealmEntered')));
    });

    test('only GravityChanged is a write; the rest are observation', () {
      final writes = [GravityChanged('r', Gravity.quiet, Gravity.vital, at)];
      final observations = [
        RealmSelected('r', at),
        RealmDeselected(at),
        RealmActivated('r', at),
        CameraChanged(0, 0, 1, at),
        FieldFocusChanged(false, at),
      ];
      expect(writes, hasLength(1));
      expect(observations.every((e) => e is! GravityChanged), isTrue);
    });
  });

  group('Gather easing', () {
    test('cubic-bezier(.2,.7,.2,1) starts at 0 and lands on 1', () {
      expect(Verb.gather(0), 0);
      expect(Verb.gather(1), 1);
    });

    test('it front-loads, as the reference curve does', () {
      // With a y2 control at .7 the curve is well past halfway by t = 0.4.
      expect(Verb.gather(0.4), greaterThan(0.5));
    });

    test('it is monotonic — position never reverses mid-Gather', () {
      var previous = -1.0;
      for (var i = 0; i <= 200; i++) {
        final v = Verb.gather(i / 200);
        expect(v, greaterThanOrEqualTo(previous - 1e-9));
        previous = v;
      }
    });

    test('it never overshoots into a cartoon bounce', () {
      for (var i = 0; i <= 200; i++) {
        expect(Verb.gather(i / 200), inInclusiveRange(0, 1));
      }
    });
  });
}
