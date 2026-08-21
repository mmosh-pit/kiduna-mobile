import 'dart:math' as math;

import 'design_persona.dart';
import 'realm_atlas.dart';

/// Distance ring a Realm sits in relative to the Source — a Dart port of
/// `field-composition.ts`.
enum FieldBand { near, middle, far }

/// The thematic cluster a Realm belongs to — maps to the 6 canonical Themes
/// from Taxonomy V0.09 plus `branch` for nested child-realm views.
enum FieldClusterId {
  peopleCare,
  societyJustice,
  culturePlay,
  placePlanet,
  workWealth,
  knowledgeFrontier,
  branch,
}

/// A placed Realm: its position (`%` of the field box), band, cluster, and the
/// plain-language reason it is where it is.
class FieldPlacement {
  const FieldPlacement({
    required this.realm,
    required this.left,
    required this.top,
    required this.band,
    required this.cluster,
    required this.mass,
    required this.reason,
    required this.rolePull,
  });

  final AtlasRealm realm;
  final double left;
  final double top;
  final FieldBand band;
  final FieldClusterId cluster;

  /// Visual weight, 1–3.
  final int mass;
  final String reason;
  final bool rolePull;
}

/// A cluster's labelled ellipse in the field.
class FieldCluster {
  const FieldCluster({
    required this.id,
    required this.label,
    required this.left,
    required this.top,
    required this.radiusX,
    required this.radiusY,
  });

  final FieldClusterId id;
  final String label;
  final double left;
  final double top;
  final double radiusX;
  final double radiusY;
}

/// The full composition: placed Realms plus their cluster ellipses.
class FieldComposition {
  const FieldComposition({required this.placements, required this.clusters});

  final List<FieldPlacement> placements;
  final List<FieldCluster> clusters;
}

const Map<FieldClusterId, String> _clusterLabels = {
  FieldClusterId.peopleCare: 'People & Care',
  FieldClusterId.societyJustice: 'Society & Justice',
  FieldClusterId.culturePlay: 'Culture & Play',
  FieldClusterId.placePlanet: 'Place & Planet',
  FieldClusterId.workWealth: 'Work & Wealth',
  FieldClusterId.knowledgeFrontier: 'Knowledge & Frontier',
  FieldClusterId.branch: '',
};

const Map<String, FieldClusterId> _rootCluster = {
  // ── People & Care ──
  'service-alliance': FieldClusterId.peopleCare,
  'bihome': FieldClusterId.peopleCare,
  'soul-kitchen': FieldClusterId.peopleCare,
  'safeword': FieldClusterId.peopleCare,
  'homeworld': FieldClusterId.peopleCare,
  'black-love': FieldClusterId.peopleCare,
  'non-toxic-masculinity': FieldClusterId.peopleCare,
  // ── Society & Justice ──
  'true-democracy': FieldClusterId.societyJustice,
  'contraction': FieldClusterId.societyJustice,
  'global-peace': FieldClusterId.societyJustice,
  'jews-against-homelands': FieldClusterId.societyJustice,
  'mycelial-aid': FieldClusterId.societyJustice,
  'ansanm-ayiti': FieldClusterId.societyJustice,
  'the-long-drum': FieldClusterId.societyJustice,
  // ── Culture & Play ──
  'ceremony-machine': FieldClusterId.culturePlay,
  'fellowship-of-play': FieldClusterId.culturePlay,
  'fanduna': FieldClusterId.culturePlay,
  'party-line': FieldClusterId.culturePlay,
  'cosmic-humanity': FieldClusterId.culturePlay,
  'vibe-coast': FieldClusterId.culturePlay,
  'wokelord': FieldClusterId.culturePlay,
  // ── Place & Planet ──
  'confluence-collective': FieldClusterId.placePlanet,
  'mountain-river-trail': FieldClusterId.placePlanet,
  'celebrity-solar': FieldClusterId.placePlanet,
  'indigenous-revival': FieldClusterId.placePlanet,
  // ── Work & Wealth ──
  'agency': FieldClusterId.workWealth,
  'hyphal': FieldClusterId.workWealth,
  'mapshifting': FieldClusterId.workWealth,
  'freehold-finance': FieldClusterId.workWealth,
  'tangential': FieldClusterId.workWealth,
  'kinship-commons': FieldClusterId.workWealth,
  // ── Knowledge & Frontier ──
  'dunaversity': FieldClusterId.knowledgeFrontier,
  'ravensong-labs': FieldClusterId.knowledgeFrontier,
  'kinship-underground': FieldClusterId.knowledgeFrontier,
};

