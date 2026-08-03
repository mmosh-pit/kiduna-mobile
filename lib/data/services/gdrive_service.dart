import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/utils/logger.dart';

/// MIME types the backend can ingest — matches kinship-shared's
/// INGESTIBLE_MIME_TYPES. Google Docs are exported to PDF server-side.
const kIngestibleMimeTypes = <String>{
  'application/pdf',
  'text/plain',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.google-apps.document',
};

/// Build the Drive API `mimeType` query filter for folder listing.
String _mimeFilter() =>
    kIngestibleMimeTypes.map((m) => "mimeType='$m'").join(' or ');

/// Maximum files to list from a single folder (matches kinship-shared).
const _kMaxFolderFiles = 20;

/// Maximum individual file size in bytes (5 MB, matches kinship-shared).
const kMaxDriveFileSize = 5 * 1024 * 1024;

/// A file discovered from Google Drive.
class DriveFile {
  const DriveFile({
    required this.id,
    required this.name,
    required this.mimeType,
    this.sizeBytes,
  });

  final String id;
  final String name;
  final String mimeType;
  final int? sizeBytes;

  bool get isIngestible => kIngestibleMimeTypes.contains(mimeType);

  bool get isWorkspaceFile =>
      mimeType.startsWith('application/vnd.google-apps.');

  bool get isOversized =>
      !isWorkspaceFile && sizeBytes != null && sizeBytes! > kMaxDriveFileSize;
}

/// Handles Google Sign-In and Google Drive REST API calls.
///
/// Uses `google_sign_in` for OAuth (the Flutter equivalent of GIS in
/// kinship-shared). Uses Dio for Drive REST API calls.
class GdriveService {
  GdriveService._();

  static final GdriveService instance = GdriveService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/drive.readonly'],
  );

  final Dio _driveDio = Dio(
    BaseOptions(
      baseUrl: 'https://www.googleapis.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  GoogleSignInAccount? _currentUser;

  bool get isSignedIn => _currentUser != null;

  String? get userEmail => _currentUser?.email;

  String? get userName => _currentUser?.displayName;

  /// Sign in with Google and request `drive.readonly` scope.
  ///
  /// Returns the access token on success, null on user cancellation.
  Future<String?> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser == null) {
        AppLogger.info('Google sign-in cancelled', tag: 'GdriveService');
        return null;
      }

      final auth = await _currentUser!.authentication;
      AppLogger.info('Google sign-in successful', tag: 'GdriveService');
      return auth.accessToken;
    } catch (e, st) {
      AppLogger.error(
        'Google sign-in failed',
        tag: 'GdriveService',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Sign in silently (reuse existing session). Returns access token or null.
  Future<String?> signInSilently() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser == null) return null;

      final auth = await _currentUser!.authentication;
      return auth.accessToken;
    } catch (e) {
      AppLogger.debug('Silent sign-in unavailable: $e', tag: 'GdriveService');
      return null;
    }
  }

  /// Get the current access token, refreshing if needed.
  Future<String?> getAccessToken() async {
    if (_currentUser == null) return null;

    try {
      final auth = await _currentUser!.authentication;
      return auth.accessToken;
    } catch (e) {
      AppLogger.debug(
        'Token refresh failed, re-authenticating',
        tag: 'GdriveService',
      );
      return signIn();
    }
  }

  /// Sign out of Google.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    AppLogger.info('Google sign-out', tag: 'GdriveService');
  }

  /// List files in a Google Drive folder.
  ///
  /// Matches kinship-shared's `listFilesInFolders`: queries by folder ID,
  /// filters by ingestible MIME types server-side, caps at [_kMaxFolderFiles].
  Future<List<DriveFile>> listFolderFiles({
    required String folderId,
    required String accessToken,
  }) async {
    try {
      final query =
          "'$folderId' in parents and trashed = false and (${_mimeFilter()})";

      final response = await _driveDio.get<Map<String, dynamic>>(
        '/drive/v3/files',
        queryParameters: {
          'q': query,
          'fields': 'files(id,name,mimeType,size)',
          'pageSize': _kMaxFolderFiles,
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      final files = response.data?['files'] as List<dynamic>? ?? [];
      return files.map((f) {
        final m = f as Map<String, dynamic>;
        return DriveFile(
          id: m['id'] as String? ?? '',
          name: m['name'] as String? ?? '',
          mimeType: m['mimeType'] as String? ?? '',
          sizeBytes: m['size'] != null ? int.tryParse('${m['size']}') : null,
        );
      }).toList();
    } on DioException catch (e, st) {
      AppLogger.error(
        'List folder files failed',
        tag: 'GdriveService',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  /// Get metadata for a single file by ID.
  Future<DriveFile?> getFileMetadata({
    required String fileId,
    required String accessToken,
  }) async {
    try {
      final response = await _driveDio.get<Map<String, dynamic>>(
        '/drive/v3/files/$fileId',
        queryParameters: {'fields': 'id,name,mimeType,size'},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      final m = response.data;
      if (m == null) return null;

      return DriveFile(
        id: m['id'] as String? ?? '',
        name: m['name'] as String? ?? '',
        mimeType: m['mimeType'] as String? ?? '',
        sizeBytes: m['size'] != null ? int.tryParse('${m['size']}') : null,
      );
    } on DioException catch (e, st) {
      AppLogger.error(
        'Get file metadata failed',
        tag: 'GdriveService',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Extract a file ID from a Google Drive URL.
  ///
  /// Supports:
  /// - `https://drive.google.com/file/d/{id}/...`
  /// - `https://docs.google.com/document/d/{id}/...`
  /// - `https://docs.google.com/spreadsheets/d/{id}/...`
  static String? extractFileId(String url) {
    final match = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(url);
    return match?.group(1);
  }

  /// Extract a folder ID from a Google Drive folder URL.
  ///
  /// Supports: `https://drive.google.com/drive/folders/{id}...`
  static String? extractFolderId(String url) {
    final match = RegExp(r'/folders/([a-zA-Z0-9_-]+)').firstMatch(url);
    return match?.group(1);
  }

  /// Determine whether a URL is a Drive folder or file link.
  static DriveUrlType classifyUrl(String url) {
    if (extractFolderId(url) != null) return DriveUrlType.folder;
    if (extractFileId(url) != null) return DriveUrlType.file;
    return DriveUrlType.unknown;
  }
}

/// The type of Drive URL pasted by the user.
enum DriveUrlType { folder, file, unknown }
