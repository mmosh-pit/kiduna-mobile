import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/errors/exceptions.dart';
import '../../core/utils/logger.dart';
import '../models/user_model.dart';

abstract class _Keys {
  static const String token = 'kiduna_auth_token';
  static const String user = 'kiduna_auth_user';
}

class SecureStorage {
  SecureStorage._();

  static final SecureStorage instance = SecureStorage._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      preferencesKeyPrefix: 'kiduna',
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
    mOptions: MacOsOptions(
      usesDataProtectionKeychain: false,
      accessibility: KeychainAccessibility.first_unlock,
    ),
    lOptions: LinuxOptions(),
    wOptions: WindowsOptions(),
    webOptions: WebOptions(
      dbName: 'kiduna_secure_storage',
      publicKey: 'kiduna',
    ),
  );

  // ── Internal read/write/delete ─────────────────────────────────────────

  Future<void> _write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> _read(String key) async {
    return _storage.read(key: key);
  }

  Future<void> _delete(String key) async {
    await _storage.delete(key: key);
  }

  // ── Token ──────────────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    try {
      await _write(_Keys.token, token);
      AppLogger.debug('Token saved (${token.length} chars)', tag: 'Storage');
    } catch (e, st) {
      AppLogger.error('Failed to save token', tag: 'Storage', error: e, stackTrace: st);
      throw const CacheException('Failed to save authentication token');
    }
  }

  Future<String?> getToken() async {
    try {
      final token = await _read(_Keys.token);
      AppLogger.debug(
        'Token read: ${token != null ? "${token.length} chars" : "null"}',
        tag: 'Storage',
      );
      return token;
    } catch (e, st) {
      AppLogger.error('Failed to read token', tag: 'Storage', error: e, stackTrace: st);
      return null;
    }
  }

  Future<void> deleteToken() async {
    try {
      await _delete(_Keys.token);
      AppLogger.debug('Token deleted', tag: 'Storage');
    } catch (e, st) {
      AppLogger.error('Failed to delete token', tag: 'Storage', error: e, stackTrace: st);
    }
  }

  // ── User ───────────────────────────────────────────────────────────────

  Future<void> saveUser(UserModel user) async {
    try {
      await _write(_Keys.user, jsonEncode(user.toJson()));
    } catch (e, st) {
      AppLogger.error('Failed to save user', tag: 'Storage', error: e, stackTrace: st);
      throw const CacheException('Failed to save user data');
    }
  }

  Future<UserModel?> getUser() async {
    try {
      final raw = await _read(_Keys.user);
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJson(json);
    } catch (e, st) {
      AppLogger.error('Failed to read user', tag: 'Storage', error: e, stackTrace: st);
      return null;
    }
  }

  Future<void> deleteUser() async {
    try {
      await _delete(_Keys.user);
    } catch (e, st) {
      AppLogger.error('Failed to delete user', tag: 'Storage', error: e, stackTrace: st);
    }
  }

  // ── Bulk ───────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    await deleteToken();
    await deleteUser();
    AppLogger.debug('All auth data cleared', tag: 'Storage');
  }
}
