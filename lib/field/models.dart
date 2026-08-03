/// Dart mirror of `contracts/field-snapshot.schema.json`.
///
/// The source sends **meaning**; the client derives **geometry**. Nothing in
/// this file computes a position — see `placement.dart` for that.
library;

import 'dart:ui' show Color;

import '../design/tokens.dart';

/// `#RRGGBB` → Color. Null for anything unparseable, so a bad accent falls
/// back rather than throwing.
Color? _parseHex(String? hex) {
  if (hex == null || hex.length != 7 || !hex.startsWith('#')) return null;
  final value = int.tryParse(hex.substring(1), radix: 16);
  return value == null ? null : Color(0xFF000000 | value);
}

/// What a Source may do in a Realm. Ranked loosely from least to most standing.
enum Role {
  guest('Guest'),
  member('Member'),
  organizer('Organizer'),
  creator('Creator'),
  builder('Builder'),
  catalyst('Catalyst'),
  luminary('Luminary'),
  mage('Mage');

  const Role(this.label);

  final String label;

  static Role parse(String? raw) => values.firstWhere(
        (r) => r.label.toLowerCase() == raw?.toLowerCase(),
        orElse: () => Role.guest,
      );
}

/// An Ally's behavioural State.
///
/// State is **context, not identity**. It may change gaze, halo, crop and
/// emphasis — never the person, and never implying a human emotion or a
/// private mental state.
enum AllyState {
  open('Open', 'Available · welcoming · present'),
  engaged('Engaged', 'Conversing · collaborating · responding'),
  focused('Focused', 'Working · reviewing · making'),
  dreaming('Dreaming', 'Imagining · reflecting · exploring');

  const AllyState(this.label, this.meaning);

  final String label;
  final String meaning;

  static AllyState parse(String? raw) => values.firstWhere(
        (s) => s.name == raw,
        orElse: () => AllyState.open,
      );
}

/// An Ally is a Portrait, not an avatar.
class Ally {
  const Ally({
    required this.id,
    required this.name,
    required this.state,
    this.portrait,
  });

  final String id;
  final String name;
  final AllyState state;
  final String? portrait;

  factory Ally.fromJson(Map<String, dynamic> json) => Ally(
        id: json['id'] as String,
        name: json['name'] as String,
        state: AllyState.parse(json['state'] as String?),
        portrait: json['portrait'] as String?,
      );
}

/// An elliptical region of the Field.
///
/// A restrained halo — never a hard container, never a ranking boundary.
class ClusterDef {
  const ClusterDef({
    required this.id,
    required this.label,
    required this.accent,
    required this.left,
    required this.top,
    required this.radiusX,
    required this.radiusY,
    this.startAngle = -2.8,
    this.arc = 5.25,
  });

  /// An open string, not an enum. Clusters **arise** from parentage and
  /// working relationships rather than being drawn from a fixed list, so an
  /// Ecosystem with twenty working groupings has twenty clusters. The five
  /// named for Kinship Duna are its *primary* clusters, not a system limit.
  final String id;

  final String label;

  /// **Taken from the snapshot**, not from a hardcoded table.
  ///
  /// An earlier version read the accent off a six-value enum and silently
  /// dropped the one the wire supplied — so a server sending its own colour
  /// was ignored, and any cluster outside the six was unrenderable.
  final Color accent;

  /// True for the implicit cluster of nested children, which carries no label
  /// and no halo in the root Field.
  bool get isBranch => id == 'branch';

  /// Centre, in percent of Field.
  final double left;
  final double top;
  final double radiusX;
  final double radiusY;

  /// Radians: where the ring of Realms begins, and how far it sweeps.
  final double startAngle;
  final double arc;

