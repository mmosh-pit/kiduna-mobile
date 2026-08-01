/// Non-web stub — always returns false so [FileDownload] falls back to
/// clipboard. This file is replaced by `file_download_web.dart` on web
/// builds via conditional import.
bool triggerDownload({
  required String fileName,
  required String content,
  required String mimeType,
}) {
  return false;
}