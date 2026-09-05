import 'dart:convert';
import 'dart:io' show Directory, File, Platform;

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

  // macOS uses a plain JSON file in Application Support instead of the
  // keychain: ad-hoc signed builds are not in the keychain item ACL, so macOS
  // prompts for the login password on every launch and "Always Allow" doesn't
  // stick across rebuilds. Switch back to FlutterSecureStorage on macOS once
  // the app is signed with a real Apple Developer Team ID.
  bool get _useMacFile => !kIsWeb && Platform.isMacOS;

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      preferencesKeyPrefix: 'kiduna',
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
    lOptions: LinuxOptions(),
    wOptions: WindowsOptions(),
    webOptions: WebOptions(
      dbName: 'kiduna_secure_storage',
      publicKey: 'kiduna',
    ),
  );

  // ── macOS file-based backend ───────────────────────────────────────────

  File? _cachedFile;

  Future<File> _macFile() async {
    if (_cachedFile != null) return _cachedFile!;
    final home = Platform.environment['HOME'] ?? '';
    final dir = Directory('$home/Library/Application Support/kiduna_mobile');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return _cachedFile = File('${dir.path}/auth.json');
  }

  Future<Map<String, String>> _readMacMap() async {
    final f = await _macFile();
    if (!await f.exists()) return <String, String>{};
    final raw = await f.readAsString();
    if (raw.isEmpty) return <String, String>{};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as String));
  }

  Future<void> _writeMacMap(Map<String, String> map) async {
    final f = await _macFile();
    await f.writeAsString(jsonEncode(map));
  }

  // ── Internal read/write/delete ─────────────────────────────────────────

  Future<void> _write(String key, String value) async {
    if (_useMacFile) {
      final map = await _readMacMap();
      map[key] = value;
      await _writeMacMap(map);
      return;
    }
    await _storage.write(key: key, value: value);
  }

  Future<String?> _read(String key) async {
    if (_useMacFile) {
      final map = await _readMacMap();
      return map[key];
    }
    return _storage.read(key: key);
  }

  Future<void> _delete(String key) async {
    if (_useMacFile) {
      final map = await _readMacMap();
      map.remove(key);
      await _writeMacMap(map);
      return;
    }
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

  // ── Generic key-value (for flags like wallet_disconnected) ────────────

  /// Write an arbitrary key-value pair.
  Future<void> write(String key, String value) => _write(key, value);

  /// Read an arbitrary key. Returns null if not set.
  Future<String?> read(String key) => _read(key);

  /// Delete an arbitrary key.
  Future<void> delete(String key) => _delete(key);
}
