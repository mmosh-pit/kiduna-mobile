import 'package:flutter/foundation.dart';

/// The authenticated user's profile — sourced from kinship-backend's
/// `/login` and `/is-auth` responses.
///
/// Only the fields kiduna-mobile actually uses are kept here. The backend
/// returns additional keys (subscription, membership, etc.) that are
/// intentionally ignored until they are needed.
@immutable
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.wallet,
    required this.role,
  });

  final String id;
  final String email;
  final String name;
  final String wallet;
  final String role;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      name:
          (json['name'] ??
                  json['firstName'] ??
                  (json['profile'] as Map<String, dynamic>?)?['displayName'] ??
                  'User')
              as String,
      wallet: (json['wallet'] ?? '') as String,
      role: (json['role'] ?? 'member') as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'wallet': wallet,
    'role': role,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          name == other.name &&
          wallet == other.wallet &&
          role == other.role;

  @override
  int get hashCode => Object.hash(id, email, name, wallet, role);

  @override
  String toString() =>
      'UserModel(id: $id, name: $name, wallet: ${wallet.length > 12 ? '${wallet.substring(0, 12)}…' : wallet})';
}
