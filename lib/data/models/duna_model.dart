import 'package:flutter/foundation.dart';

/// A single DUNA registration returned by `GET /api/v1/dunas`.
@immutable
class DunaModel {
  const DunaModel({
    required this.id,
    required this.name,
    this.ecosystemId,
    this.registration,
    required this.purpose,
    this.capacities,
    this.organizations = 0,
    this.members,
    required this.status,
    required this.isGenesis,
    this.parentId,
    this.wallet,
    this.email,
    required this.createdAt,
  });

  final String id;
  final String name;

  /// Stable ecosystem identifier — auto-generated (e.g. "ECO-A1B2C3").
  final String? ecosystemId;

  /// Legal registration string (e.g. "Kinship Duna, WV Org. ID 167085").
  final String? registration;

  /// Common, nonprofit purpose.
  final String purpose;

  /// Dot-separated capacity labels — auto-populated on creation.
  final String? capacities;

  /// Current organization count inside this ecosystem.
  final int organizations;

  /// Current member count (e.g. "0", "3").
  final String? members;

  final String status;
  final bool isGenesis;

  /// Parent DUNA id — organizations belong to the genesis ecosystem.
  final String? parentId;

  /// Creator wallet address.
  final String? wallet;

  /// Creator email.
  final String? email;

  final DateTime createdAt;

  factory DunaModel.fromJson(Map<String, dynamic> json) {
    return DunaModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      ecosystemId: json['ecosystemId'] as String?,
      registration: json['registration'] as String?,
      purpose: json['purpose'] as String? ?? '',
      capacities: json['capacities'] as String?,
      organizations: json['organizations'] as int? ?? 0,
      members: json['members'] as String?,
      status: json['status'] as String? ?? '',
      isGenesis: json['isGenesis'] as bool? ?? false,
      parentId: json['parentId'] as String?,
      wallet: json['wallet'] as String?,
      email: json['email'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// The response shape from `GET /api/v1/dunas`.
@immutable
class DunasResponse {
  const DunasResponse({
    this.genesis,
    this.organizations = const [],
    this.dunas = const [],
  });

  /// The global genesis duna visible to everyone.
  final DunaModel? genesis;

  /// Organizations registered under the genesis DUNA.
  final List<DunaModel> organizations;

  /// The caller's own dunas (excluding genesis).
  final List<DunaModel> dunas;

  factory DunasResponse.fromJson(Map<String, dynamic> json) {
    final genesisJson = json['genesis'] as Map<String, dynamic>?;
    final orgsJson = json['organizations'] as List<dynamic>? ?? [];
    final dunasJson = json['dunas'] as List<dynamic>? ?? [];
    return DunasResponse(
      genesis: genesisJson != null ? DunaModel.fromJson(genesisJson) : null,
      organizations: orgsJson
          .whereType<Map<String, dynamic>>()
          .map(DunaModel.fromJson)
          .toList(),
      dunas: dunasJson
          .whereType<Map<String, dynamic>>()
          .map(DunaModel.fromJson)
          .toList(),
    );
  }
}
