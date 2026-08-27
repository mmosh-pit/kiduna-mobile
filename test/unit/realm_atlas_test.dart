import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/features/field/data/design_persona.dart';
import 'package:kiduna/features/field/data/realm_atlas.dart';

void main() {
  group('DesignPersona', () {
    test('resolves ids and rejects unknown ones', () {
      expect(DesignPersona.fromId('alice'), DesignPersona.alice);
      expect(DesignPersona.fromId('danny'), DesignPersona.danny);
      expect(DesignPersona.fromId('moto'), isNull);
    });
  });

  group('realmAtlas', () {
    test('the Ecosystem root holds all 34 top-level realms', () {
      expect(realmAtlas['kinship-duna']!.children, hasLength(34));
      expect(realmAtlas['kinship-duna']!.type, AtlasRealmType.ecosystem);
    });

    test('nesting is canonical (parents are fixed)', () {
      expect(realmAtlas['economic-empowerment']!.parent, 'dunaversity');
      expect(realmAtlas['service-alliance']!.parent, 'kinship-duna');
      expect(realmAtlas['freehold-mortgage']!.fixture, isTrue);
    });
  });

  group('visibleChildren', () {
    test('Alice sees every top-level realm', () {
      final visible = visibleChildren('kinship-duna', DesignPersona.alice);
      expect(visible, hasLength(34));
    });

    test('Bob sees only his granted top-level realms', () {
      final visible = visibleChildren('kinship-duna', DesignPersona.bob);
      final ids = visible.map((realm) => realm.id).toSet();
      expect(visible, hasLength(9));
      // Boundary is authoritative absence, not a locked placeholder.
      expect(ids.contains('safeword'), isFalse);
      expect(ids.contains('service-alliance'), isTrue);
    });

    test('unknown realm ids resolve to no children', () {
      expect(visibleChildren('does-not-exist', DesignPersona.alice), isEmpty);
    });
  });

  test('persona relationship lines describe each role', () {
    expect(personaRealmRelationship[DesignPersona.alice], contains('Catalyst'));
    expect(personaRealmRelationship[DesignPersona.danny], contains('Builder'));
  });
}
