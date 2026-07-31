import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/errors/exceptions.dart';
import '../../core/utils/logger.dart';
import '../models/user_model.dart';

/// Keys used for secure-storage entries — never hardcode strings at call sites.
abstract class _Keys {
  static const String token = 'auth_token';
  static const String user = 'auth_user';
}

/// Thin wrapper around [FlutterSecureStorage] for auth persistence.
///
/// Tokens and user data are stored encrypted on-device. Use [instance] for the
/// shared singleton — never create a second FlutterSecureStorage.
class SecureStorage {
  SecureStorage._();

  static final SecureStorage instance = SecureStorage._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Token ──────────────────────────────────────────────────────────────

  /// Persist the auth token.
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

  /// Read the stored token, or `null` when none exists.
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

  /// Delete the stored token.
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

  /// Persist the user model as JSON.
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

  /// Read the stored user, or `null` when none exists or JSON is invalid.
  Future<UserModel?> getUser() async {
    try {
      final raw = await _storage.read(key: _Keys.user);
      if (raw == null || raw.isEmpty) {
        return null;
      }
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

  /// Delete the stored user.
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

  /// Clear all auth-related storage (token + user).
  Future<void> clearAll() async {
    await deleteToken();
    await deleteUser();
  }
}
