/// Google Drive URL parsing utilities for Wisdom Drive import.
///
/// No API calls — backend handles all Drive operations internally
/// using stored OAuth tokens from Empower with Connections.
class GdriveService {
  GdriveService._();
  static final GdriveService instance = GdriveService._();

  /// Extract a file ID from a Google Drive URL.
  static String? extractFileId(String url) {
    final match = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(url);
    return match?.group(1);
  }

  /// Extract a folder ID from a Google Drive folder URL.
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