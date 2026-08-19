import 'package:flutter/foundation.dart';

/// Stage of a task in the Apiary board.
///
/// Maps to the five columns: Ready → Build → Test → Release → Live.
enum TaskStage {
  ready,
  build,
  test,
  release,
  live;

  static TaskStage fromString(String value) {
    return TaskStage.values.firstWhere(
      (s) => s.name == value.toLowerCase(),
      orElse: () => TaskStage.ready,
    );
  }

  /// Human-readable label for display.
  String get label => switch (this) {
    TaskStage.ready => 'Ready',
    TaskStage.build => 'Build',
    TaskStage.test => 'Test',
    TaskStage.release => 'Release',
    TaskStage.live => 'Live',
  };

  /// Next stage in the pipeline, or `null` if already live.
  TaskStage? get next => switch (this) {
    TaskStage.ready => TaskStage.build,
    TaskStage.build => TaskStage.test,
    TaskStage.test => TaskStage.release,
    TaskStage.release => TaskStage.live,
    TaskStage.live => null,
  };
}

/// A task on the Apiary board.
///
/// Each task appears as a card in one of the five stage columns.
/// Tasks are actors — they can be tapped to send context to Ki.
@immutable
class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.stage,
    this.subtitle,
    this.description = '',
    this.category = '',
    this.assignee,
    this.assigneeWallet,
    this.estimatedHours,
    this.createdBy = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String description;
  final TaskStage stage;

  /// Sigil category — wind, compass, spark, shield, loom, portal, flower, etc.
  final String category;

  /// Display name of the person working on this task, or `null` if unassigned.
  final String? assignee;
  final String? assigneeWallet;
  final double? estimatedHours;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAssigned => assignee != null && assignee!.isNotEmpty;

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: (json['id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      subtitle: json['subtitle'] as String?,
      description: (json['description'] ?? '') as String,
      stage: TaskStage.fromString(
        (json['stage'] ?? json['status'] ?? 'ready') as String,
      ),
      category: (json['category'] ?? '') as String,
      assignee: json['assignee'] as String?,
      assigneeWallet:
          (json['assigneeWallet'] ?? json['assignee_wallet']) as String?,
      estimatedHours: _tryParseDouble(
        json['estimatedHours'] ?? json['estimated_hours'],
      ),
      createdBy: (json['createdBy'] ?? json['created_by'] ?? '') as String,
      createdAt: _tryParseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _tryParseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    if (subtitle != null) 'subtitle': subtitle,
    'description': description,
    'stage': stage.name,
    'category': category,
    if (assignee != null) 'assignee': assignee,
    if (assigneeWallet != null) 'assignee_wallet': assigneeWallet,
    if (estimatedHours != null) 'estimated_hours': estimatedHours,
    'created_by': createdBy,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };

  TaskModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    TaskStage? stage,
    String? category,
    String? assignee,
    String? assigneeWallet,
    double? estimatedHours,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearSubtitle = false,
    bool clearAssignee = false,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: clearSubtitle ? null : (subtitle ?? this.subtitle),
      description: description ?? this.description,
      stage: stage ?? this.stage,
      category: category ?? this.category,
      assignee: clearAssignee ? null : (assignee ?? this.assignee),
      assigneeWallet:
          clearAssignee ? null : (assigneeWallet ?? this.assigneeWallet),
      estimatedHours: estimatedHours ?? this.estimatedHours,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _tryParseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value as String);
  }

  static double? _tryParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          stage == other.stage &&
          category == other.category &&
          assignee == other.assignee;

  @override
  int get hashCode => Object.hash(id, title, stage, category, assignee);

  @override
  String toString() =>
      'TaskModel(id: $id, title: $title, stage: ${stage.name})';
}
