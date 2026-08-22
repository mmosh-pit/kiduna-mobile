import 'package:flutter/foundation.dart';

@immutable
class AllyAgentModel {
  const AllyAgentModel({
    required this.id,
    required this.name,
    required this.handle,
    required this.description,
    required this.tagline,
    required this.wallet,
    required this.status,
    required this.isAlly,
    this.tone = '',
    this.accessLevel = '',
    this.presenceSubtype = '',
    this.systemPrompt = '',
    this.promptId = '',
    this.knowledgeBaseIds = const [],
  });

  final String id;
  final String name;
  final String handle;
  final String description;
  final String tagline;
  final String wallet;
  final String status;
  final bool isAlly;
  final String tone;
  final String accessLevel;
  final String presenceSubtype;
  final String systemPrompt;
  final String promptId;
  final List<String> knowledgeBaseIds;

  factory AllyAgentModel.fromJson(Map<String, dynamic> json) {
    return AllyAgentModel(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      handle: (json['handle'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      tagline: (json['tagline'] ?? '') as String,
      wallet: (json['wallet'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      isAlly: (json['isAlly'] ?? false) as bool,
      tone: (json['tone'] ?? '') as String,
      accessLevel: (json['accessLevel'] ?? '') as String,
      presenceSubtype: (json['presenceSubtype'] ?? '') as String,
      systemPrompt: (json['systemPrompt'] ?? '') as String,
      promptId: (json['promptId'] ?? '') as String,
      knowledgeBaseIds:
          (json['knowledgeBaseIds'] as List<dynamic>?)?.cast<String>() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'handle': handle,
    'description': description,
    'tagline': tagline,
    'wallet': wallet,
    'status': status,
    'isAlly': isAlly,
    'tone': tone,
    'accessLevel': accessLevel,
    'presenceSubtype': presenceSubtype,
    'systemPrompt': systemPrompt,
    'promptId': promptId,
    'knowledgeBaseIds': knowledgeBaseIds,
  };

  AllyAgentModel copyWith({
    String? id,
    String? name,
    String? handle,
    String? description,
    String? tagline,
    String? wallet,
    String? status,
    bool? isAlly,
    String? tone,
    String? accessLevel,
    String? presenceSubtype,
    String? systemPrompt,
    String? promptId,
    List<String>? knowledgeBaseIds,
  }) {
    return AllyAgentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      handle: handle ?? this.handle,
      description: description ?? this.description,
      tagline: tagline ?? this.tagline,
      wallet: wallet ?? this.wallet,
      status: status ?? this.status,
      isAlly: isAlly ?? this.isAlly,
      tone: tone ?? this.tone,
      accessLevel: accessLevel ?? this.accessLevel,
      presenceSubtype: presenceSubtype ?? this.presenceSubtype,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      promptId: promptId ?? this.promptId,
      knowledgeBaseIds: knowledgeBaseIds ?? this.knowledgeBaseIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AllyAgentModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          handle == other.handle &&
          description == other.description &&
          tagline == other.tagline &&
          wallet == other.wallet &&
          status == other.status &&
          isAlly == other.isAlly &&
          tone == other.tone &&
          accessLevel == other.accessLevel &&
          presenceSubtype == other.presenceSubtype &&
          systemPrompt == other.systemPrompt &&
          promptId == other.promptId &&
          listEquals(knowledgeBaseIds, other.knowledgeBaseIds);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    handle,
    description,
    tagline,
    wallet,
    status,
    isAlly,
    tone,
    accessLevel,
    presenceSubtype,
    systemPrompt,
    promptId,
    Object.hashAll(knowledgeBaseIds),
  );

  @override
  String toString() =>
      'AllyAgentModel(id: $id, name: $name, handle: $handle, status: $status)';
}
