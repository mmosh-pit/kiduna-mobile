import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/features/field/data/design_persona.dart';
import 'package:kiduna_mobile/features/field/data/field_composition.dart';
import 'package:kiduna_mobile/features/field/data/realm_atlas.dart';

FieldComposition _aliceRoot() {
  final realms = visibleChildren('kinship-duna', DesignPersona.alice);
  return fieldCompositionFor('kinship-duna', DesignPersona.alice, realms);
}

void main() {
  test('composition is deterministic for the same input', () {
    final realms = visibleChildren('kinship-duna', DesignPersona.alice);
    final first = fieldCompositionFor(
      'kinship-duna',
      DesignPersona.alice,
      realms,
    );
    final second = fieldCompositionFor(
      'kinship-duna',
      DesignPersona.alice,
      realms,
    );

    String key(FieldPlacement p) =>
        '${p.realm.id}:${p.left}:${p.top}:${p.band}';
    expect(
      first.placements.map(key).toList(),
      second.placements.map(key).toList(),
    );
  });

  test('the Alice root places all visible realms', () {
    expect(_aliceRoot().placements, hasLength(34));
  });

  test("Alice's anchor realm (Dunaversity) is near and role-pulled", () {
    final duna = _aliceRoot().placements.firstWhere(
      (p) => p.realm.id == 'dunaversity',
    );
    expect(duna.band, FieldBand.near);
    expect(duna.rolePull, isTrue);
  });

  test('every placement stays within the field bounds', () {
    for (final placement in _aliceRoot().placements) {
      expect(placement.left, inInclusiveRange(5, 95));
      expect(placement.top, inInclusiveRange(9, 92));
    }
  });

  test('root composition emits a labelled ellipse per cluster', () {
    final composition = _aliceRoot();
    // Alice's top-level realms span all five root clusters.
    expect(composition.clusters, hasLength(5));
    expect(
      composition.clusters.every((c) => c.id != FieldClusterId.branch),
      isTrue,
    );
  });

  test('branch composition holds proposed institutions at the far band', () {
    final realms = visibleChildren('freehold-finance', DesignPersona.alice);
    final composition = fieldCompositionFor(
      'freehold-finance',
      DesignPersona.alice,
      realms,
    );
    final mortgage = composition.placements.firstWhere(
      (p) => p.realm.id == 'freehold-mortgage',
    );
    expect(mortgage.realm.fixture, isTrue);
    expect(mortgage.band, FieldBand.far);
    expect(composition.clusters.single.id, FieldClusterId.branch);
  });
}
