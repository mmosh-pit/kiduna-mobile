import 'package:flutter/foundation.dart';

/// A single Alliance returned by `/api/v1/alliances`.
@immutable
class AllianceModel {
  const AllianceModel({
    required this.id,
    required this.name,
    required this.handle,
    this.description,
    this.purpose,
    required this.visibility,
    this.startDate,
    this.endDate,
    required this.threshold,
    this.parentMarketId,
    required this.creatorWallet,
    this.multisigPda,
    this.vaultPda,
    required this.walletEnabled,
    this.spendingRule,
    this.defaultTools,
    required this.status,
    this.members = const [],
    required this.createdAt,
  });

  final String id;
  final String name;
  final String handle;
  final String? description;
  final String? purpose;

  /// public | private | secret
  final String visibility;

  final DateTime? startDate;
  final DateTime? endDate;

  /// Squads multisig approval threshold (1-of-N).
  final int threshold;

  final String? parentMarketId;
  final String creatorWallet;

  /// Squads multisig PDA (filled after on-chain creation).
  final String? multisigPda;

  /// Squads treasury vault PDA (the Team Wallet).
  final String? vaultPda;

  final bool walletEnabled;
  final String? spendingRule;
  final String? defaultTools;

  /// draft | active | archived
  final String status;

  /// Active members with their roles.
  final List<AllianceMemberModel> members;

  final DateTime createdAt;

  factory AllianceModel.fromJson(Map<String, dynamic> json) {
    final membersJson = json['members'] as List<dynamic>? ?? [];
    return AllianceModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      handle: json['handle'] as String? ?? '',
      description: json['description'] as String?,
      purpose: json['purpose'] as String?,
      visibility: json['visibility'] as String? ?? 'public',
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      threshold: json['threshold'] as int? ?? 1,
      parentMarketId: json['parentMarketId'] as String?,
      creatorWallet: json['creatorWallet'] as String? ?? '',
      multisigPda: json['multisigPda'] as String?,
      vaultPda: json['vaultPda'] as String?,
      walletEnabled: json['walletEnabled'] as bool? ?? false,
      spendingRule: json['spendingRule'] as String?,
      defaultTools: json['defaultTools'] as String?,
      status: json['status'] as String? ?? 'draft',
      members: membersJson
          .whereType<Map<String, dynamic>>()
          .map(AllianceMemberModel.fromJson)
          .toList(),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

/// A member within an Alliance.
@immutable
class AllianceMemberModel {
  const AllianceMemberModel({
    required this.wallet,
    required this.role,
    required this.isSigner,
  });

  final String wallet;

  /// Wizard | Operator | Connector | Treasurer | Organizer | Guide | Scribe | Member | Guest
  final String role;

  /// Whether this member is a signer on the Squads multisig on-chain.
  final bool isSigner;

  factory AllianceMemberModel.fromJson(Map<String, dynamic> json) {
    return AllianceMemberModel(
      wallet: json['wallet'] as String? ?? '',
      role: json['role'] as String? ?? 'Member',
      isSigner: json['isSigner'] as bool? ?? false,
    );
  }
}
