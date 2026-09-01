import 'package:flutter/foundation.dart';

/// A single Realm returned by `/realms` or `/realms/:id`.
///
/// Replaces the old [AllianceModel], [InstitutionModel], and [DunaModel]
/// with a single unified model. The [type] field distinguishes the 12 Realm
/// types (Taxonomy V0.09): ecosystem, organization, alliance, program,
/// project, dyad, community, institution, council, concept, cell, clan.
///
/// Type-specific data lives in [config] (a JSON map). For example, an
/// Institution has `entityType`, `standingDocUrl`, etc. in its config.
@immutable
class RealmModel {
  const RealmModel({
    required this.id,
    required this.name,
    required this.handle,
    required this.type,
    this.parentId,
    this.primaryTheme,
    this.primaryFocus,
    this.description,
    this.purpose,
    this.tags = const [],
    this.avatar,
    required this.visibility,
    this.config = const {},
    this.email,
    required this.wallet,
    this.multisigPda,
    this.vaultPda,
    required this.walletEnabled,
    required this.threshold,
    required this.status,
    this.members = const [],
    required this.createdAt,
    this.gravityLevel,
    this.gravityScore,
    this.gameStatus,
    this.gameRoomCode,
    this.gamePlayerCount,
    this.gameSeatCount,
  });

  final String id;
  final String name;
  final String handle;

  /// One of the 12 Taxonomy V0.09 types: ecosystem, organization, alliance,
  /// program, project, dyad, community, institution, council, concept, cell, clan.
  final String type;

  /// Parent Realm id. Null for ecosystem (root).
  final String? parentId;

  /// One of 6 canonical Themes (Taxonomy V0.14). Null for ecosystem/clan/dyad/cell.
  final String? primaryTheme;

  /// One of 26 canonical Focuses within the chosen Theme.
  final String? primaryFocus;

  final String? description;
  final String? purpose;

  /// Tags for categorization and discovery.
  final List<String> tags;

  /// Avatar image URL (https://).
  final String? avatar;

  /// public | private | secret
  final String visibility;

  /// Type-specific configuration as a JSON map.
  /// Institution: { entityType, standingDocUrl, registrationDomain, ... }
  /// Alliance: { startDate, endDate, defaultTools, spendingRule }
  /// Ecosystem: { ecosystemId, registration, capacities }
  final Map<String, dynamic> config;

  final String? email;

  /// Creator/owner wallet address.
  final String wallet;

  /// Squads multisig PDA (filled after on-chain creation).
  final String? multisigPda;

  /// Squads treasury vault PDA.
  final String? vaultPda;

  final bool walletEnabled;

  /// Squads multisig approval threshold.
  final int threshold;

  /// draft | pending | active | published | registered | archived | failed
  final String status;

  /// Active members with their roles.
  final List<RealmMemberModel> members;

  final DateTime createdAt;

  /// Gravity level from the graph API (vital/central/relevant/available/quiet).
  /// Null when loaded from the table API.
  final String? gravityLevel;

  /// Gravity score from the graph API (0.0–1.0).
  /// Null when loaded from the table API.
  final double? gravityScore;

  final String? gameStatus;
  final String? gameRoomCode;
  final int? gamePlayerCount;
  final int? gameSeatCount;

  // ── Config convenience getters for Institution type ──

  String get entityType =>
      config['entityType'] as String? ?? 'company';
  String? get standingDocUrl =>
      config['standingDocUrl'] as String?;
  String? get standingDescription =>
      config['standingDescription'] as String?;
  String? get registrationDomain =>
      config['registrationDomain'] as String?;
  String? get designateContact =>
      config['designateContact'] as String?;
  String? get designateEmail =>
      config['designateEmail'] as String?;
  String? get address =>
      config['address'] as String?;

  // ── Config convenience getters for Alliance type ──

  String? get spendingRule =>
      config['spendingRule'] as String?;
  String? get defaultTools =>
      config['defaultTools'] as String?;

  // ── Config convenience getters for Ecosystem type ──

  String? get ecosystemId =>
      config['ecosystemId'] as String?;
  String? get registration =>
      config['registration'] as String?;
  String? get capacities =>
      config['capacities'] as String?;

  // ── Config convenience getters for Cell type ──

