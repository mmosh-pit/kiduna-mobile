import 'package:flutter/foundation.dart';

/// Response from `POST /api/v1/codes` — the three values the review panel
/// displays.
@immutable
class InvitationResponse {
  const InvitationResponse({
    required this.id,
    required this.code,
    required this.recipientName,
    required this.invitationLink,
    required this.invitationMessage,
  });

  /// Database ID of the created code.
  final String id;

  /// The generated code string (e.g. `KIN-ABC123-XYZ`).
  final String code;

  /// Recipient name echoed back from the server.
  final String recipientName;

  /// Full deep-link URL (e.g. `https://join.kiduna.org/k/KIN-ABC123-XYZ`).
  final String invitationLink;

  /// The formatted personal invitation message.
  final String invitationMessage;

  factory InvitationResponse.fromJson(Map<String, dynamic> json) {
    return InvitationResponse(
      id: json['id'] as String,
      code: json['code'] as String,
      recipientName: json['recipientName'] as String,
      invitationLink: json['invitationLink'] as String,
      invitationMessage: json['invitationMessage'] as String,
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
