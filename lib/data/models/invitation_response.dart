import 'package:flutter/foundation.dart';

/// Response from `POST /realm-invites/:realmId` — the values the review
/// panel displays.
@immutable
class InvitationResponse {
  const InvitationResponse({
    required this.id,
    required this.code,
    required this.invitationLink,
    required this.realmName,
    required this.role,
    required this.maxUses,
    this.recipientName,
    this.inviterHandle,
    this.kidunaPerPerson = 0,
    this.expiresAt,
    this.label,
  });

  /// Database ID of the created invite.
  final String id;

  /// The generated code string (e.g. `RLM-ABC123`).
  final String code;

  /// Full deep-link URL (e.g. `https://kiduna.ai/ravi/code/RLM-ABC123`).
  final String invitationLink;

  /// Realm name.
  final String realmName;

  /// Role granted on join.
  final String role;

  /// Max people who can use this code.
  final int maxUses;

  /// Optional recipient name.
  final String? recipientName;

  /// Inviter's handle (username).
  final String? inviterHandle;

  /// KIDUNA sponsored per person (0 = no sponsorship).
  final double kidunaPerPerson;

  /// When the invite expires.
  final String? expiresAt;

  /// Purpose label.
  final String? label;

  factory InvitationResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return InvitationResponse(
      id: data['id'] as String,
      code: data['code'] as String,
      invitationLink: (data['url'] as String?) ?? '',
      realmName: (data['realmName'] as String?) ?? '',
      role: (data['role'] as String?) ?? 'member',
      maxUses: int.tryParse(data['maxUses']?.toString() ?? '') ?? 1,
      recipientName: data['invitedName'] as String?,
      inviterHandle: data['inviterHandle'] as String?,
      kidunaPerPerson:
          double.tryParse(data['kidunaPerPerson']?.toString() ?? '') ??
          double.tryParse(data['kiduna_per_person']?.toString() ?? '') ??
          0,
      expiresAt: data['expiresAt']?.toString(),
      label: data['label'] as String?,
    );
  }

  /// Pre-formatted shareable invite text.
  String get shareText {
    final parts = <String>['Join $realmName on Kiduna!'];
    if (kidunaPerPerson > 0) {
      parts.add(
        '${_formatKiduna(kidunaPerPerson)} KIDUNA sponsored for you.',
      );
    }
    parts.add(invitationLink);
    return parts.join('\n');
  }

  /// Summary line for the review panel.
  String get summary {
    final parts = <String>[];
    parts.add('$maxUses ${maxUses == 1 ? 'person' : 'people'}');
    if (kidunaPerPerson > 0) {
      parts.add('${_formatKiduna(kidunaPerPerson)} KIDUNA each');
    }
    parts.add('Role: $role');
    return parts.join(' · ');
  }

  static String _formatKiduna(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvitationResponse &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