  factory ClusterDef.fromJson(Map<String, dynamic> json) => ClusterDef(
        id: json['id'] as String,
        label: json['label'] as String? ?? '',
        accent: _parseHex(json['accent'] as String?) ??
            Cluster.accentFor(json['id'] as String),
        left: (json['left'] as num).toDouble(),
        top: (json['top'] as num).toDouble(),
        radiusX: (json['radiusX'] as num).toDouble(),
        radiusY: (json['radiusY'] as num).toDouble(),
        startAngle: (json['startAngle'] as num?)?.toDouble() ?? -2.8,
        arc: (json['arc'] as num?)?.toDouble() ?? 5.25,
      );
}

/// A position in percent-of-Field space.
class FieldPoint {
  const FieldPoint(this.left, this.top);

  final double left;
  final double top;

  factory FieldPoint.fromJson(Map<String, dynamic> json) => FieldPoint(
        (json['left'] as num).toDouble(),
        (json['top'] as num).toDouble(),
      );

  @override
  String toString() =>
      'FieldPoint(${left.toStringAsFixed(2)}, ${top.toStringAsFixed(2)})';
}

/// A container of work or relationship.
class Realm {
  const Realm({
    required this.id,
    required this.name,
    required this.typeName,
    required this.type,
    required this.clusterId,
    required this.mass,
    required this.fixture,
    this.parentId,
    this.purpose = '',
    this.motif = '',
    this.childIds = const [],
    this.seed,
    this.stationedAllyId,
    this.portrait,
    this.reason,
    this.themes = const [],
  });

  final String id;
  final String name;

  /// The raw type string from the snapshot, preserved even when unrecognised.
  final String typeName;

  /// `null` when [typeName] is not a type this build knows.
  final RealmType? type;

  final String? parentId;
  final String purpose;
  final String motif;
  final List<String> childIds;

  /// Which orbit this Realm sits on. Open string — see [ClusterDef.id].
  final String clusterId;

  /// Optional pre-Gravity anchor. Absent means the client derives it.
  final FieldPoint? seed;

  final int mass;

  /// A *proposed* entity that does not yet exist. Must be visually
  /// distinguishable and never presented as real.
  final bool fixture;

  final String? stationedAllyId;
  final String? portrait;

  /// Why this Realm sits where it does, for this viewer. Inspection copy.
  final String? reason;

  /// What the Realm is **about** — the intention layer. At most three, so
  /// tagging stays a signal and not noise.
  ///
  /// Distinct from [clusterId], which is *where* it sits: a Realm carries up
  /// to three Themes but can occupy only one position in space. Values come
  /// from the 26-theme spine or from open folksonomy sub-themes beneath it,
  /// so this is a list of strings rather than an enum — a new sub-theme must
  /// never be a breaking change.
  final List<String> themes;

  /// Falls back to the conceptual emblem for unknown types.
  String get emblemAsset => type?.emblemAsset ?? RealmType.unknownEmblemAsset;

  /// True when the snapshot carries a type this build does not recognise.
  bool get isUnknownType => type == null;

  factory Realm.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String;
    return Realm(
      id: json['id'] as String,
      name: json['name'] as String,
      typeName: rawType,
      type: RealmType.parse(rawType),
      parentId: json['parentId'] as String?,
      purpose: json['purpose'] as String? ?? '',
      motif: json['motif'] as String? ?? '',
      childIds:
          (json['childIds'] as List<dynamic>? ?? []).cast<String>().toList(),
      clusterId: json['clusterId'] as String,
      seed: json['seed'] == null
          ? null
          : FieldPoint.fromJson(json['seed'] as Map<String, dynamic>),
      mass: json['mass'] as int,
      fixture: json['fixture'] as bool,
      stationedAllyId: json['stationedAllyId'] as String?,
      portrait: json['portrait'] as String?,
      reason: json['reason'] as String?,
      themes:
          (json['themes'] as List<dynamic>? ?? []).cast<String>().toList(),
    );
  }
}

/// A cross-cluster relationship. Quieter than within-cluster paths.
class Bridge {
  const Bridge({required this.fromRealmId, required this.toRealmId});

