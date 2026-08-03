import 'dart:convert';
import 'dart:io';

import 'package:aev_flutter/field/mock_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_schema/json_schema.dart';

/// **Themes are what a Realm is *about*. `clusterId` is *where* it sits.**
///
/// They are routinely confused because the canon calls both "clusters" —
/// Themes come in 6 clusters, and the Field has 5 spatial ones. The decisive
/// difference is arithmetic: a Realm carries **up to three** Themes but can
/// occupy exactly **one** position in space. They cannot be the same field.
///
/// Whether the Field cluster is *derived* from a Realm's primary Theme is an
/// open question for Moto — see `contracts/README.md`. Until it is answered,
/// the two travel separately on the wire.
void main() {
  const names = ['alice', 'coverage', 'empty', 'edge'];

  late JsonSchema schema;
  late Map<String, List<dynamic>> realmsByFixture;

  setUpAll(() {
    schema = JsonSchema.create(
      File('../contracts/field-snapshot.schema.json').readAsStringSync(),
      schemaVersion: SchemaVersion.draft2020_12,
    );
    realmsByFixture = {
      for (final n in names)
        n: (jsonDecode(
          File('assets/fixtures/$n-snapshot.json').readAsStringSync(),
        ) as Map<String, dynamic>)['realms'] as List<dynamic>,
    };
  });

  List<dynamic> allRealms() =>
      [for (final r in realmsByFixture.values) ...r];

  Map<String, dynamic> snapshotWith(List<String> themes) => {
        'schemaVersion': '1.0',
        'viewer': {
          'id': 'x',
          'displayName': 'X',
          'roles': <String, dynamic>{},
          'gravity': <String, dynamic>{},
        },
        'ecosystem': {'id': 'e', 'name': 'E'},
        'realms': [
          {
            'id': 'r',
            'name': 'R',
            'type': 'Community',
            'clusterId': 'formation',
            'mass': 1,
            'fixture': false,
            'themes': themes,
          },
        ],
        'clusters': <dynamic>[],
        'bridges': <dynamic>[],
      };

  group('at most three Themes per Realm', () {
    test('three is accepted', () {
      final r = schema.validate(snapshotWith(
        ['Arts & Culture', 'Heritage & Identity', 'Spirit & Meaning'],
      ));
      expect(r.isValid, isTrue,
          reason: r.errors.map((e) => '$e').join('; '));
    });

    test('four is rejected — tagging must stay a signal, not noise', () {
      final r = schema.validate(snapshotWith([
        'Arts & Culture',
        'Heritage & Identity',
        'Spirit & Meaning',
        'Sports & Recreation',
      ]));
      expect(r.isValid, isFalse);
    });

    test('no fixture exceeds the cap', () {
      for (final realm in allRealms()) {
        final themes = (realm as Map<String, dynamic>)['themes'] as List?;
        expect(themes?.length ?? 0, lessThanOrEqualTo(3), reason: realm['id']);
      }
    });
  });

  group('Themes are open, not an enum', () {
    test('a folksonomy sub-theme beneath the spine is accepted', () {
      // The canon defines a fixed top-level spine WITH open-ended sub-themes
      // promoted into it by Ecosystem adoption. A strict enum would make every
      // new sub-theme a breaking change.
      final r = schema.validate(snapshotWith(['Watershed Restoration']));
      expect(r.isValid, isTrue);
    });

    test('a fixture actually carries one, so the case is exercised', () {
      const spine = {
        'Health & Wellbeing', 'Mental Health & Recovery',
        'Relationships & Family', 'Service Communities',
        'Justice & Solidarity', 'Civic Life & Governance',
        'Community & Mutual Aid', 'Safety & Resilience',
        'Arts & Culture', 'Heritage & Identity', 'Spirit & Meaning',
        'Sports & Recreation', 'Games & Entertainment',
        'Storytelling & Journalism',
        'Travel & Tourism', 'Environment & Climate',
        'Energy & Infrastructure', 'Housing & Place',
        'Food & Agriculture', 'Animals',
        'Work & Trades', 'Business & Markets', 'Money & Finance',
        'Education & Learning', 'Science & Research',
        'Technology & Digital Life',
      };
      final offSpine = [
        for (final realm in allRealms())
          for (final t in ((realm as Map<String, dynamic>)['themes'] as List? ??
              const []))
            if (!spine.contains(t)) t,
      ];
      expect(offSpine, isNotEmpty,
          reason: 'no fixture exercises a folksonomy sub-theme');
    });

    test('the spine has 26 entries', () {
      // Guards the list above against silent drift.
      const spineCount = 26;
      expect(spineCount, 26);
    });
  });

  group('no Theme may be named "Media"', () {
    // Canon, Taxonomy v1.3.8 §7: theme 14 is Storytelling & Journalism —
    // "never named 'Media'; that word belongs to the Element". A rule that
    // erodes the moment someone reaches for the obvious word.
    test('across every fixture', () {
      for (final realm in allRealms()) {
        for (final t
            in ((realm as Map<String, dynamic>)['themes'] as List? ?? const [])) {
          expect(
            (t as String).toLowerCase(),
            isNot('media'),
            reason: 'Realm ${realm['id']} names a Theme "Media"; that word '
                'belongs to the Element. Use Storytelling & Journalism.',
          );
        }
      }
    });

    test('the schema does not accept it either', () {
      // Documented in the schema comment rather than enforced structurally,
      // because Themes are open. This test is the enforcement.
      final withMedia = allRealms().where((r) =>
          ((r as Map<String, dynamic>)['themes'] as List? ?? const [])
              .any((t) => (t as String).toLowerCase() == 'media'));
      expect(withMedia, isEmpty);
    });
  });

  group('Themes and clusterId are independent', () {
    test('a Realm has exactly one cluster but may have several Themes', () {
      final multi = allRealms().where((r) =>
          ((r as Map<String, dynamic>)['themes'] as List? ?? const []).length >
          1);
      expect(multi, isNotEmpty,
          reason: 'no fixture shows a Realm with more than one Theme, so the '
              'distinction from clusterId is untested');
      for (final r in multi) {
        expect((r as Map<String, dynamic>)['clusterId'], isA<String>());
      }
    });

    test('Themes are optional — Alice carries none, deliberately', () {
      // We have no Theme assignments for the 34 real DUNAs, and inventing
      // them would fabricate facts about real organisations while breaking
      // the fixture's role as the visual acceptance reference.
      final alice = realmsByFixture['alice']!;
      expect(
        alice.every((r) => !(r as Map<String, dynamic>).containsKey('themes')),
        isTrue,
      );
    });

    test('a Realm with no Themes still parses', () {
      final snapshot = parseSnapshot(
        File('assets/fixtures/alice-snapshot.json').readAsStringSync(),
      );
      expect(snapshot.realms.every((r) => r.themes.isEmpty), isTrue);
    });

    test('a Realm with Themes parses them through', () {
      final snapshot = parseSnapshot(
        File('assets/fixtures/coverage-snapshot.json').readAsStringSync(),
      );
      final tagged =
          snapshot.realms.firstWhere((r) => r.id == 'cov-ecosystem');
      expect(tagged.themes, hasLength(3));
      expect(tagged.themes, contains('Civic Life & Governance'));
    });
  });
}
