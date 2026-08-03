/// Kiduna Studio design tokens.
///
/// Source: `design-kit/studio-v1.7/DESIGN-SYSTEM.md` and the Design Lab canon
/// at https://www.kiduna.design/ ("Studio system · 22 July 2026").
///
/// The visual language is **Deep. Warm. Alive.** — the celestial-enamel canon.
library;

import 'package:flutter/painting.dart';

/// The eleven canonical colour tokens.
abstract final class Enamel {
  /// The canonical Studio Field ground. Never a gradient, never a wash.
  static const deepField = Color(0xFF0A0604);
  static const deepEspresso = Color(0xFF060304);
  static const warmSurface = Color(0xFF1C140D);
  static const raisedUmber = Color(0xFF271B11);
  static const raisedWarmSurface = Color(0xFF33251A);

  static const cream = Color(0xFFFFF6D5);
  static const text = Color(0xFFFFFFE6);
  static const camel = Color(0xFFC19A6B);

  static const skyBlue = Color(0xFF03CCD9);
  static const sunGold = Color(0xFFEAAA00);
  static const mint = Color(0xFF8FE6C6);

  /// Every token, in canon order — for the Phase 7 Field Catalog.
  static const all = <(String, Color)>[
    ('Deep Field', deepField),
    ('Deep espresso', deepEspresso),
    ('Warm surface', warmSurface),
    ('Raised umber', raisedUmber),
    ('Raised warm surface', raisedWarmSurface),
    ('Cream', cream),
    ('Text', text),
    ('Camel', camel),
    ('Sky blue', skyBlue),
    ('Sun gold', sunGold),
    ('Mint', mint),
  ];
}

/// The six Field clusters.
///
/// Five are visible themes; `branch` is the implicit cluster for nested child
/// Realms. Accents come from `CLUSTER_PALETTE` in `CanonicalFirstField.tsx`.
enum Cluster {
  formation('Formation · work · economy', Color(0xFF03CCD9)),
  care('Care · family · relationship', Color(0xFFCF6F58)),
  place('Place · ecology · mutual aid', Color(0xFF8FE6C6)),
  culture('Culture · play · public imagination', Color(0xFF9A7DE8)),
  law('Law · accountable institutions', Color(0xFFEAAA00)),

  /// Nested children. Carries no label in the Field.
  branch('', Color(0xFF62A8DF));

  const Cluster(this.label, this.accent);

  /// Empty for [Cluster.branch].
  final String label;
  final Color accent;

  /// Fallback accent for a cluster id, used only when a snapshot omits one.
  /// Unknown ids get a neutral camel rather than throwing — clusters arise
  /// from working relationships, so the set is open-ended by design.
  static Color accentFor(String id) {
    for (final c in values) {
      if (c.name == id) return c.accent;
    }
    return Enamel.camel;
  }
}

/// The four named materials of the celestial-enamel canon.
///
/// Not colours in their own right — they describe *how* a surface reads.
enum Material4 {
  lacquer('Lacquer', 'Deep umber ground; no decorative wash'),
  enamel('Enamel', 'Saturated fill inside a metal rim'),
  goldWire('Gold wire', 'Thin orbital engraving and rims'),
  moonCream('Moon cream', 'Sparse glints; the threshold signal');

  const Material4(this.label, this.description);

  final String label;
  final String description;
}

/// Realm types carried by the AEV Atlas fixture (`lib/realm-atlas.ts`).
///
/// Note the asset gap: only Organization, Alliance, Community, Program,
/// Project and Relationship have their own emblem. Ecosystem and Institution
/// both fall through to `conceptual.png` in the reference implementation.
/// Flagged for Moto rather than invented — see AEV-UNDERSTANDING.md §13.
enum RealmType {
  ecosystem('Ecosystem', 'Contains every other Realm'),
  organization('Organization', 'Radial institution'),
  alliance('Alliance', 'Interlocking centres'),
  community('Community', 'Gathered difference'),
  program('Program', 'Recurring rhythm'),
  project('Project', 'Finite ascent'),
  institution('Institution', 'Proposed legal entity');

  const RealmType(this.label, this.geometry);

  final String label;

  /// Crest geometry per the Design Lab canon §03.
  final String geometry;

  /// Mirrors `realmTypeEmblem()` in `CanonicalFirstField.tsx`: types without a
  /// dedicated emblem fall back to `conceptual`.
  String get emblemAsset {
    const own = {organization, alliance, community, program, project};
    final name = own.contains(this) ? label.toLowerCase() : 'conceptual';
    return 'assets/realm-emblems/$name.png';
  }

  /// Shown for any Realm type this build does not recognise.
  static const unknownEmblemAsset = 'assets/realm-emblems/conceptual.png';

  /// Returns `null` for an unrecognised type rather than throwing.
  ///
  /// The contract requires forward compatibility: a server that introduces a
  /// new Realm type must not break this client. Callers pair the null with
  /// [unknownEmblemAsset] and keep the raw name for display.
  static RealmType? parse(String raw) {
    for (final value in values) {
      if (value.label.toLowerCase() == raw.toLowerCase()) return value;
    }
    return null;
  }
}

/// Source-controlled relevance, 1–5.
///
/// Gravity changes **presentation only** — never authority, membership, or
/// truth. It drives position, distance band, and art fidelity together.
enum Gravity {
  quiet(1, 'Quiet', 'Legitimate context, but not currently relevant', 1.12),
  available(2, 'Available', 'Related and easy to find', 0.98),
  relevant(3, 'Relevant', 'Connected to current interests or work', 0.84),
  central(4, 'Central', 'Directly involved in current responsibility or Focus', 0.70),
  vital(5, 'Vital', 'Requires sustained awareness or consequential attention', 0.56);

  const Gravity(this.level, this.label, this.meaning, this.pull);

  final int level;
  final String label;
  final String meaning;

  /// Multiplier applied to the Realm's offset from its cluster centre.
  /// Higher Gravity pulls a Realm *toward* the centre.
  final double pull;

  static Gravity of(int level) =>
      values.firstWhere((g) => g.level == level, orElse: () => quiet);

  /// `gravity >= 4 → near · >= 2 → middle · else far`.
  DistanceBand get band => switch (level) {
        >= 4 => DistanceBand.near,
        >= 2 => DistanceBand.middle,
        _ => DistanceBand.far,
      };
}

/// Distance is the encoding of relevance, not a level-of-detail optimisation.
///
/// Near carries a unique high-fidelity Portrait; far carries a generic
/// Realm-type glyph. Reading distance *is* reading relevance.
enum DistanceBand {
  near(Size(152, 142), 1.0, 'Unique high-resolution enamel Portrait'),
  middle(Size(118, 105), 1.0, 'Simplified emblem; silhouette and motif preserved'),
  far(Size(72, 65), 0.62, 'Generic filled Realm-type glyph');

  const DistanceBand(this.size, this.opacity, this.fidelity);

  final Size size;
  final double opacity;
  final String fidelity;
}
