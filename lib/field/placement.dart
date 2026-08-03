/// Turns a [FieldSnapshot] into positioned, banded Realms.
///
/// This is the *only* place geometry is derived. The source sends meaning —
/// which cluster, what Gravity, who is viewing — and everything spatial is
/// computed here, so there is exactly one implementation of what relevance
/// looks like.
///
/// Ported from `lib/field-composition.ts` in Studio Design Kit v1.7.
/// Pure Dart: no Flutter, no rendering, no side effects.
library;

import 'dart:math' as math;

import '../design/tokens.dart';
import 'models.dart';

/// Ring radius multiplier per band.
///
/// Near sits at the *smallest* radius — nearest the cluster centre. Distance
/// from centre is the encoding of relevance, so a near Realm is literally
/// closer in.
const _ringMultiplier = <DistanceBand, double>{
  DistanceBand.near: 0.62,
  DistanceBand.middle: 0.88,
  DistanceBand.far: 1.10,
};

/// Field bounds, in percent. Realms never touch the viewport edge.
const _minLeft = 5.0;
const _maxLeft = 95.0;
const _minTop = 9.0;
const _maxTop = 92.0;

double _clamp(double v, double lo, double hi) => math.min(hi, math.max(lo, v));

/// A Realm resolved to a place in the Field.
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

  /// The single source of relevance: drives [band], [position] and fidelity.
  final Gravity gravity;
  final DistanceBand band;

  /// Pre-Gravity anchor, percent. Either supplied by the snapshot or derived.
  final FieldPoint seed;

  /// Post-Gravity position, percent. What actually gets drawn.
  final FieldPoint position;

  final Role role;

  /// Resolved from `stationedAllyId`. `null` reads as "Ally · None stationed".
  final Ally? ally;

  /// The line shown on hover, mirroring the reference's identity facts.
  String get identityFacts =>
      '${realm.typeName} · ${role.label} · Ally · ${ally?.name ?? 'None stationed'}';

  /// The accessible label, mirroring the reference's `aria-label`.
  String get semanticLabel =>
      '${realm.name}. Type: ${realm.typeName}. Your role: ${role.label}. '
      'Ally stationed: ${ally?.name ?? 'None stationed'}. '
      'Select to see its Possible Actions.';
}

enum ConnectorKind {
  /// Within a cluster. Chained, coloured by the cluster accent.
  cluster,

  /// Across clusters. Quieter and visually distinct.
  bridge,

  /// Gold, to the viewer's Vital Realm. Subordinate to Realm identity.
  currentPath,
}

/// A drawn relationship. Never decorative — every connector has a real
/// relationship behind it.
class Connector {
  const Connector({required this.from, required this.to, required this.kind});

  final Placement from;
  final Placement to;
  final ConnectorKind kind;

  /// Quadratic Bézier control-point offset, per the reference.
  ///
  /// `3.5` within a cluster · `7.0` across clusters · `-5.0` for branch.
  double get bend {
    if (from.cluster.isBranch) return -5.0;
    return from.cluster.id == to.cluster.id ? 3.5 : 7.0;
  }

  /// The dimmest endpoint governs, so a path fades with whatever it connects.
  DistanceBand get distance {
    if (from.band == DistanceBand.far || to.band == DistanceBand.far) {
      return DistanceBand.far;
    }
    if (from.band == DistanceBand.middle || to.band == DistanceBand.middle) {
      return DistanceBand.middle;
    }
    return DistanceBand.near;
  }
}

/// A snapshot resolved into everything the renderer needs.
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

  /// Within-cluster chains.
  final List<Connector> connectors;

  /// Cross-cluster bridges whose endpoints are both visible.
  final List<Connector> bridges;

  /// `null` when no current path is declared, or its target is not visible.
  final Placement? currentPathTarget;

  /// Bridges dropped because an endpoint was not visible to this viewer.
  /// Reported rather than silently swallowed.
  final int skippedBridges;

  bool get isEmpty => placements.isEmpty;

  Placement? byId(String id) {
    for (final p in placements) {
      if (p.realm.id == id) return p;
    }
    return null;
  }
}

/// Derives a seed position on the cluster's elliptical ring.
///
/// [index] is the Realm's position among its same-band siblings and [count] is
/// how many there are. A lone Realm sits at the midpoint of the arc rather
/// than at its start.
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

/// Applies Gravity's pull toward the cluster centre.
///
/// Higher Gravity means a smaller multiplier, so the Realm is drawn further in.
/// Gravity 1 (Quiet) uses 1.12 and pushes slightly outward.
FieldPoint applyGravity({
  required ClusterDef cluster,
  required FieldPoint seed,
  required Gravity gravity,
}) =>
    FieldPoint(
      cluster.left + (seed.left - cluster.left) * gravity.pull,
      cluster.top + (seed.top - cluster.top) * gravity.pull,
    );

/// Resolves a snapshot into placements, connectors and bridges.
ResolvedField resolveField(FieldSnapshot snapshot) {
  final clustersById = {for (final c in snapshot.clusters) c.id: c};

  // Group by cluster, then by band, preserving snapshot order so ring indices
  // are stable across reloads.
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

  // Within-cluster connectors chain from the second placement onward. A
  // cluster holding a single Realm therefore draws none — correct, not a bug.
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

  // A bridge endpoint may be invisible to this viewer. Skip, never fail.
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
