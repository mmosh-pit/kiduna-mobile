import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/env.dart';
import '../../core/utils/logger.dart';
import 'screens/buy_kiduna_screen.dart';

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
