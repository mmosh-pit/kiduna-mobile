import 'dart:math' as math;

import '../game/enamel_tokens.dart';
import 'field_models.dart';

const _ringMultiplier = <DistanceBand, double>{
  DistanceBand.near: 0.62,
  DistanceBand.middle: 0.88,
  DistanceBand.far: 1.10,
};

const _minLeft = 5.0;
const _maxLeft = 95.0;
const _minTop = 9.0;
const _maxTop = 92.0;

double _clamp(double v, double lo, double hi) =>
    math.min(hi, math.max(lo, v));

class Placement {
  const Placement({
    required this.realm,
    required this.cluster,
    required this.gravity,
    required this.band,
    required this.seed,
    required this.position,
    required this.role,
    this.ally,
  });

  final Realm realm;
  final ClusterDef cluster;
  final Gravity gravity;
  final DistanceBand band;
  final FieldPoint seed;
  final FieldPoint position;
  final Role role;
  final Ally? ally;

  String get identityFacts =>
      '${realm.typeName} · ${role.label} · Ally · ${ally?.name ?? 'None stationed'}';

  String get semanticLabel =>
      '${realm.name}. Type: ${realm.typeName}. Your role: ${role.label}. '
      'Ally stationed: ${ally?.name ?? 'None stationed'}. '
      'Select to see its Possible Actions.';
}

enum ConnectorKind { cluster, bridge, currentPath }

class Connector {
  const Connector({required this.from, required this.to, required this.kind});

  final Placement from;
  final Placement to;
  final ConnectorKind kind;

  double get bend {
    if (from.cluster.isBranch) return -5.0;
    return from.cluster.id == to.cluster.id ? 3.5 : 7.0;
  }

  DistanceBand get distance {
    if (from.band == DistanceBand.far || to.band == DistanceBand.far) {
      return DistanceBand.far;
    }
    if (from.band == DistanceBand.middle || to.band == DistanceBand.middle) {
      return DistanceBand.middle;
    }
    return DistanceBand.near;
  }

  Gravity get minGravity =>
      from.gravity.level <= to.gravity.level ? from.gravity : to.gravity;
}

class ResolvedField {
  const ResolvedField({
    required this.placements,
    required this.clusters,
    required this.connectors,
    required this.bridges,
    this.currentPathTarget,
    this.skippedBridges = 0,
  });

  final List<Placement> placements;
  final List<ClusterDef> clusters;
  final List<Connector> connectors;
  final List<Connector> bridges;
  final Placement? currentPathTarget;
  final int skippedBridges;

  bool get isEmpty => placements.isEmpty;

  Placement? byId(String id) {
    for (final p in placements) {
      if (p.realm.id == id) return p;
    }
    return null;
  }
}

FieldPoint deriveSeed({
  required ClusterDef cluster,
  required DistanceBand band,
  required int index,
  required int count,
}) {
  final multiplier = _ringMultiplier[band]!;
  final angle = count <= 1
      ? cluster.startAngle + cluster.arc / 2
      : cluster.startAngle + (cluster.arc * index) / count;

  return FieldPoint(
    _clamp(
      cluster.left + math.cos(angle) * cluster.radiusX * multiplier,
      _minLeft,
      _maxLeft,
    ),
    _clamp(
      cluster.top + math.sin(angle) * cluster.radiusY * multiplier,
      _minTop,
      _maxTop,
    ),
  );
}

FieldPoint applyGravity({
  required ClusterDef cluster,
  required FieldPoint seed,
  required Gravity gravity,
}) =>
    FieldPoint(
      cluster.left + (seed.left - cluster.left) * gravity.pull,
      cluster.top + (seed.top - cluster.top) * gravity.pull,
    );

ResolvedField resolveField(FieldSnapshot snapshot) {
  final clustersById = {for (final c in snapshot.clusters) c.id: c};

  final grouped = <String, Map<DistanceBand, List<Realm>>>{};
  for (final realm in snapshot.realms) {
    if (!clustersById.containsKey(realm.clusterId)) continue;
    final gravity = snapshot.viewer.gravityFor(realm.id);
    grouped
        .putIfAbsent(realm.clusterId, () => {})
        .putIfAbsent(gravity.band, () => [])
        .add(realm);
  }

  final placements = <Placement>[];
  for (final entry in grouped.entries) {
    final cluster = clustersById[entry.key]!;
    for (final bandEntry in entry.value.entries) {
      final band = bandEntry.key;
      final siblings = bandEntry.value;
      for (var i = 0; i < siblings.length; i++) {
        final realm = siblings[i];
        final gravity = snapshot.viewer.gravityFor(realm.id);
        final seed = realm.seed ??
            deriveSeed(
              cluster: cluster,
              band: band,
              index: i,
              count: siblings.length,
            );
        placements.add(
          Placement(
            realm: realm,
            cluster: cluster,
            gravity: gravity,
            band: band,
            seed: seed,
            position:
                applyGravity(cluster: cluster, seed: seed, gravity: gravity),
            role: snapshot.viewer.roleIn(realm.id),
            ally: snapshot.allyById(realm.stationedAllyId),
          ),
        );
      }
    }
  }

  final connectors = <Connector>[];
  final byCluster = <String, List<Placement>>{};
  for (final p in placements) {
    byCluster.putIfAbsent(p.cluster.id, () => []).add(p);
  }
  for (final chain in byCluster.values) {
    for (var i = 1; i < chain.length; i++) {
      connectors.add(
        Connector(
          from: chain[i - 1],
          to: chain[i],
          kind: ConnectorKind.cluster,
        ),
      );
    }
  }

  final index = {for (final p in placements) p.realm.id: p};
  final bridges = <Connector>[];
  var skipped = 0;
  for (final bridge in snapshot.bridges) {
    final from = index[bridge.fromRealmId];
    final to = index[bridge.toRealmId];
    if (from == null || to == null) {
      skipped++;
      continue;
    }
    bridges.add(Connector(from: from, to: to, kind: ConnectorKind.bridge));
  }

  return ResolvedField(
    placements: placements,
    clusters: snapshot.clusters,
    connectors: connectors,
    bridges: bridges,
    currentPathTarget: index[snapshot.currentPathTargetId],
    skippedBridges: skipped,
  );
}
