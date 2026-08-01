import 'package:flutter/foundation.dart';

/// The Ally agent profile — sourced from `GET /api/agents/ally`.
///
/// Represents the system-wide companion presence (Ki). Only the fields
/// kiduna-mobile needs are typed here; unknown keys from the backend
/// are silently ignored by [fromJson].
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
  };

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
          presenceSubtype == other.presenceSubtype;

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
  );

  @override
  String toString() =>
      'AllyAgentModel(id: $id, name: $name, handle: $handle, status: $status)';
}