const Map<DesignPersona, List<String>> _foreground = {
  DesignPersona.alice: [
    'dunaversity',
    'kinship-commons',
    'ravensong-labs',
    'agency',
    'hyphal',
    'mapshifting',
    'freehold-finance',
    'tangential',
    'true-democracy',
    'service-alliance',
    'the-long-drum',
  ],
  DesignPersona.bob: [
    'service-alliance',
    'soul-kitchen',
    'mountain-river-trail',
    'confluence-collective',
    'homeworld',
  ],
  DesignPersona.carol: [
    'ceremony-machine',
    'fellowship-of-play',
    'fanduna',
    'party-line',
    'cosmic-humanity',
  ],
  DesignPersona.danny: [
    'confluence-collective',
    'mountain-river-trail',
    'ravensong-labs',
    'dunaversity',
  ],
};

const Map<DesignPersona, List<String>> _middle = {
  DesignPersona.alice: [
    'bihome',
    'soul-kitchen',
    'safeword',
    'homeworld',
    'black-love',
    'non-toxic-masculinity',
    'confluence-collective',
    'mountain-river-trail',
    'celebrity-solar',
    'mycelial-aid',
    'ansanm-ayiti',
    'indigenous-revival',
    'ceremony-machine',
    'fellowship-of-play',
    'fanduna',
    'party-line',
    'cosmic-humanity',
    'vibe-coast',
    'wokelord',
    'global-peace',
    'contraction',
  ],
  DesignPersona.bob: [
    'ansanm-ayiti',
    'mycelial-aid',
    'dunaversity',
    'party-line',
  ],
  DesignPersona.carol: [
    'homeworld',
    'black-love',
    'vibe-coast',
    'dunaversity',
    'wokelord',
  ],
  DesignPersona.danny: [
    'indigenous-revival',
    'mycelial-aid',
    'hyphal',
    'kinship-underground',
  ],
};

const Set<String> _massThree = {
  'dunaversity',
  'kinship-commons',
  'ravensong-labs',
  'service-alliance',
  'confluence-collective',
  'ceremony-machine',
};

const Set<String> _massTwo = {
  'agency',
  'hyphal',
  'freehold-finance',
  'true-democracy',
  'soul-kitchen',
  'homeworld',
  'mountain-river-trail',
  'mycelial-aid',
  'the-long-drum',
  'fellowship-of-play',
  'party-line',
  'cosmic-humanity',
  'contraction',
};

class _ClusterGeometry {
  const _ClusterGeometry({
    required this.left,
    required this.top,
    required this.radiusX,
    required this.radiusY,
    required this.startAngle,
    required this.arc,
  });

  final double left;
  final double top;
  final double radiusX;
  final double radiusY;
  final double startAngle;
  final double arc;
}

