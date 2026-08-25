import 'package:flutter/foundation.dart';

/// Response from `POST /realm-invites/:realmId` — the values the review
/// panel displays.
@immutable
class InvitationResponse {
  const InvitationResponse({
    required this.id,
    required this.code,
    required this.recipientName,
    required this.invitationLink,
    required this.invitationMessage,
  });

  /// Database ID of the created invite.
  final String id;

  /// The generated code string (e.g. `RLM-ABC123`).
  final String code;

  /// Recipient name echoed back from the server.
  final String recipientName;

  /// Full deep-link URL (e.g. `https://kiduna.ai/join/RLM-ABC123`).
  final String invitationLink;

  /// The formatted personal invitation message.
  final String invitationMessage;

  factory InvitationResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final code = data['code'] as String;
    final name = (data['invitedName'] as String?) ?? '';
    final realmName = (data['realmName'] as String?) ?? '';
    final url = (data['url'] as String?) ?? '';
    final role = (data['role'] as String?) ?? '';

    final message =
        'You are invited to join $realmName as ${role.isNotEmpty ? role : 'a member'}. '
        'Use the link or code below to accept.';

    return InvitationResponse(
      id: data['id'] as String,
      code: code,
      recipientName: name,
      invitationLink: url,
      invitationMessage: message,
    );
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
