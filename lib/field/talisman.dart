/// Talismans — portable symbols of meaning.
///
/// > Talismans are portable symbols of meaning, **not Realm types and not
/// > identities**. The geometry around them is a kit of semantic parts: each
/// > arc, node, stud, path, and glint earns its place.
/// >
/// > — the Design Lab canon, §04
///
/// The distinction matters at the data layer, not just visually. A Realm type
/// is a closed enum of ten and decides what a thing *is*; a Talisman is an
/// attachable mark that says what a thing is *for*. Anything may carry one,
/// carrying one changes no permission, and nothing is a Talisman *instead of*
/// being something else.
///
/// The six below are the supplied set, with assets already in the repository.
/// They are **not** a closed list in the canon — new Talismans arrive the same
/// way sub-themes do, so this enum must not be treated as exhaustive by any
/// consumer that persists a value.
library;

enum Talisman {
  compass(
    'Compass',
    'Orientation',
    'find the way',
    'assets/talismans/compass.png',
  ),
  moon(
    'Moon',
    'Reflection',
    'hold possibility',
    'assets/talismans/moon.png',
  ),
  sprout(
    'Sprout',
    'Cultivation',
    'help life emerge',
    'assets/talismans/sprout.png',
  ),
  tide(
    'Tide',
    'Flow',
    'move with a living rhythm',
    'assets/talismans/tide.png',
  ),
  summit(
    'Summit',
    'Purpose',
    'move toward a horizon',
    'assets/talismans/summit.png',
  ),
  vessel(
    'Vessel',
    'Stewardship',
    'hold shared value',
    'assets/talismans/vessel.png',
  );

  const Talisman(this.label, this.meaning, this.gloss, this.asset);

  /// The name shown to a member.
  final String label;

  /// The single word the canon gives it.
  final String meaning;

  /// What carrying it asks of the carrier.
  final String gloss;

  final String asset;

  /// Unknown ids resolve to null rather than throwing: the set is open, and a
  /// Talisman this build has never heard of must degrade to "no mark", never
  /// to a crash or to the wrong mark.
  static Talisman? parse(String? raw) {
    if (raw == null) return null;
    for (final t in values) {
      if (t.name == raw) return t;
    }
    return null;
  }
}

/// The composition order the canon fixes for any Talisman arrangement.
///
/// > Ground → geometry → connection → object → signal
///
/// Listed here rather than only in prose because it is a **drawing order**: a
/// signal painted before its object, or a connection over the object it joins,
/// reads as a different picture even with identical parts.
const talismanCompositionOrder = <(String, String)>[
  ('Ground', 'Deep umber lacquer; no decorative wash.'),
  ('Geometry', 'Quiet orbital scaffolding establishes gravity.'),
  ('Connection', 'Semantic paths join anchored points.'),
  ('Object', 'Ally, Realm, Element, or Talisman occupies the field.'),
  ('Signal', 'One active glint or enamel pulse reveals change.'),
];
