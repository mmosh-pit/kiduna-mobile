import 'package:flutter/painting.dart';

abstract final class Enamel {
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

enum FieldCluster {
  formation('Formation · work · economy', Color(0xFF03CCD9)),
  care('Care · family · relationship', Color(0xFFCF6F58)),
  place('Place · ecology · mutual aid', Color(0xFF8FE6C6)),
  culture('Culture · play · public imagination', Color(0xFF9A7DE8)),
  law('Law · accountable institutions', Color(0xFFEAAA00)),
  branch('', Color(0xFF62A8DF));

  const FieldCluster(this.label, this.accent);

  final String label;
  final Color accent;

  static Color accentFor(String id) {
    for (final c in values) {
      if (c.name == id) {
        return c.accent;
      }
    }
    return Enamel.camel;
  }
}

enum Material4 {
  lacquer('Lacquer', 'Deep umber ground; no decorative wash'),
  enamel('Enamel', 'Saturated fill inside a metal rim'),
  goldWire('Gold wire', 'Thin orbital engraving and rims'),
  moonCream('Moon cream', 'Sparse glints; the threshold signal');

  const Material4(this.label, this.description);

  final String label;
  final String description;
}

enum RealmType {
  ecosystem('Ecosystem', 'Contains every other Realm'),
  organization('Organization', 'Radial institution'),
  alliance('Alliance', 'Interlocking centres'),
  community('Community', 'Gathered difference'),
  program('Program', 'Recurring rhythm'),
  project('Project', 'Finite ascent'),
  institution('Institution', 'Proposed legal entity'),
  relationship('Relationship', 'Mutual bond'),
  cell('Cell', 'Intimate working group'),
  concept('Concept', 'Abstract idea or principle'),
  dyad('Dyad', 'Two-person bond'),
  council('Council', 'Deliberative body'),
  clan('Clan', 'Extended kinship group');

  const RealmType(this.label, this.geometry);

  final String label;
  final String geometry;

  String get emblemAsset {
    const own = {organization, alliance, community, program, project};
    final name = own.contains(this) ? label.toLowerCase() : 'conceptual';
    return 'assets/images/realm-emblems/$name.jpg';
  }

  static const unknownEmblemAsset =
      'assets/images/realm-emblems/conceptual.jpg';

  static RealmType? parse(String raw) {
    for (final value in values) {
      if (value.label.toLowerCase() == raw.toLowerCase() ||
          value.name == raw.toLowerCase()) {
        return value;
      }
    }
    return null;
  }
}

enum Gravity {
  quiet(1, 'Quiet', 'Legitimate context, but not currently relevant', 1.12,
      0.25, Size(24, 22)),
  available(
      2, 'Available', 'Related and easy to find', 0.98, 0.82, Size(48, 44)),
  relevant(3, 'Relevant', 'Connected to current interests or work', 0.84, 1.0,
      Size(72, 65)),
  central(4, 'Central',
      'Directly involved in current responsibility or Focus', 0.70, 1.0,
      Size(118, 105)),
  vital(5, 'Vital',
      'Requires sustained awareness or consequential attention', 0.56, 1.0,
      Size(152, 142));

  const Gravity(
    this.level,
    this.label,
    this.meaning,
    this.pull,
    this.opacity,
    this.componentSize,
  );

  final int level;
  final String label;
  final String meaning;
  final double pull;
  final double opacity;
  final Size componentSize;

  static Gravity of(int level) =>
      values.firstWhere((g) => g.level == level, orElse: () => quiet);

  DistanceBand get band => switch (level) {
        >= 4 => DistanceBand.near,
        >= 2 => DistanceBand.middle,
        _ => DistanceBand.far,
      };
}

enum DistanceBand {
  near(Size(152, 142), 1.0, 'Unique high-resolution enamel Portrait'),
  middle(
      Size(118, 105), 1.0, 'Simplified emblem; silhouette and motif preserved'),
  far(Size(72, 65), 0.62, 'Generic filled Realm-type glyph');

  const DistanceBand(this.size, this.opacity, this.fidelity);

  final Size size;
  final double opacity;
  final String fidelity;
}
