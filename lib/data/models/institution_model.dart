import 'package:flutter/foundation.dart';

/// A single Institution returned by `/institutions`.
@immutable
class InstitutionModel {
  const InstitutionModel({
    required this.id,
    required this.name,
    required this.handle,
    this.description,
    this.purpose,
    required this.entityType,
    this.standingDocUrl,
    this.standingDescription,
    this.registrationDomain,
    this.designateContact,
    this.designateEmail,
    this.address,
    required this.threshold,
    required this.creatorWallet,
    this.multisigPda,
    this.vaultPda,
    required this.walletEnabled,
    this.spendingRule,
    required this.status,
    this.members = const [],
    required this.createdAt,
  });

  final String id;
  final String name;
  final String handle;
  final String? description;
  final String? purpose;

  /// company | government | charity | ngo | education | other
  final String entityType;

  // ── Legal standing ──
  final String? standingDocUrl;
  final String? standingDescription;
  final String? registrationDomain;

  // ── Designated contact ──
  final String? designateContact;
  final String? designateEmail;

  // ── Physical address ──
  final String? address;

  // ── Squads multisig ──
  final int threshold;
  final String creatorWallet;
  final String? multisigPda;
  final String? vaultPda;
  final bool walletEnabled;
  final String? spendingRule;

  /// draft | published | registered
  final String status;

  final List<InstitutionMemberModel> members;
  final DateTime createdAt;

  factory InstitutionModel.fromJson(Map<String, dynamic> json) {
    final membersJson = json['members'] as List<dynamic>? ?? [];
    return InstitutionModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      handle: json['handle'] as String? ?? '',
      description: json['description'] as String?,
      purpose: json['purpose'] as String?,
      entityType: json['entityType'] as String? ?? json['entity_type'] as String? ?? 'company',
      standingDocUrl: json['standingDocUrl'] as String? ?? json['standing_doc_url'] as String?,
      standingDescription: json['standingDescription'] as String? ?? json['standing_description'] as String?,
      registrationDomain: json['registrationDomain'] as String? ?? json['registration_domain'] as String?,
      designateContact: json['designateContact'] as String? ?? json['designate_contact'] as String?,
      designateEmail: json['designateEmail'] as String? ?? json['designate_email'] as String?,
      address: json['address'] as String?,
      threshold: json['threshold'] as int? ?? 1,
      creatorWallet: json['creatorWallet'] as String? ?? json['creator_wallet'] as String? ?? '',
      multisigPda: json['multisigPda'] as String? ?? json['multisig_pda'] as String?,
      vaultPda: json['vaultPda'] as String? ?? json['vault_pda'] as String?,
      walletEnabled: json['walletEnabled'] as bool? ?? json['wallet_enabled'] as bool? ?? false,
      spendingRule: json['spendingRule'] as String? ?? json['spending_rule'] as String?,
      status: json['status'] as String? ?? 'draft',
      members: membersJson
          .whereType<Map<String, dynamic>>()
          .map(InstitutionMemberModel.fromJson)
          .toList(),
      createdAt: DateTime.tryParse(
              json['createdAt'] as String? ?? json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// A member within an Institution.
@immutable
class InstitutionMemberModel {
  const InstitutionMemberModel({
    required this.wallet,
    required this.isSigner,
  });

  final String wallet;
  final bool isSigner;

  factory InstitutionMemberModel.fromJson(Map<String, dynamic> json) {
    return InstitutionMemberModel(
      wallet: json['wallet'] as String? ?? '',
      isSigner: json['isSigner'] as bool? ?? json['is_signer'] as bool? ?? false,
    );
  }
}
