import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Web-only — SharedPreferences (backed by localStorage on web).
  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ── Internal read/write/delete ─────────────────────────────────────────

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await _getPrefs();
      await prefs.setString(key, value);
    } else {
      await _native.write(key: key, value: value);
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      final prefs = await _getPrefs();
      return prefs.getString(key);
    } else {
      return _native.read(key: key);
    }
  }

  Future<void> _delete(String key) async {
    if (kIsWeb) {
      final prefs = await _getPrefs();
      await prefs.remove(key);
    } else {
      await _native.delete(key: key);
    }
  }

  // ── Token ──────────────────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    try {
      await _write(_Keys.token, token);
      if (kDebugMode) {
        debugPrint('🔑 [Storage] Token saved (${token.length} chars)');
      }
    } catch (e, st) {
      AppLogger.error('Failed to save token', tag: 'Storage', error: e, stackTrace: st);
      throw const CacheException('Failed to save authentication token');
    }
  }

  Future<String?> getToken() async {
    try {
      final token = await _read(_Keys.token);
      if (kDebugMode) {
        debugPrint(
          '🔑 [Storage] Token read: ${token != null ? "${token.length} chars" : "null"}',
        );
      }
      return token;
    } catch (e, st) {
      AppLogger.error('Failed to read token', tag: 'Storage', error: e, stackTrace: st);
      return null;
    }
  }

  Future<void> deleteToken() async {
    try {
      await _delete(_Keys.token);
      if (kDebugMode) {
        debugPrint('🔑 [Storage] Token deleted');
      }
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
      final raw = await _storage.read(key: _Keys.user);
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
    if (kDebugMode) {
      debugPrint('🔑 [Storage] All auth data cleared');
    }
  }
}