  final String fromRealmId;
  final String toRealmId;

  factory Bridge.fromJson(Map<String, dynamic> json) => Bridge(
        fromRealmId: json['fromRealmId'] as String,
        toRealmId: json['toRealmId'] as String,
      );
}

/// The Source looking at the Field.
///
/// Roles and Gravity are **per viewer** — two members see the same Realm at
/// different distances, and that is correct.
class Viewer {
  const Viewer({
    required this.id,
    required this.displayName,
    this.allyId,
    this.relationship,
    this.roles = const {},
    this.gravity = const {},
  });

  final String id;
  final String displayName;
  final String? allyId;
  final String? relationship;
  final Map<String, Role> roles;
  final Map<String, Gravity> gravity;

  Role roleIn(String realmId) => roles[realmId] ?? Role.guest;

  /// Unset Gravity reads as Quiet — legitimate context, not current Focus.
  Gravity gravityFor(String realmId) => gravity[realmId] ?? Gravity.quiet;

  factory Viewer.fromJson(Map<String, dynamic> json) => Viewer(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        allyId: json['allyId'] as String?,
        relationship: json['relationship'] as String?,
        roles: (json['roles'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, Role.parse(v as String?))),
        gravity: (json['gravity'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, Gravity.of(v as int))),
      );
}

/// Identifies the Realm that contains every other Realm in this Field.
class EcosystemRef {
  const EcosystemRef({required this.id, required this.name, this.type});

  final String id;
  final String name;
  final String? type;

  factory EcosystemRef.fromJson(Map<String, dynamic> json) => EcosystemRef(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String?,
      );
}

/// Everything the Field needs to render, for one viewer at one moment.
class FieldSnapshot {
  const FieldSnapshot({
    required this.schemaVersion,
    required this.viewer,
    required this.ecosystem,
    required this.realms,
    required this.clusters,
    this.allies = const [],
    this.bridges = const [],
    this.currentPathTargetId,
  });

  final String schemaVersion;
  final Viewer viewer;
  final EcosystemRef ecosystem;

  /// Only Realms this viewer may see. **Absence is the visibility mechanism** —
  /// a hidden Realm is never sent with a flag.
  final List<Realm> realms;

  final List<ClusterDef> clusters;
  final List<Ally> allies;
  final List<Bridge> bridges;

  /// Usually the viewer's Vital Realm. `null` draws no current-path signal.
  final String? currentPathTargetId;

  Ally? allyById(String? id) {
    if (id == null) return null;
    for (final ally in allies) {
      if (ally.id == id) return ally;
    }
    return null;
  }

  /// The major version. A client must refuse an unknown major.
  int get schemaMajor => int.parse(schemaVersion.split('.').first);

  factory FieldSnapshot.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'] as String;
    final major = int.parse(version.split('.').first);
    if (major != 1) {
      throw FormatException(
        'Unsupported FieldSnapshot major version $major. '
        'This client implements 1.x — see contracts/README.md.',
      );
    }
    return FieldSnapshot(
      schemaVersion: version,
      viewer: Viewer.fromJson(json['viewer'] as Map<String, dynamic>),
      ecosystem:
          EcosystemRef.fromJson(json['ecosystem'] as Map<String, dynamic>),
      realms: (json['realms'] as List<dynamic>)
          .map((e) => Realm.fromJson(e as Map<String, dynamic>))
          .toList(),
      clusters: (json['clusters'] as List<dynamic>)
          .map((e) => ClusterDef.fromJson(e as Map<String, dynamic>))
          .toList(),
      allies: (json['allies'] as List<dynamic>? ?? [])
          .map((e) => Ally.fromJson(e as Map<String, dynamic>))
          .toList(),
      bridges: (json['bridges'] as List<dynamic>? ?? [])
          .map((e) => Bridge.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPathTargetId:
          (json['currentPath'] as Map<String, dynamic>?)?['targetRealmId']
              as String?,
    );
  }
}
