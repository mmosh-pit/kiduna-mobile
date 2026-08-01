import 'package:flutter/foundation.dart';

/// Role of a message in a conversation.
enum ChatRole {
  user,
  assistant,
  system,
  tool;

  static ChatRole fromString(String value) {
    return ChatRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => ChatRole.assistant,
    );
  }
}

/// Delivery status of a message in the local UI.
enum ChatMessageStatus { sending, streaming, complete, error }

/// A single message in the Ki conversation thread.
///
/// Mirrors the backend's `ChatMessage` schema from
/// `GET /api/conversations/{presence_id}/{user_wallet}`.
@immutable
class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    this.timestamp,
    this.status = ChatMessageStatus.complete,
  });

  final String id;
  final ChatRole role;
  final String content;
  final String? timestamp;
  final ChatMessageStatus status;

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: (json['id'] ?? '') as String,
      role: ChatRole.fromString((json['role'] ?? 'assistant') as String),
      content: (json['content'] ?? '') as String,
      timestamp: json['timestamp'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role.name,
    'content': content,
    if (timestamp != null) 'timestamp': timestamp,
  };

  ChatMessageModel copyWith({
    String? id,
    ChatRole? role,
    String? content,
    String? timestamp,
    ChatMessageStatus? status,
    bool clearTimestamp = false,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: clearTimestamp ? null : (timestamp ?? this.timestamp),
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          role == other.role &&
          content == other.content &&
          timestamp == other.timestamp &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, role, content, timestamp, status);

  @override
  String toString() =>
      'ChatMessageModel(id: $id, role: ${role.name}, status: ${status.name})';
}
