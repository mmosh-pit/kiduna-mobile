import 'package:flutter/foundation.dart';

/// A prompt (system stance) for an agent.
@immutable
class PromptModel {
  const PromptModel({
    required this.id,
    required this.name,
    this.content = '',
    this.goal,
    this.tone,
    this.persona,
    this.audience,
    this.connectedKbId,
    this.connectedKbName,
    this.status = 'active',
  });

  final String id;
  final String name;
  final String content;
  final String? goal;
  final String? tone;
  final String? persona;
  final String? audience;
  final String? connectedKbId;
  final String? connectedKbName;
  final String status;

  factory PromptModel.fromJson(Map<String, dynamic> json) {
    return PromptModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      content: json['content'] as String? ?? '',
      goal: json['goal'] as String?,
      tone: json['tone'] as String?,
      persona: json['persona'] as String?,
      audience: json['audience'] as String?,
      connectedKbId: json['connectedKBId'] as String?,
      connectedKbName: json['connectedKBName'] as String?,
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'content': content,
        'goal': goal,
        'tone': tone,
        'persona': persona,
        'audience': audience,
        'connectedKbId': connectedKbId,
        'connectedKbName': connectedKbName,
        'status': status,
      };
}