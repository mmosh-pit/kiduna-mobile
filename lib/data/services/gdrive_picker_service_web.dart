import 'dart:async';
import 'dart:js_interop';

import '../../config/env.dart';
import '../../core/utils/logger.dart';

/// A file selected from the Google Drive Picker.
class DrivePickedFile {
  const DrivePickedFile({
    required this.id,
    required this.name,
    required this.mimeType,
  });

  final String id;
  final String name;
  final String mimeType;

  bool get isFolder => mimeType == 'application/vnd.google-apps.folder';
}

/// Dart wrapper for Google Identity Services + Google Drive Picker.
///
/// Uses `dart:js_interop` to call JavaScript functions defined in
/// `web/google_picker.js`. Web-only — do not import on non-web targets.
class GdrivePickerService {
  GdrivePickerService._();
  static final GdrivePickerService instance = GdrivePickerService._();

  String? _cachedToken;

  bool get hasToken => _cachedToken != null;

  /// Sign in via Google Identity Services popup.
  ///
  /// Returns access token on success, null on cancel/error.
  Future<String?> signIn() async {
    final clientId = Env.googleClientId;
    if (clientId.isEmpty) {
      AppLogger.warning(
        'GOOGLE_CLIENT_ID not set',
        tag: 'GdrivePickerService',
      );
      return null;
    }

    final completer = Completer<String?>();

    _jsGoogleSignIn(
      clientId.toJS,
      ((JSObject result) {
        final error = (result as _JSSignInResult).error;
        final token = (result as _JSSignInResult).token;

        if (error != null) {
          AppLogger.warning(
            'Google sign-in error: $error',
            tag: 'GdrivePickerService',
          );
          completer.complete(null);
        } else if (token != null) {
          _cachedToken = token;
          AppLogger.info(
            'Google sign-in success',
            tag: 'GdrivePickerService',
          );
          completer.complete(token);
        } else {
          completer.complete(null);
        }
      }).toJS,
    );

    return completer.future;
  }

  /// Open the Google Drive Picker to select files.
  ///
  /// Uses [_cachedToken] from [signIn]. Call [signIn] first if no token.
  /// Returns list of selected files, empty list on cancel.
  Future<List<DrivePickedFile>> pickFiles() async {
    final token = _cachedToken;
    if (token == null) {
      AppLogger.warning(
        'No token — call signIn() first',
        tag: 'GdrivePickerService',
      );
      return [];
    }

    final apiKey = Env.googleApiKey;
    if (apiKey.isEmpty) {
      AppLogger.warning(
        'GOOGLE_API_KEY not set',
        tag: 'GdrivePickerService',
      );
      return [];
    }

    final completer = Completer<List<DrivePickedFile>>();

    _jsGooglePickFiles(
      token.toJS,
      apiKey.toJS,
      ((JSObject result) {
        final error = (result as _JSPickerResult).error;
        final jsFiles = (result as _JSPickerResult).files;

        if (error != null) {
          AppLogger.warning(
            'Picker error: $error',
            tag: 'GdrivePickerService',
          );
          completer.complete([]);
          return;
        }

        if (jsFiles == null) {
          completer.complete([]);
          return;
        }

        final files = <DrivePickedFile>[];
        for (var i = 0; i < jsFiles.length; i++) {
          final f = jsFiles[i] as _JSPickedFile;
          files.add(DrivePickedFile(
            id: f.id,
            name: f.name,
            mimeType: f.mimeType,
          ));
        }

        AppLogger.info(
          'Picker: ${files.length} files selected',
          tag: 'GdrivePickerService',
        );
        completer.complete(files);
      }).toJS,
    );

    return completer.future;
  }

  /// Sign in + pick files in one call.
  Future<List<DrivePickedFile>> signInAndPick() async {
    final token = _cachedToken ?? await signIn();
    if (token == null) return [];
    return pickFiles();
  }

  void clearToken() {
    _cachedToken = null;
  }
}

// ── JS interop bindings ──

@JS('googleSignIn')
external void _jsGoogleSignIn(JSString clientId, JSFunction callback);

@JS('googlePickFiles')
external void _jsGooglePickFiles(
  JSString token,
  JSString apiKey,
  JSFunction callback,
);

extension type _JSSignInResult(JSObject _) implements JSObject {
  external String? get token;
  external String? get error;
}

extension type _JSPickerResult(JSObject _) implements JSObject {
  external String? get error;
  external JSArray? get files;
}

extension type _JSPickedFile(JSObject _) implements JSObject {
  external String get id;
  external String get name;
  external String get mimeType;
}