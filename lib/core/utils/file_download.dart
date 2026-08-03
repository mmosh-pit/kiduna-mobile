import 'package:flutter/services.dart';

import 'file_download_stub.dart'
    if (dart.library.html) 'file_download_web.dart'
    as platform;
import 'logger.dart';

/// Download a text file to the user's device.
///
/// On web: browser file download via Blob URL.
/// On native: copies content to clipboard as fallback.
///
/// Platform detection is handled by conditional import — no `kIsWeb`
/// checks leak outside this file.
abstract class FileDownload {
  const FileDownload._();

  /// Trigger a `.md` download. Returns a status message for the UI.
  static Future<String> downloadMarkdown({
    required String fileName,
    required String content,
  }) async {
    try {
      final downloaded = platform.triggerDownload(
        fileName: fileName,
        content: content,
        mimeType: 'text/markdown',
      );
      if (downloaded) {
        return '$fileName downloaded';
      }
    } catch (e) {
      AppLogger.warning(
        'Platform download failed, falling back to clipboard',
        tag: 'FileDownload',
      );
    }
    // Fallback: clipboard works everywhere.
    await Clipboard.setData(ClipboardData(text: content));
    return '$fileName copied to clipboard';
  }
}
