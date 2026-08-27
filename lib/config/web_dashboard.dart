import 'package:flutter/foundation.dart' show kIsWeb;

/// Whether the web build may reach the dashboard.
///
/// The web app normally sends a signed-in user to the download page, because
/// the product is a mobile/desktop app and the browser build exists to get
/// people to it. That makes the dashboard — and everything behind it, including
/// tournaments — unreachable in a browser, so end-to-end tests cannot drive it.
///
/// Building with `--dart-define=WEB_DASHBOARD=true` lets the browser through.
/// Off by default, so production web is unchanged.
const bool _webDashboardOverride = bool.fromEnvironment('WEB_DASHBOARD');

/// True when a signed-in user should be sent to the download page instead of
/// the dashboard.
bool get sendWebUsersToDownload => kIsWeb && !_webDashboardOverride;