  String get cellType => config['cellType'] as String? ?? 'temporary';
  bool get isPermanentCell => type == 'cell' && cellType == 'permanent';
  bool get isTemporaryCell => type == 'cell' && cellType != 'permanent';

  /// Whether this is a genesis Ecosystem (root, no parent).
  bool get isGenesis => type == 'ecosystem' && parentId == null;

  /// Human-readable type label (e.g. "Alliance", "Ecosystem").
  String get typeLabel =>
      type.isNotEmpty ? '${type[0].toUpperCase()}${type.substring(1)}' : type;

  factory RealmModel.fromJson(Map<String, dynamic> json) {
    final membersJson = json['members'] as List<dynamic>? ?? [];
    final tagsJson = json['tags'] as List<dynamic>? ?? [];
    final configJson = json['config'] as Map<String, dynamic>? ?? {};

    return RealmModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      handle: json['handle'] as String? ?? '',
      type: json['type'] as String? ?? 'organization',
      parentId: json['parentId'] as String? ?? json['parent_id'] as String?,
      primaryTheme: json['primaryTheme'] as String? ?? json['primary_theme'] as String?,
      primaryFocus: json['primaryFocus'] as String? ?? json['primary_focus'] as String?,
      description: json['description'] as String?,
      purpose: json['purpose'] as String?,
      tags: tagsJson.whereType<String>().toList(),
      avatar: json['avatar'] as String?,
      visibility: json['visibility'] as String? ?? 'public',
      config: configJson,
      email: json['email'] as String?,
      wallet: json['wallet'] as String? ?? '',
      multisigPda: json['multisigPda'] as String? ?? json['multisig_pda'] as String?,
      vaultPda: json['vaultPda'] as String? ?? json['vault_pda'] as String?,
      walletEnabled: json['walletEnabled'] as bool? ?? json['wallet_enabled'] as bool? ?? false,
      threshold: json['threshold'] as int? ?? 1,
      status: json['status'] as String? ?? 'draft',
      members: membersJson
          .whereType<Map<String, dynamic>>()
          .map(RealmMemberModel.fromJson)
          .toList(),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}

/// A member within a Realm.
@immutable
class RealmMemberModel {
  const RealmMemberModel({
    this.id,
    required this.wallet,
    required this.role,
    required this.isSigner,
    this.username,
    this.displayName,
    this.name,
    this.picture,
  });

  final String? id;
  final String wallet;

  /// One of 9 roles from the Canon Taxonomy:
  /// visitor | guest | member | mage | catalyst | organizer | creator | builder | luminary
  final String role;

  /// Whether this member is a signer on the Squads multisig on-chain.
  final bool isSigner;

  final String? username;
  final String? displayName;
  final String? name;
  final String? picture;

  String get label =>
      displayName ?? username ?? name ?? '${wallet.substring(0, 4)}...${wallet.substring(wallet.length - 4)}';

  factory RealmMemberModel.fromJson(Map<String, dynamic> json) {
    return RealmMemberModel(
      id: json['id'] as String?,
      wallet: json['wallet'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      isSigner: json['isSigner'] as bool? ?? json['is_signer'] as bool? ?? false,
      username: json['username'] as String?,
      displayName: json['displayName'] as String? ?? json['display_name'] as String?,
      name: json['name'] as String?,
      picture: json['picture'] as String?,
    );
  }
}

/// The response shape from `GET /realms`.
@immutable
class RealmsListResponse {
  const RealmsListResponse({
    this.realms = const [],
    this.total = 0,
  });

  final List<RealmModel> realms;
  final int total;

  factory RealmsListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['realms'] as List<dynamic>? ?? [];
    return RealmsListResponse(
      realms: list
          .whereType<Map<String, dynamic>>()
          .map(RealmModel.fromJson)
          .toList(),
      total: json['total'] as int? ?? 0,
    );
  }
}

/// The response shape from `GET /realms/ecosystem`.
@immutable
class EcosystemResponse {
  const EcosystemResponse({this.ecosystem});

  final RealmModel? ecosystem;

  factory EcosystemResponse.fromJson(Map<String, dynamic> json) {
    final eco = json['ecosystem'] as Map<String, dynamic>?;
    return EcosystemResponse(
      ecosystem: eco != null ? RealmModel.fromJson(eco) : null,
    );
  }
}
