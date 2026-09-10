import 'package:flutter/foundation.dart';

import 'video_job_model.dart';

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

enum ChatMessageStatus { sending, streaming, complete, error }

@immutable
class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    this.timestamp,
    this.status = ChatMessageStatus.complete,
    this.video,
  });

  final String id;
  final ChatRole role;
  final String content;
  final String? timestamp;
  final ChatMessageStatus status;

  /// A video Ki generated for this message, if any. Present from the moment
  /// generation starts, so the bubble can show progress before the clip exists.
  final VideoJobModel? video;

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
    VideoJobModel? video,
    bool clearTimestamp = false,
    bool clearVideo = false,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: clearTimestamp ? null : (timestamp ?? this.timestamp),
      status: status ?? this.status,
      video: clearVideo ? null : (video ?? this.video),
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
          status == other.status &&
          video == other.video;

  @override
  int get hashCode => Object.hash(id, role, content, timestamp, status, video);

  @override
  String toString() =>
      'ChatMessageModel(id: $id, role: ${role.name}, status: ${status.name})';
}
