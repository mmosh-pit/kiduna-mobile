import 'dart:math' as math;

import '../../../data/models/gravity_model.dart';
import '../game/enamel_tokens.dart';
import 'field_models.dart';

const _kSchemaVersion = '1.0';

const _levelToGravityInt = <String, int>{
  'vital': 5,
  'central': 4,
  'relevant': 3,
  'available': 2,
  'quiet': 1,
};

const _membershipToRole = <String, String>{
  'creator': 'Creator',
  'team_member': 'Organizer',
  'member': 'Member',
};

const _typeToCluster = <String, String>{
  'organization': 'formation',
  'alliance': 'care',
  'institution': 'law',
  'community': 'place',
  'program': 'formation',
  'project': 'formation',
  'relationship': 'care',
  'cell': 'culture',
  'concept': 'culture',
  'ecosystem': 'formation',
  'dyad': 'care',
  'council': 'law',
  'clan': 'care',
};

const _defaultClusters = <Map<String, dynamic>>[
  {
    'id': 'formation',
    'label': 'Formation · work · economy',
    'accent': '#03CCD9',
    'left': 50,
    'top': 50,
    'radiusX': 1,
    'radiusY': 1,
  },
  {
    'id': 'care',
    'label': 'Care · family · relationship',
    'accent': '#CF6F58',
    'left': 50,
    'top': 50,
    'radiusX': 1,
    'radiusY': 1,
  },
  {
    'id': 'place',
    'label': 'Place · ecology · mutual aid',
    'accent': '#8FE6C6',
    'left': 50,
    'top': 50,
    'radiusX': 1,
    'radiusY': 1,
  },
  {
    'id': 'culture',
    'label': 'Culture · play · public imagination',
    'accent': '#9A7DE8',
    'left': 50,
    'top': 50,
    'radiusX': 1,
    'radiusY': 1,
  },
  {
    'id': 'law',
    'label': 'Law · accountable institutions',
    'accent': '#EAAA00',
    'left': 50,
    'top': 50,
    'radiusX': 1,
    'radiusY': 1,
  },
];

int _massFromScore(double score) {
  if (score >= 0.25) return 3;
  if (score >= 0.10) return 2;
  return 1;
}

const _zoneX = <int, (double, double)>{
  5: (28, 72),
  4: (20, 80),
  3: (12, 88),
  2: (8, 92),
  1: (5, 95),
};
const _zoneY = <int, (double, double)>{
  5: (25, 65),
  4: (18, 72),
  3: (12, 82),
  2: (8, 88),
  1: (5, 95),
};
const _exclusionPx = <int, double>{5: 90.0, 4: 65.0, 3: 42.0, 2: 24.0, 1: 12.0};

List<FieldPoint> _spreadPositions(List<int> levels) {
  final rng = math.Random(42);
  final placed = <(FieldPoint, double)>[];
  final result = <FieldPoint>[];

  for (final level in levels) {
    final (xLo, xHi) = _zoneX[level]!;
    final (yLo, yHi) = _zoneY[level]!;
    final exc = _exclusionPx[level]!;
    var gap = exc;

    FieldPoint? pos;
    FieldPoint? bestFallback;
    var bestMinDist = -1.0;

    for (var attempt = 0; attempt < 80; attempt++) {
      final x = xLo + rng.nextDouble() * (xHi - xLo);
      final y = yLo + rng.nextDouble() * (yHi - yLo);
      final candidate = FieldPoint(x, y);

      var ok = true;
      var minDist = double.infinity;
      for (final (p, pExc) in placed) {
        final dx = (candidate.left - p.left) * 12.0;
        final dy = (candidate.top - p.top) * 9.0;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist < gap + pExc) {
          ok = false;
        }
        if (dist < minDist) minDist = dist;
      }
      if (ok) {
        pos = candidate;
        break;
      }
      if (minDist > bestMinDist) {
        bestMinDist = minDist;
        bestFallback = candidate;
      }
      if (attempt == 35) gap *= 0.8;
      if (attempt == 55) gap *= 0.8;
    }

    pos ??=
        bestFallback ??
        FieldPoint(
          xLo + rng.nextDouble() * (xHi - xLo),
          yLo + rng.nextDouble() * (yHi - yLo),
        );
    placed.add((pos, exc));
    result.add(pos);
  }

  return result;
}

FieldSnapshot gravityToSnapshot({
  required GravityResponse gravity,
  required String viewerId,
  required String viewerName,
}) {
  final gravityMap = <String, Gravity>{};
  final rolesMap = <String, Role>{};

  for (final rg in gravity.realms) {
    final level = _levelToGravityInt[rg.level] ?? 1;
    gravityMap[rg.id] = Gravity.of(level);
    final roleLabel = _membershipToRole[rg.membership];
    if (roleLabel != null) {
      rolesMap[rg.id] = Role.parse(roleLabel);
    }
  }

  final sorted = List.of(gravity.realms)
    ..sort((a, b) {
      final la = _levelToGravityInt[a.level] ?? 1;
      final lb = _levelToGravityInt[b.level] ?? 1;
      return lb.compareTo(la);
    });

  final levels = sorted.map((r) => _levelToGravityInt[r.level] ?? 1).toList();
  final positions = _spreadPositions(levels);

  final realms = <Realm>[];
  for (var i = 0; i < sorted.length; i++) {
    final rg = sorted[i];
    final level = _levelToGravityInt[rg.level] ?? 1;
    final pull = Gravity.of(level).pull;
    final pos = positions[i];
    final seed = FieldPoint(
      50.0 + (pos.left - 50.0) / pull,
      50.0 + (pos.top - 50.0) / pull,
    );
    realms.add(
      Realm(
        id: rg.id,
        name: rg.name,
        typeName: rg.type,
        type: RealmType.parse(rg.type),
        clusterId: _typeToCluster[rg.type] ?? 'formation',
        mass: _massFromScore(rg.score),
        fixture: false,
        reason: rg.reason,
        seed: seed,
      ),
    );
  }

  final viewer = Viewer(
    id: viewerId,
    displayName: viewerName,
    gravity: gravityMap,
    roles: rolesMap,
  );

  const ecosystem = EcosystemRef(
    id: 'kinship-duna',
    name: 'Kinship Duna',
    type: 'Ecosystem',
  );

  final clusterCounts = <String, int>{};
  for (final realm in realms) {
    clusterCounts.update(realm.clusterId, (n) => n + 1, ifAbsent: () => 1);
  }
  final clusters = <ClusterDef>[];
  for (final raw in _defaultClusters) {
    final id = raw['id'] as String;
    if ((clusterCounts[id] ?? 0) == 0) continue;
    clusters.add(ClusterDef.fromJson(raw));
  }

  return FieldSnapshot(
    schemaVersion: _kSchemaVersion,
    viewer: viewer,
    ecosystem: ecosystem,
    realms: realms,
    clusters: clusters,
  );
}
