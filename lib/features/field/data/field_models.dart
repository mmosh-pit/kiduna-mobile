import 'dart:ui' show Color;

import '../game/enamel_tokens.dart';

Color? parseHex(String? hex) {
  if (hex == null || hex.length != 7 || !hex.startsWith('#')) return null;
  final value = int.tryParse(hex.substring(1), radix: 16);
  return value == null ? null : Color(0xFF000000 | value);
}

enum Role {
  guest('Guest'),
  member('Member'),
  sponsor('Sponsor'),
  organizer('Organizer'),
  creator('Creator'),
  builder('Builder'),
  luminary('Luminary'),
  mage('Mage'),
  catalyst('Catalyst');

  const Role(this.label);

  final String label;

  /// Whether this role can invite people.
  bool get canInvite =>
      this == catalyst || this == mage || this == organizer;

  /// Whether this role can create sub-realms / content.
  bool get canCreate =>
      this == catalyst || this == mage || this == creator;

  /// Whether this role can shape / update realm settings.
  bool get canShape =>
      this == catalyst || this == mage || this == builder;

  /// Whether this role can present / edit realm presentation.
  bool get canPresent =>
      this == catalyst || this == mage;

  /// Whether this role can manage members (change roles, kick).
  bool get canManageMembers =>
      this == catalyst || this == mage;

  /// Whether this role can view alliance / squad wallet.
  bool get canViewAlliance =>
      this == catalyst || this == mage || this == sponsor;

  static Role parse(String? raw) => values.firstWhere(
        (r) => r.label.toLowerCase() == raw?.toLowerCase(),
        orElse: () => Role.guest,
      );
}

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

  final String id;
  final String label;
  final Color accent;

  bool get isBranch => id == 'branch';

  final double left;
  final double top;
  final double radiusX;
  final double radiusY;

  final double startAngle;
  final double arc;

  factory ClusterDef.fromJson(Map<String, dynamic> json) => ClusterDef(
        id: json['id'] as String,
        label: json['label'] as String? ?? '',
        accent: parseHex(json['accent'] as String?) ??
            FieldCluster.accentFor(json['id'] as String),
        left: (json['left'] as num).toDouble(),
        top: (json['top'] as num).toDouble(),
        radiusX: (json['radiusX'] as num).toDouble(),
        radiusY: (json['radiusY'] as num).toDouble(),
        startAngle: (json['startAngle'] as num?)?.toDouble() ?? -2.8,
        arc: (json['arc'] as num?)?.toDouble() ?? 5.25,
      );
}

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
    this.gameStatus,
    this.gameRoomCode,
    this.gamePlayerCount,
    this.gameSeatCount,
  });

  final String id;
  final String name;
  final String typeName;
  final RealmType? type;
  final String? parentId;
  final String purpose;
  final String motif;
  final List<String> childIds;
  final String clusterId;
  final FieldPoint? seed;
  final int mass;
  final bool fixture;
  final String? stationedAllyId;
  final String? portrait;
  final String? reason;
  final List<String> themes;
  final String? gameStatus;
  final String? gameRoomCode;
  final int? gamePlayerCount;
  final int? gameSeatCount;

  String get emblemAsset => type?.emblemAsset ?? RealmType.unknownEmblemAsset;

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

class Bridge {
  const Bridge({required this.fromRealmId, required this.toRealmId});

  final String fromRealmId;
  final String toRealmId;

  factory Bridge.fromJson(Map<String, dynamic> json) => Bridge(
        fromRealmId: json['fromRealmId'] as String,
        toRealmId: json['toRealmId'] as String,
      );
}

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
  final List<Realm> realms;
  final List<ClusterDef> clusters;
  final List<Ally> allies;
  final List<Bridge> bridges;
  final String? currentPathTargetId;

  Ally? allyById(String? id) {
    if (id == null) return null;
    for (final ally in allies) {
      if (ally.id == id) return ally;
    }
    return null;
  }

  int get schemaMajor => int.parse(schemaVersion.split('.').first);

  factory FieldSnapshot.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'] as String;
    final major = int.parse(version.split('.').first);
    if (major != 1) {
      throw FormatException(
        'Unsupported FieldSnapshot major version $major.',
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
