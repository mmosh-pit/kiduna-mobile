import 'package:flutter/foundation.dart';

/// An available tool discovered from MCP servers via
/// `GET /api/tools/available`.
///
/// External tools come from connected MCP servers (Gmail, Bluesky, Solana,
/// etc.). Internal tools (Chat, Vibes) are built-in platform capabilities.
@immutable
class AvailableToolModel {
  const AvailableToolModel({
    required this.uid,
    required this.id,
    required this.name,
    this.description = '',
    this.color = '#94a3b8',
    this.category = 'External',
    this.type = 'external',
    this.isConnected = true,
    this.isDisabled = false,
  });

  /// Unique identifier used in skill tool lists and UI toggle state.
  final String uid;

  /// Service-level identifier sent to the backend in `POST /api/skills`.
  final String id;

  /// Human-readable display name (e.g. 'Read Email', 'Create Post').
  final String name;

  /// Short description shown below the tool name.
  final String description;

  /// Hex colour string for the tool icon/badge.
  final String color;

  /// Grouping label (e.g. 'Email', 'Social', 'Wallet', 'Internal').
  final String category;

  /// `'internal'` or `'external'`.
  final String type;

  /// Whether the MCP connection is active.
  final bool isConnected;

  /// Disabled tools render but cannot be toggled (e.g. 'COMING SOON').
  final bool isDisabled;

  bool get isExternal => type == 'external';

  factory AvailableToolModel.fromJson(
    Map<String, dynamic> json, {
    String defaultType = 'external',
  }) {
    return AvailableToolModel(
      uid: (json['uid'] ?? json['id'] ?? '') as String,
      id: (json['service'] ?? json['uid'] ?? json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      description: (json['desc'] ?? json['description'] ?? '') as String,
      color: (json['color'] ?? '#94a3b8') as String,
      category: (json['category'] ?? 'External') as String,
      type: (json['type'] ?? defaultType) as String,
      isConnected: (json['connected'] ?? true) as bool,
      isDisabled: (json['disabled'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'id': id,
    'name': name,
    'description': description,
    'color': color,
    'category': category,
    'type': type,
    'connected': isConnected,
    'disabled': isDisabled,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailableToolModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => Object.hash(uid, id, name);

  @override
  String toString() =>
      'AvailableToolModel(uid: $uid, name: $name, category: $category)';
}