const Map<DesignPersona, Map<FieldClusterId, _ClusterGeometry>> _rootGeometry =
    {
      DesignPersona.alice: {
        FieldClusterId.peopleCare: _ClusterGeometry(
          left: 18,
          top: 69,
          radiusX: 15,
          radiusY: 18,
          startAngle: -2.2,
          arc: 4.25,
        ),
        FieldClusterId.societyJustice: _ClusterGeometry(
          left: 76,
          top: 29,
          radiusX: 14,
          radiusY: 14,
          startAngle: -2.6,
          arc: 4.2,
        ),
        FieldClusterId.culturePlay: _ClusterGeometry(
          left: 79,
          top: 63,
          radiusX: 15,
          radiusY: 23,
          startAngle: -2.35,
          arc: 4.45,
        ),
        FieldClusterId.placePlanet: _ClusterGeometry(
          left: 48,
          top: 76,
          radiusX: 20,
          radiusY: 13,
          startAngle: -2.85,
          arc: 4.8,
        ),
        FieldClusterId.workWealth: _ClusterGeometry(
          left: 35,
          top: 38,
          radiusX: 22,
          radiusY: 18,
          startAngle: -2.8,
          arc: 5.0,
        ),
        FieldClusterId.knowledgeFrontier: _ClusterGeometry(
          left: 52,
          top: 30,
          radiusX: 14,
          radiusY: 12,
          startAngle: -2.5,
          arc: 4.0,
        ),
      },
      DesignPersona.bob: {
        FieldClusterId.peopleCare: _ClusterGeometry(
          left: 38,
          top: 51,
          radiusX: 27,
          radiusY: 24,
          startAngle: -2.7,
          arc: 5.1,
        ),
        FieldClusterId.societyJustice: _ClusterGeometry(
          left: 70,
          top: 63,
          radiusX: 20,
          radiusY: 18,
          startAngle: -2.35,
          arc: 4.5,
        ),
        FieldClusterId.culturePlay: _ClusterGeometry(
          left: 78,
          top: 31,
          radiusX: 11,
          radiusY: 10,
          startAngle: -2.2,
          arc: 3.8,
        ),
        FieldClusterId.placePlanet: _ClusterGeometry(
          left: 84,
          top: 78,
          radiusX: 10,
          radiusY: 9,
          startAngle: -2.4,
          arc: 3.6,
        ),
        FieldClusterId.workWealth: _ClusterGeometry(
          left: 20,
          top: 30,
          radiusX: 12,
          radiusY: 10,
          startAngle: -2.6,
          arc: 4.2,
        ),
        FieldClusterId.knowledgeFrontier: _ClusterGeometry(
          left: 22,
          top: 78,
          radiusX: 10,
          radiusY: 8,
          startAngle: -2.3,
          arc: 3.5,
        ),
      },
      DesignPersona.carol: {
        FieldClusterId.peopleCare: _ClusterGeometry(
          left: 20,
          top: 70,
          radiusX: 15,
          radiusY: 16,
          startAngle: -2.5,
          arc: 4.4,
        ),
        FieldClusterId.societyJustice: _ClusterGeometry(
          left: 88,
          top: 49,
          radiusX: 8,
          radiusY: 10,
          startAngle: -2.2,
          arc: 3.5,
        ),
        FieldClusterId.culturePlay: _ClusterGeometry(
          left: 49,
          top: 51,
          radiusX: 34,
          radiusY: 28,
          startAngle: -2.85,
          arc: 5.55,
        ),
        FieldClusterId.placePlanet: _ClusterGeometry(
          left: 80,
          top: 76,
          radiusX: 9,
          radiusY: 9,
          startAngle: -2.4,
          arc: 3.7,
        ),
        FieldClusterId.workWealth: _ClusterGeometry(
          left: 77,
          top: 27,
          radiusX: 12,
          radiusY: 10,
          startAngle: -2.4,
          arc: 4.1,
        ),
        FieldClusterId.knowledgeFrontier: _ClusterGeometry(
          left: 82,
          top: 36,
          radiusX: 10,
          radiusY: 9,
          startAngle: -2.3,
          arc: 3.5,
        ),
      },
      DesignPersona.danny: {
        FieldClusterId.peopleCare: _ClusterGeometry(
          left: 87,
          top: 78,
          radiusX: 7,
          radiusY: 7,
          startAngle: -1.4,
          arc: 1.2,
        ),
        FieldClusterId.societyJustice: _ClusterGeometry(
          left: 40,
          top: 72,
          radiusX: 16,
          radiusY: 14,
          startAngle: -2.5,
          arc: 4.2,
        ),
        FieldClusterId.culturePlay: _ClusterGeometry(
          left: 75,
          top: 76,
          radiusX: 8,
          radiusY: 8,
          startAngle: -1.4,
          arc: 1.2,
        ),
        FieldClusterId.placePlanet: _ClusterGeometry(
          left: 40,
          top: 48,
          radiusX: 28,
          radiusY: 22,
          startAngle: -2.8,
          arc: 5.2,
        ),
        FieldClusterId.workWealth: _ClusterGeometry(
          left: 78,
          top: 38,
          radiusX: 14,
          radiusY: 12,
          startAngle: -2.5,
          arc: 4.0,
        ),
        FieldClusterId.knowledgeFrontier: _ClusterGeometry(
          left: 68,
          top: 30,
          radiusX: 16,
          radiusY: 14,
          startAngle: -2.65,
          arc: 4.6,
        ),
      },
    };

