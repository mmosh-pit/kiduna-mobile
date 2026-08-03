import 'dart:convert';
// dart:html is needed for browser file downloads until package:web migration
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Web-only: triggers a real browser file download.
bool triggerDownload({
  required String fileName,
  required String content,
  required String mimeType,
}) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
  return true;
}
