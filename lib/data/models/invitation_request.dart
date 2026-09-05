import 'package:flutter/foundation.dart';

/// Request body for `POST /realm-invites/:realmId` — the fields from the
/// Invite panel mapped to the kinship-backend schema.
@immutable
class InvitationRequest {
  const InvitationRequest({
    required this.realmId,
    required this.role,
    required this.expiration,
    required this.maxUses,
    this.recipientName,
    this.label,
    this.kidunaPerPerson = 0,
  });

  final String realmId;
  final String role;
  final String expiration;
  final int maxUses;
  final String? recipientName;
  final String? label;
  final double kidunaPerPerson;

  Map<String, dynamic> toJson() => {
    'role': role.toLowerCase(),
    'expires_in': expiration,
    'max_uses': maxUses,
    if (recipientName != null && recipientName!.isNotEmpty)
      'invited_name': recipientName,
    if (label != null && label!.isNotEmpty) 'label': label,
    if (kidunaPerPerson > 0) 'kiduna_per_person': kidunaPerPerson,
  };
}
