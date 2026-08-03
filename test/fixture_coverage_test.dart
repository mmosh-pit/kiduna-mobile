import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **Every schema field must be populated by at least one fixture.**
///
/// A field no fixture exercises is a field nobody has tested. This is the CI
/// check that stops the contract rotting as the dev team extends it: add a
/// property to the schema without adding it to a fixture and the build fails.
///
/// "Populated" means present *and* non-null in at least one place. A field
/// that only ever appears as `null` has not really been exercised.
void main() {
  const fixtureNames = ['alice', 'coverage', 'empty', 'edge'];

  late Map<String, dynamic> schema;
  late List<Map<String, dynamic>> fixtures;

  setUpAll(() {
    schema = jsonDecode(
      File('../contracts/field-snapshot.schema.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    fixtures = [
      for (final n in fixtureNames)
        jsonDecode(File('assets/fixtures/$n-snapshot.json').readAsStringSync())
            as Map<String, dynamic>,
    ];
  });

  List<String> propertiesOf(Map<String, dynamic> node) =>
      ((node['properties'] as Map<String, dynamic>?) ?? {}).keys.toList();

  /// Every object in the fixtures that the given schema node describes.
  List<Map<String, dynamic>> instancesOf(
    String defName,
    List<Map<String, dynamic>> from,
  ) {
    List<Map<String, dynamic>> listAt(Map<String, dynamic> d, String key) =>
        ((d[key] as List<dynamic>?) ?? const [])
            .cast<Map<String, dynamic>>()
            .toList();

    return switch (defName) {
      'snapshot' => from,
      'viewer' => [
          for (final d in from)
            if (d['viewer'] != null) d['viewer'] as Map<String, dynamic>,
        ],
      'realm' => [for (final d in from) ...listAt(d, 'realms')],
      'cluster' => [for (final d in from) ...listAt(d, 'clusters')],
      'ally' => [for (final d in from) ...listAt(d, 'allies')],
      'bridge' => [for (final d in from) ...listAt(d, 'bridges')],
      _ => const [],
    };
  }

  /// Schema properties never populated by any fixture.
  List<String> gapsFor(String defName, List<Map<String, dynamic>> from) {
    final node = defName == 'snapshot'
        ? schema
        : (schema[r'$defs'] as Map<String, dynamic>)[defName]
            as Map<String, dynamic>;
    final instances = instancesOf(defName, from);
    final populated = <String>{
      for (final obj in instances)
        for (final entry in obj.entries)
          if (entry.value != null) entry.key,
    };
    return propertiesOf(node).where((p) => !populated.contains(p)).toList();
  }

  const defs = ['snapshot', 'viewer', 'realm', 'cluster', 'ally', 'bridge'];

  group('every schema field is exercised', () {
    for (final def in defs) {
      test('$def has no unexercised properties', () {
        final gaps = gapsFor(def, fixtures);
        expect(
          gaps,
          isEmpty,
          reason: 'These $def properties are declared in the schema but never '
              'populated by any fixture: ${gaps.join(', ')}. Add them to '
              'coverage-snapshot.json.',
        );
      });
    }
  });

  group('the coverage check has teeth', () {
    test('removing a field from every fixture is detected', () {
      final stripped = [
        for (final d in fixtures)
          {
            ...d,
            'realms': [
              for (final r in (d['realms'] as List<dynamic>))
                {...(r as Map<String, dynamic>)}..remove('motif'),
            ],
          },
      ];
      expect(
        gapsFor('realm', stripped),
        contains('motif'),
        reason: 'If this passes, the coverage check is not actually checking.',
      );
    });

    test('nulling a field everywhere counts as unexercised', () {
      final nulled = [
        for (final d in fixtures)
          {
            ...d,
            'realms': [
              for (final r in (d['realms'] as List<dynamic>))
                {...(r as Map<String, dynamic>), 'portrait': null},
            ],
          },
      ];
      expect(gapsFor('realm', nulled), contains('portrait'));
    });
  });

  group('every enum value is exercised', () {
    List<dynamic> allRealms() =>
        [for (final d in fixtures) ...(d['realms'] as List<dynamic>)];

    void expectCoversEnum(String label, Set<Object> want, Set<Object> got) {
      final missing = want.difference(got);
      expect(
        missing,
        isEmpty,
        reason: '$label values never exercised by any fixture: $missing',
      );
    }

    test('all 7 Realm types', () {
      expectCoversEnum(
        'RealmType',
        {
          'Ecosystem',
          'Organization',
          'Alliance',
          'Community',
          'Program',
          'Project',
          'Institution',
        },
        {for (final r in allRealms()) r['type'] as Object},
      );
    });

    test('all 6 known clusters', () {
      // clusterId is deliberately an open string, not an enum: clusters ARISE
      // from parentage and working relationships, so an Ecosystem with twenty
      // groupings has twenty clusters. The six below are Kinship Duna's
      // primary set, and the fixtures must still exercise every one.
      expectCoversEnum(
        'clusterId',
        {'formation', 'care', 'place', 'culture', 'law', 'branch'},
        {for (final r in allRealms()) r['clusterId'] as Object},
      );
    });

    test('all 8 roles', () {
      final want = ((schema[r'$defs'] as Map<String, dynamic>)['role']
          as Map<String, dynamic>)['enum'] as List<dynamic>;
      expectCoversEnum(
        'Role',
        want.cast<Object>().toSet(),
        {
          for (final d in fixtures)
            ...(d['viewer']['roles'] as Map<String, dynamic>).values.cast<Object>(),
        },
      );
    });

    test('all 5 Gravity levels, including Available', () {
      expectCoversEnum(
        'Gravity',
        {1, 2, 3, 4, 5},
        {
          for (final d in fixtures)
            ...(d['viewer']['gravity'] as Map<String, dynamic>)
                .values
                .cast<Object>(),
        },
      );
    });

    test('all 4 Ally states', () {
      final want = ((schema[r'$defs'] as Map<String, dynamic>)['allyState']
          as Map<String, dynamic>)['enum'] as List<dynamic>;
      expectCoversEnum(
        'AllyState',
        want.cast<Object>().toSet(),
        {
          for (final d in fixtures)
            ...((d['allies'] as List<dynamic>?) ?? const [])
                .map((a) => a['state'] as Object),
        },
      );
    });

    test('all 3 mass levels', () {
      expectCoversEnum(
        'mass',
        {1, 2, 3},
        {for (final r in allRealms()) r['mass'] as Object},
      );
    });

    test('fixture true and false', () {
      expectCoversEnum(
        'fixture',
        {true, false},
        {for (final r in allRealms()) r['fixture'] as Object},
      );
    });
  });

  group('the audited gaps are closed', () {
    test('at least one Ally is stationed somewhere', () {
      final stationed = [
        for (final d in fixtures)
          for (final r in (d['realms'] as List<dynamic>))
            if (r['stationedAllyId'] != null) r['stationedAllyId'],
      ];
      expect(
        stationed,
        isNotEmpty,
        reason: 'The live AEV stations none — coverage-snapshot must.',
      );
    });

    test('a Realm without a seed exists, so derivation is exercised', () {
      final seedless = [
        for (final d in fixtures)
          for (final r in (d['realms'] as List<dynamic>))
            if (!(r as Map<String, dynamic>).containsKey('seed')) r['id'],
      ];
      expect(seedless, isNotEmpty);
    });

    test('an unrecognised Realm type exists', () {
      const known = {
        'Ecosystem',
        'Organization',
        'Alliance',
        'Community',
        'Program',
        'Project',
        'Institution',
      };
      final unknown = [
        for (final d in fixtures)
          for (final r in (d['realms'] as List<dynamic>))
            if (!known.contains(r['type'])) r['type'],
      ];
      expect(unknown, isNotEmpty);
    });
  });
}
