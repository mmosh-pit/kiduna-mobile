import 'package:flutter/foundation.dart';

import '../../core/enums/skill_trigger_type.dart';

/// A Skill — versioned instructions that tell Ki how to do specific work.
///
/// Maps to the backend's `SkillResponse` (read) and `CreateSkillRequest`
/// (write). Only fields kiduna-mobile actually uses are kept here.
@immutable
class SkillModel {
  const SkillModel({
    required this.id,
    required this.name,
    required this.triggerType,
    required this.whenText,
    required this.thenText,
    this.tools = const [],
    this.skillContent,
    this.skillFilePath,
    this.requiresApproval = false,
    this.realmId,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final SkillTriggerType triggerType;
  final String whenText;
  final String thenText;
  final List<String> tools;
  final String? skillContent;
  final String? skillFilePath;
  final bool requiresApproval;
  final String? realmId;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      triggerType: SkillTriggerType.fromJson(
        (json['triggerType'] ?? json['trigger_type'] ?? 'command') as String,
      ),
      whenText: (json['whenText'] ?? json['when_text'] ?? '') as String,
      thenText: (json['thenText'] ?? json['then_text'] ?? '') as String,
      tools:
          (json['tools'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      skillContent: (json['skillContent'] ?? json['skill_content']) as String?,
      skillFilePath:
          (json['skillFilePath'] ?? json['skill_file_path']) as String?,
      requiresApproval:
          (json['requiresApproval'] ?? json['requires_approval'] ?? false)
              as bool,
      realmId: (json['realmId'] ?? json['realm_id']) as String?,
      status: (json['status'] ?? 'active') as String,
      createdAt: _tryParseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _tryParseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value as String);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'trigger_type': triggerType.toJson(),
    'when_text': whenText,
    'then_text': thenText,
    'tools': tools,
    if (skillContent != null) 'skill_content': skillContent,
    if (skillFilePath != null) 'skill_file_path': skillFilePath,
    'requires_approval': requiresApproval,
    'status': status,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };

  /// Payload for `POST /api/skills` — only the fields the create endpoint
  /// accepts.
  Map<String, dynamic> toCreateJson({required String wallet}) => {
    'name': name,
    'trigger_type': triggerType.toJson(),
    'when_text': whenText,
    'then_text': thenText,
    if (tools.isNotEmpty) 'tools': tools,
    if (skillContent != null) 'skill_content': skillContent,
    'wallet': wallet,
    'requires_approval': requiresApproval,
    if (realmId != null) 'realmId': realmId,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          triggerType == other.triggerType &&
          whenText == other.whenText &&
          thenText == other.thenText &&
          listEquals(tools, other.tools) &&
          skillContent == other.skillContent &&
          skillFilePath == other.skillFilePath &&
          requiresApproval == other.requiresApproval &&
          status == other.status;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    triggerType,
    whenText,
    thenText,
    Object.hashAll(tools),
    skillContent,
    skillFilePath,
    requiresApproval,
    status,
  );

  @override
  String toString() =>
      'SkillModel(id: $id, name: $name, trigger: $triggerType)';
}
