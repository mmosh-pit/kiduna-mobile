import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/env.dart';
import '../../core/utils/logger.dart';
import 'screens/buy_kiduna_screen.dart';
import 'screens/withdraw_screen.dart';

/// Opens the KIDUNA purchase flow.
///
/// On web the page is pushed in-app. On desktop/mobile it opens in the
/// browser, because the Stripe onramp needs a real browser context. No token
/// is passed in the URL — the web app resolves auth from its own session.
Future<void> openBuyKidunaPage(BuildContext context) async {
  if (kIsWeb) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const BuyKidunaScreen()),
    );
    return;
  }

  final base =
      Env.webAppUrl.isNotEmpty ? Env.webAppUrl : 'https://mobile.kiduna.dev';
  AppLogger.info('Opening buy page: $base/buy-kiduna', tag: 'Compute');

  final uri = Uri.parse('$base/buy-kiduna');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Opens the KIDUNA withdrawal flow.
///
/// Always ends up on the web app: withdrawing requires a signature from a
/// browser wallet extension, which only exists there. On desktop and mobile
/// this hands off to the browser rather than failing locally.
Future<void> openWithdrawPage(BuildContext context) async {
  if (kIsWeb) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WithdrawScreen()),
    );
    return;
  }

  final base =
      Env.webAppUrl.isNotEmpty ? Env.webAppUrl : 'https://mobile.kiduna.dev';
  AppLogger.info('Opening withdraw page: $base/withdraw', tag: 'Compute');

  final uri = Uri.parse('$base/withdraw');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
