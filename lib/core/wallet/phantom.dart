/// Browser wallet access, resolved per platform.
///
/// Phantom is a browser extension, so the real implementation exists only on
/// web. Desktop and mobile get a stub — those platforms open the web app for
/// withdrawals rather than signing locally.
export 'phantom_stub.dart' if (dart.library.js_interop) 'phantom_web.dart';