const Map<DesignPersona, List<String>> _nestedForeground = {
  DesignPersona.alice: [
    'economic-empowerment',
    'nature-of-work',
    'agentic-entrepreneur',
  ],
  DesignPersona.bob: [
    'we-care-a-lot',
    'service-alliance-foundation',
    'hosting-without-surveillance',
    'welcome-table',
    'lineage-as-care',
    'kitchen-shift',
    'economic-empowerment',
  ],
  DesignPersona.carol: [
    'lightbrush-studio',
    'practice-led-facilitation',
    'positive-psychology',
    'storykeepers-room',
    'homeworld-field-notes',
    'economic-empowerment',
  ],
  DesignPersona.danny: [
    'appalachian-field-systems',
    'watershed-repair',
    'agentic-engineer',
    'field-records',
    'software-as-world',
    'offline-first-builders',
  ],
};

double _clamp(double value, double minimum, double maximum) =>
    math.min(maximum, math.max(minimum, value));

int _massFor(AtlasRealm realm) {
  if (_massThree.contains(realm.id) || realm.children.length >= 7) {
    return 3;
  }
  if (_massTwo.contains(realm.id) ||
      realm.children.length >= 3 ||
      realm.type == AtlasRealmType.institution) {
    return 2;
  }
  return 1;
}

FieldBand _bandFor(String realmId, DesignPersona persona) {
  if (_foreground[persona]!.contains(realmId)) {
    return FieldBand.near;
  }
  if (_middle[persona]!.contains(realmId)) {
    return FieldBand.middle;
  }
  return FieldBand.far;
}

String _reasonFor(AtlasRealm realm, DesignPersona persona, FieldBand band) {
  if (persona == DesignPersona.alice && realm.id == 'dunaversity') {
    return 'Dunaversity contains the Program Alice is shaping and sits at the '
        'center of her current Catalyst work.';
  }
  if (persona == DesignPersona.bob && realm.id == 'service-alliance') {
    return 'Bob organizes Service Alliance, so its visible people, Projects, '
        'and responsibilities give it the strongest pull.';
  }
  if (persona == DesignPersona.carol && realm.id == 'ceremony-machine') {
    return 'The Ceremony Machine contains Carol’s current Media and production '
        'work.';
  }
  if (persona == DesignPersona.danny && realm.id == 'confluence-collective') {
    return 'Confluence Collective contains Danny’s current field systems, '
        'sandbox, and release work.';
  }
  if (band == FieldBand.near) {
    return '${realm.name} is close because this Persona has direct work, '
        'responsibility, or a strong granted role here.';
  }
  if (band == FieldBand.middle) {
    return '${realm.name} is visible through a joined Realm, explicit '
        'responsibility, or a legitimate cross-Realm bridge.';
  }
  return '${realm.name} is legitimate Ecosystem context, but it is not part of '
      'this Persona’s current Focus.';
}

