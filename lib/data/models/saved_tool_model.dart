import 'package:flutter/foundation.dart';

/// A tool account connected to the user's wallet via
/// `POST /api/tools/save`. Returned by `GET /api/tools/saved`.
@immutable
class SavedToolModel {
  const SavedToolModel({
    required this.id,
    required this.toolName,
    this.externalHandle,
    this.externalUserId,
    this.ownerChatId,
    this.status = 'active',
  });

  /// Backend-generated ID (e.g. `gta_xxxx`).
  final String id;

  /// Tool identifier: `bluesky`, `google`, `telegram`, `solana`.
  final String toolName;

  /// Display handle from the external service (e.g. `@user.bsky.social`).
  final String? externalHandle;

  /// External service user ID.
  final String? externalUserId;

  /// Telegram-specific: chat ID for bot messages.
  final String? ownerChatId;

  /// `active` or `disconnected`.
  final String status;

  bool get isActive => status == 'active';

  factory SavedToolModel.fromJson(Map<String, dynamic> json) {
    return SavedToolModel(
      id: (json['id'] ?? '') as String,
      toolName: (json['tool_name'] ?? json['toolName'] ?? '') as String,
      externalHandle: json['external_handle'] as String?,
      externalUserId: json['external_user_id'] as String?,
      ownerChatId: json['owner_chat_id'] as String?,
      status: (json['status'] ?? 'active') as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedToolModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SavedToolModel(id: $id, toolName: $toolName, '
      'handle: $externalHandle, status: $status)';
}
