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

/// Web-only: attempts to close the current browser tab.
///
/// Browsers only permit `window.close()` on windows that were opened by
/// script (`window.open`). A tab the user opened — or one launched by an
/// external app — cannot be closed programmatically, so this returns false
/// and the caller should fall back to asking the user to close it manually.
bool closeWindow() {
  try {
    html.window.close();
    // If the tab is still here a moment later the close was blocked.
    return html.window.closed ?? false;
  } catch (_) {
    return false;
  }
}