import 'dart:io';
import 'dart:ui' show Color;

import 'package:aev_flutter/design/tokens.dart';
import 'package:aev_flutter/field/mock_source.dart';
import 'package:aev_flutter/field/models.dart';
import 'package:aev_flutter/field/placement.dart';
import 'package:flutter_test/flutter_test.dart';

FieldSnapshot load(String name) =>
    parseSnapshot(File('assets/fixtures/$name-snapshot.json').readAsStringSync());

void main() {
  group('Alice — the visual acceptance reference', () {
    late ResolvedField field;

    setUpAll(() => field = resolveField(load('alice')));

    test('resolves all 34 top-level Realms', () {
      expect(field.placements, hasLength(34));
    });

    test('cluster distribution matches the live page', () {
      final counts = <String, int>{};
      for (final p in field.placements) {
        counts[p.cluster.id] = (counts[p.cluster.id] ?? 0) + 1;
      }
      expect(counts, {
        'formation': 10,
        'care': 7,
        'place': 7,
        'culture': 9,
        'law': 1,
      });
    });

    test('band distribution is 11 near, 21 middle, 2 far', () {
      final counts = <DistanceBand, int>{};
      for (final p in field.placements) {
        counts[p.band] = (counts[p.band] ?? 0) + 1;
      }
      expect(counts[DistanceBand.near], 11);
      expect(counts[DistanceBand.middle], 21);
      expect(counts[DistanceBand.far], 2);
    });

    test('every position stays inside the Field bounds', () {
      for (final p in field.placements) {
        expect(p.position.left, inInclusiveRange(0, 100), reason: p.realm.id);
        expect(p.position.top, inInclusiveRange(0, 100), reason: p.realm.id);
      }
    });

    test('Dunaversity is Vital and therefore near', () {
      final duna = field.byId('dunaversity')!;
      expect(duna.gravity, Gravity.vital);
      expect(duna.band, DistanceBand.near);
    });

    test('the current path targets the Vital Realm', () {
      expect(field.currentPathTarget?.realm.id, 'dunaversity');
    });

    test('all five bridges resolve, none skipped', () {
      expect(field.bridges, hasLength(5));
      expect(field.skippedBridges, 0);
    });

    test('the single-Realm law cluster draws zero connectors', () {
      final law = field.placements.where((p) => p.cluster.id == 'law');
      expect(law, hasLength(1));
      final lawConnectors = field.connectors
          .where((c) => c.from.cluster.id == 'law')
          .toList();
      expect(lawConnectors, isEmpty,
          reason: 'A chain of one has no links. Correct, not a bug.');
    });

    test('connectors chain within each cluster: n-1 per cluster', () {
      final perCluster = <String, int>{};
      for (final p in field.placements) {
        perCluster[p.cluster.id] = (perCluster[p.cluster.id] ?? 0) + 1;
      }
      final expected =
          perCluster.values.fold(0, (sum, n) => sum + (n > 1 ? n - 1 : 0));
      expect(field.connectors, hasLength(expected));
    });

    test('no Ally is stationed anywhere — the reference fixture stations none',
        () {
      expect(field.placements.every((p) => p.ally == null), isTrue);
      expect(field.placements.first.identityFacts,
          contains('Ally · None stationed'));
    });

    test('Gravity 2 never occurs by default', () {
      expect(
        field.placements.any((p) => p.gravity == Gravity.available),
        isFalse,
        reason: 'Available is reachable only through the Gravity control.',
      );
    });
  });

  group('Gravity drives position, band and fidelity together', () {
    test('raising Gravity pulls a Realm toward its cluster centre', () {
      final snapshot = load('alice');
      final quiet = resolveField(snapshot).byId('kinship-underground')!;

      double distanceFromCentre(Placement p) {
        final dx = p.position.left - p.cluster.left;
        final dy = p.position.top - p.cluster.top;
        return dx * dx + dy * dy;
      }

      final raised = FieldSnapshot(
        schemaVersion: snapshot.schemaVersion,
        viewer: Viewer(
          id: snapshot.viewer.id,
          displayName: snapshot.viewer.displayName,
          roles: snapshot.viewer.roles,
          gravity: {
            ...snapshot.viewer.gravity,
            'kinship-underground': Gravity.vital,
          },
        ),
        ecosystem: snapshot.ecosystem,
        realms: snapshot.realms,
        clusters: snapshot.clusters,
        allies: snapshot.allies,
        bridges: snapshot.bridges,
      );
      final vital = resolveField(raised).byId('kinship-underground')!;

      expect(vital.band, DistanceBand.near,
          reason: 'Gravity 5 promotes far → near');
      expect(quiet.band, DistanceBand.far);
      expect(distanceFromCentre(vital), lessThan(distanceFromCentre(quiet)));
    });

    test('band thresholds are 4+ near, 2+ middle, else far', () {
      expect(Gravity.vital.band, DistanceBand.near);
      expect(Gravity.central.band, DistanceBand.near);
      expect(Gravity.relevant.band, DistanceBand.middle);
      expect(Gravity.available.band, DistanceBand.middle);
      expect(Gravity.quiet.band, DistanceBand.far);
    });

    test('near sits at a smaller ring radius than far', () {
      const cluster = ClusterDef(
        id: 'formation',
        label: '',
        accent: Color(0xFF03CCD9),
        left: 50,
        top: 50,
        radiusX: 30,
        radiusY: 30,
      );
      double radius(DistanceBand band) {
        final seed =
            deriveSeed(cluster: cluster, band: band, index: 0, count: 4);
        final dx = seed.left - cluster.left;
        final dy = seed.top - cluster.top;
        return dx * dx + dy * dy;
      }

      expect(radius(DistanceBand.near), lessThan(radius(DistanceBand.middle)));
      expect(radius(DistanceBand.middle), lessThan(radius(DistanceBand.far)));
    });

    test('a lone Realm sits at the arc midpoint, not its start', () {
      const cluster = ClusterDef(
        id: 'law',
        label: '',
        accent: Color(0xFFEAAA00),
        left: 76,
        top: 29,
        radiusX: 7,
        radiusY: 9,
        startAngle: -1.4,
        arc: 1.2,
      );
      final alone =
          deriveSeed(cluster: cluster, band: DistanceBand.near, index: 0, count: 1);
      final first =
          deriveSeed(cluster: cluster, band: DistanceBand.near, index: 0, count: 4);
      expect(alone.left, isNot(closeTo(first.left, 0.001)));
    });
  });

  group('empty — the newly-created Ecosystem', () {
    test('resolves to nothing without throwing', () {
      final field = resolveField(load('empty'));
      expect(field.isEmpty, isTrue);
      expect(field.connectors, isEmpty);
      expect(field.bridges, isEmpty);
      expect(field.currentPathTarget, isNull);
    });
  });

  group('edge — everything that must degrade rather than throw', () {
    late ResolvedField field;
    late FieldSnapshot snapshot;

    setUpAll(() {
      snapshot = load('edge');
      field = resolveField(snapshot);
    });

    test('an unrecognised Realm type falls back to the conceptual emblem', () {
      final unknown = field.byId('edge-unknown-type')!.realm;
      expect(unknown.type, isNull);
      expect(unknown.isUnknownType, isTrue);
      expect(unknown.typeName, 'Constellation',
          reason: 'the raw name is preserved for display');
      expect(unknown.emblemAsset, RealmType.unknownEmblemAsset);
    });

    test('bridges with a missing endpoint are skipped and counted', () {
      expect(field.bridges, isEmpty);
      expect(field.skippedBridges, 2);
    });

    test('a current path pointing at an invisible Realm resolves to null', () {
      expect(snapshot.currentPathTargetId, 'edge-does-not-exist');
      expect(field.currentPathTarget, isNull);
    });

    test('a Realm with every optional absent still resolves', () {
      final minimal = field.byId('edge-minimal')!;
      expect(minimal.realm.seed, isNull, reason: 'no seed supplied');
      expect(minimal.seed, isNotNull, reason: 'so one is derived');
      expect(minimal.realm.parentId, isNull);
      expect(minimal.realm.purpose, isEmpty);
      expect(minimal.realm.childIds, isEmpty);
      expect(minimal.ally, isNull);
    });

    test('an overlong name is preserved, never truncated in the model', () {
      final long = field.byId('edge-long-name')!.realm;
      expect(long.name.length, greaterThan(100));
    });

    test('the solitary Realm in its cluster produces no connector', () {
      expect(
        field.connectors.where((c) => c.from.cluster.id == 'law'),
        isEmpty,
      );
    });
  });

  group('coverage — every enum exercised', () {
    late ResolvedField field;

    setUpAll(() => field = resolveField(load('coverage')));

    test('all five Gravity levels appear, including Available', () {
      final seen = field.placements.map((p) => p.gravity).toSet();
      expect(seen, containsAll(Gravity.values));
    });

    test('all four Ally states are stationed', () {
      final states = field.placements
          .map((p) => p.ally?.state)
          .whereType<AllyState>()
          .toSet();
      expect(states, containsAll(AllyState.values));
    });

    test('proposed entities are flagged', () {
      expect(field.placements.any((p) => p.realm.fixture), isTrue);
      expect(field.placements.any((p) => !p.realm.fixture), isTrue);
    });

    test('a Realm without a seed still derives one on its ring', () {
      final derived = field.byId('cov-alliance')!;
      expect(derived.realm.seed, isNull);
      expect(derived.seed.left, inInclusiveRange(0, 100));
      expect(derived.seed.top, inInclusiveRange(0, 100));
    });

    test('semantic labels mirror the reference aria-label', () {
      final p = field.byId('cov-ecosystem')!;
      expect(p.semanticLabel, contains('Coverage Ecosystem'));
      expect(p.semanticLabel, contains('Your role: Mage'));
      expect(p.semanticLabel, contains('Ally stationed: Open Ally'));
      expect(p.semanticLabel, contains('Select to see its Possible Actions'));
    });
  });

  group('connector geometry', () {
    test('bend constants: 3.5 same-cluster, 7.0 cross, -5.0 branch', () {
      final field = resolveField(load('coverage'));
      for (final c in field.connectors) {
        expect(c.bend, c.from.cluster.isBranch ? -5.0 : 3.5);
      }
      for (final b in field.bridges) {
        expect(b.bend, b.from.cluster.id == b.to.cluster.id ? 3.5 : 7.0);
      }
    });

    test('a path dims to its dimmest endpoint', () {
      final field = resolveField(load('alice'));
      for (final c in field.connectors) {
        if (c.from.band == DistanceBand.far || c.to.band == DistanceBand.far) {
          expect(c.distance, DistanceBand.far);
        }
      }
    });
  });

  group('schema version', () {
    test('an unsupported major version is refused', () {
      expect(
        () => parseSnapshot(
          '{"schemaVersion":"2.0","viewer":{"id":"x","displayName":"X",'
          '"roles":{},"gravity":{}},"ecosystem":{"id":"e","name":"E"},'
          '"realms":[],"clusters":[]}',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
