// Phantom is injected into the page as `window.solana`; there is no Dart
// package for it, so this talks to the extension over JS interop.
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('window')
external JSObject get _window;

/// Thin wrapper over the Phantom browser extension.
///
/// Only `signTransaction` is used — never `signAndSendTransaction`. The
/// extension broadcasts through its own RPC, which may point at a different
/// cluster than the backend; signing here and submitting server-side keeps
/// the transaction on the intended one.
class PhantomWallet {
  static JSObject? get _solana {
    if (!_window.has('solana')) return null;
    return _window.getProperty('solana'.toJS) as JSObject?;
  }

  /// True when the Phantom extension is present in this browser.
  static bool get isAvailable {
    final s = _solana;
    if (s == null) return false;
    if (!s.has('isPhantom')) return false;
    final flag = s.getProperty('isPhantom'.toJS);
    return flag != null && (flag as JSBoolean).toDart;
  }

  /// Prompt the user to connect, returning their public key.
  ///
  /// Returns null when the extension is missing or the user declines.
  static Future<String?> connect() async {
    final s = _solana;
    if (s == null) return null;

    try {
      final result = await (s.callMethod('connect'.toJS) as JSPromise).toDart;
      final obj = result as JSObject;
      if (!obj.has('publicKey')) return null;
      final pk = obj.getProperty('publicKey'.toJS) as JSObject;
      final str = pk.callMethod('toString'.toJS) as JSString;
      return str.toDart;
    } catch (_) {
      // Phantom throws when the user rejects the prompt — not an error.
      return null;
    }
  }

  /// Ask Phantom to sign a base64 transaction, returning it re-encoded.
  ///
  /// Returns null when the user rejects. The transaction already carries the
  /// admin signature; Phantom adds the fee payer's.
  static Future<String?> signTransaction(String transactionBase64) async {
    final s = _solana;
    if (s == null) return null;

    try {
      // Phantom expects a Transaction object, so the bytes are rehydrated
      // through the injected web3 helper the extension exposes.
      final signed = await (_signViaExtension(
        s,
        transactionBase64,
      ) as JSPromise)
          .toDart;
      return (signed as JSString).toDart;
    } catch (_) {
      return null;
    }
  }

  static JSAny? _signViaExtension(JSObject solana, String txBase64) {
    // Defined in web/index.html — bridges base64 <-> Transaction so the Dart
    // side never has to model Solana's wire format.
    final bridge = _window.getProperty('kidunaSignTransaction'.toJS);
    if (bridge == null) {
      throw StateError('kidunaSignTransaction bridge is not loaded');
    }
    return (bridge as JSFunction).callAsFunction(null, txBase64.toJS);
  }

  static Future<void> disconnect() async {
    final s = _solana;
    if (s == null) return;
    try {
      await (s.callMethod('disconnect'.toJS) as JSPromise).toDart;
    } catch (_) {
      // Already disconnected.
    }
  }
}