List<FieldPlacement> _placeRing(
  List<AtlasRealm> items,
  DesignPersona persona,
  FieldClusterId cluster,
) {
  final geometry = _rootGeometry[persona]![cluster]!;
  final byBand = <FieldBand, List<AtlasRealm>>{
    FieldBand.near: [],
    FieldBand.middle: [],
    FieldBand.far: [],
  };
  for (final item in items) {
    byBand[_bandFor(item.id, persona)]!.add(item);
  }

  final placements = <FieldPlacement>[];
  for (final band in FieldBand.values) {
    final entries = byBand[band]!;
    final radiusMultiplier = band == FieldBand.near
        ? 0.62
        : band == FieldBand.middle
        ? 0.88
        : 1.1;
    for (var index = 0; index < entries.length; index++) {
      final realm = entries[index];
      final count = entries.length;
      final angle = count == 1
          ? geometry.startAngle + geometry.arc / 2
          : geometry.startAngle + (geometry.arc * index) / count;
      final left = _clamp(
        geometry.left + math.cos(angle) * geometry.radiusX * radiusMultiplier,
        5,
        95,
      );
      final top = _clamp(
        geometry.top + math.sin(angle) * geometry.radiusY * radiusMultiplier,
        9,
        92,
      );
      placements.add(
        FieldPlacement(
          realm: realm,
          left: left,
          top: top,
          band: band,
          cluster: cluster,
          mass: _massFor(realm),
          reason: _reasonFor(realm, persona, band),
          rolePull: band == FieldBand.near,
        ),
      );
    }
  }
  return placements;
}

FieldComposition _rootComposition(
  DesignPersona persona,
  List<AtlasRealm> realms,
) {
  final grouped = <FieldClusterId, List<AtlasRealm>>{};
  for (final realm in realms) {
    final cluster = _rootCluster[realm.id] ?? FieldClusterId.workWealth;
    grouped.putIfAbsent(cluster, () => []).add(realm);
  }

  final placements = <FieldPlacement>[];
  final clusters = <FieldCluster>[];
  for (final entry in grouped.entries) {
    placements.addAll(_placeRing(entry.value, persona, entry.key));
    final geometry = _rootGeometry[persona]![entry.key]!;
    clusters.add(
      FieldCluster(
        id: entry.key,
        label: _clusterLabels[entry.key]!,
        left: geometry.left,
        top: geometry.top,
        radiusX: geometry.radiusX,
        radiusY: geometry.radiusY,
      ),
    );
  }
  return FieldComposition(placements: placements, clusters: clusters);
}

FieldComposition _branchComposition(
  DesignPersona persona,
  List<AtlasRealm> realms,
) {
  final foreground = _nestedForeground[persona]!;
  final placements = <FieldPlacement>[];
  for (var index = 0; index < realms.length; index++) {
    final realm = realms[index];
    final band = foreground.contains(realm.id)
        ? FieldBand.near
        : realm.fixture
        ? FieldBand.far
        : FieldBand.middle;
    final angle =
        -math.pi / 2 + (math.pi * 2 * index) / math.max(1, realms.length);
    final radiusX = band == FieldBand.near
        ? 25.0
        : band == FieldBand.middle
        ? 34.0
        : 42.0;
    final radiusY = band == FieldBand.near
        ? 22.0
        : band == FieldBand.middle
        ? 29.0
        : 34.0;
    placements.add(
      FieldPlacement(
        realm: realm,
        left: _clamp(50 + math.cos(angle) * radiusX, 7, 93),
        top: _clamp(54 + math.sin(angle) * radiusY, 11, 91),
        band: band,
        cluster: FieldClusterId.branch,
        mass: _massFor(realm),
        reason: foreground.contains(realm.id)
            ? '${realm.name} is close because it matches this Persona’s '
                  'granted work inside the current Realm.'
            : realm.fixture
            ? '${realm.name} is a proposed Institution. It is visible as '
                  'structure, but restrained until its legal status is verified.'
            : '${realm.name} is a visible nested Realm within the current '
                  'granted scope.',
        rolePull: foreground.contains(realm.id),
      ),
    );
  }
  return FieldComposition(
    placements: placements,
    clusters: const [
      FieldCluster(
        id: FieldClusterId.branch,
        label: '',
        left: 50,
        top: 54,
        radiusX: 39,
        radiusY: 33,
      ),
    ],
  );
}

/// Composes the 2-D layout for [realms] visible to [persona] at
/// [currentRealmId] — the root Ecosystem uses cluster ellipses; any other Realm
/// uses a single radial branch ring. Pure and deterministic.
FieldComposition fieldCompositionFor(
  String currentRealmId,
  DesignPersona persona,
  List<AtlasRealm> realms,
) {
  return currentRealmId == 'kinship-duna'
      ? _rootComposition(persona, realms)
      : _branchComposition(persona, realms);
}
