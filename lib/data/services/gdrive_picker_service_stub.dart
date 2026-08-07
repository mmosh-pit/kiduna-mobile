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

/// Stub implementation for non-web platforms.
///
/// Google Drive Picker requires JS interop and is only available on web.
/// All methods return empty/null results on Android and iOS.
class GdrivePickerService {
  GdrivePickerService._();
  static final GdrivePickerService instance = GdrivePickerService._();

  bool get hasToken => false;

  Future<String?> signIn() async {
    AppLogger.warning(
      'GdrivePickerService is web-only',
      tag: 'GdrivePickerService',
    );
    return null;
  }

  Future<List<DrivePickedFile>> pickFiles() async => [];

  Future<List<DrivePickedFile>> signInAndPick() async => [];

  void clearToken() {}
}