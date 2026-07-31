import 'package:flutter/foundation.dart';

/// Request body for `POST /api/v1/codes` — the six fields from the Invite
/// panel plus the logged-in user's wallet.
@immutable
class InvitationRequest {
  const InvitationRequest({
    required this.wallet,
    required this.recipientName,
    required this.role,
    required this.expiration,
    this.handshake,
    this.notes,
  });

  final String wallet;
  final String recipientName;
  final String role;
  final String expiration;
  final String? handshake;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'wallet': wallet,
    'recipientName': recipientName,
    'role': role,
    'expiration': expiration,
    if (handshake != null && handshake!.isNotEmpty) 'handshake': handshake,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
  };
}
