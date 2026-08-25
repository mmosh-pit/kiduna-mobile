import 'package:flutter/foundation.dart';

/// Request body for `POST /realm-invites/:realmId` — the fields from the
/// Invite panel mapped to the kinship-backend schema.
@immutable
class InvitationRequest {
  const InvitationRequest({
    required this.realmId,
    required this.recipientName,
    required this.role,
    required this.expiration,
    this.notes,
  });

  final String realmId;
  final String recipientName;
  final String role;
  final String expiration;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'role': role.toLowerCase(),
    'expires_in': expiration,
    'invited_name': recipientName,
    if (notes != null && notes!.isNotEmpty) 'label': notes,
  };
}
