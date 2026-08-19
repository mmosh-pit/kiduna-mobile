import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/errors/exceptions.dart';
import '../../core/utils/logger.dart';
import '../models/user_model.dart';

abstract class _Keys {
  static const String token = 'auth_token';
  static const String user = 'auth_user';
}

class SecureStorage {
  SecureStorage._();

  static final SecureStorage instance = SecureStorage._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ── Token ──────────────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _Keys.token, value: token);
    } catch (e, st) {
      AppLogger.error(
        'Failed to save token',
        tag: 'Storage',
        error: e,
        stackTrace: st,
      );
      throw const CacheException('Failed to save authentication token');
    }
  }

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _Keys.token);
    } catch (e, st) {
      AppLogger.error(
        'Failed to read token',
        tag: 'Storage',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: _Keys.token);
    } catch (e, st) {
      AppLogger.error(
        'Failed to delete token',
        tag: 'Storage',
        error: e,
        stackTrace: st,
      );
    }
  }

  // ── User ───────────────────────────────────────────────────────────────

  Future<void> saveUser(UserModel user) async {
    try {
      final json = jsonEncode(user.toJson());
      await _storage.write(key: _Keys.user, value: json);
    } catch (e, st) {
      AppLogger.error(
        'Failed to save user',
        tag: 'Storage',
        error: e,
        stackTrace: st,
      );
      throw const CacheException('Failed to save user data');
    }
  }

  Future<UserModel?> getUser() async {
    try {
      final raw = await _storage.read(key: _Keys.user);
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJson(json);
    } catch (e, st) {
      AppLogger.error(
        'Failed to read user',
        tag: 'Storage',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<void> deleteUser() async {
    try {
      await _storage.delete(key: _Keys.user);
    } catch (e, st) {
      AppLogger.error(
        'Failed to delete user',
        tag: 'Storage',
        error: e,
        stackTrace: st,
      );
    }
  }

  // ── Bulk ───────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    await deleteToken();
    await deleteUser();
  }
}
