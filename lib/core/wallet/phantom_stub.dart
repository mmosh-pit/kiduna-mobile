/// Non-web stub. Browser wallet extensions only exist on web; on desktop and
/// mobile the withdrawal flow opens the web app instead of calling these.
class PhantomWallet {
  static bool get isAvailable => false;

  static Future<String?> connect() async => null;

  static Future<String?> signTransaction(String transactionBase64) async =>
      null;

  static Future<void> disconnect() async {}
}
