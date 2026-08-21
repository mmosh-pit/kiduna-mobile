import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'config/constants.dart';
import 'config/env.dart';
import 'config/theme.dart';
import 'core/network/api_client.dart';
import 'core/utils/logger.dart';
import 'data/local/secure_storage.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'l10n/app_localizations.dart';

/// Extracts an invite code from the URL on web.
/// e.g., https://kiduna.ai/join/RLM-A3Kx9M → "RLM-A3Kx9M"
///       https://kiduna.ai/#/join/RLM-A3Kx9M → "RLM-A3Kx9M"
///       https://kiduna.ai/?code=RLM-A3Kx9M → "RLM-A3Kx9M"
String? _extractInviteCodeFromUrl() {
  if (!kIsWeb) return null;
  try {
    final uri = Uri.base;
    final fullUrl = uri.toString();
    AppLogger.info('Extracting invite from URL: $fullUrl', tag: 'App');

    // Check path: /join/RLM-XXXXXX
    final path = uri.path;
    if (path.contains('/join/')) {
      final idx = path.indexOf('/join/');
      final code = path.substring(idx + 6).replaceAll('/', '').trim();
      if (code.isNotEmpty) {
        AppLogger.info('Invite code from path: $code', tag: 'App');
        return code.toUpperCase();
      }
    }

    // Check fragment (hash routing): #/join/RLM-XXXXXX
    final fragment = uri.fragment;
    if (fragment.contains('/join/')) {
      final idx = fragment.indexOf('/join/');
      final code = fragment.substring(idx + 6).replaceAll('/', '').trim();
      if (code.isNotEmpty) {
        AppLogger.info('Invite code from fragment: $code', tag: 'App');
        return code.toUpperCase();
      }
    }

    // Check full URL string as fallback (handles edge cases)
    if (fullUrl.contains('/join/')) {
      final idx = fullUrl.indexOf('/join/');
      var code = fullUrl.substring(idx + 6);
      // Remove trailing slashes, query params, fragments
      code = code.split('?').first.split('#').first.replaceAll('/', '').trim();
      if (code.isNotEmpty) {
        AppLogger.info('Invite code from full URL: $code', tag: 'App');
        return code.toUpperCase();
      }
    }

    // Check query param: ?code=RLM-XXXXXX
    final queryCode = uri.queryParameters['code'];
    if (queryCode != null && queryCode.isNotEmpty) {
      AppLogger.info('Invite code from query: $queryCode', tag: 'App');
      return queryCode.toUpperCase();
    }
  } catch (e) {
    AppLogger.warning('Failed to extract invite code from URL: $e', tag: 'App');
  }
  return null;
}

/// Global invite code extracted from URL (if any).
/// Used by SignupScreen to prefill Step 6.
String? pendingInviteCode;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use path-based URLs on web (no # hash)
  usePathUrlStrategy();

  await dotenv.load();
  assert(Env.isConfigured, 'Missing .env config. Copy .env.example to .env.');
  AppLogger.info('Environment loaded: ${Env.env}', tag: 'App');

  // Extract invite code from URL before anything renders
  pendingInviteCode = _extractInviteCodeFromUrl();

  ApiClient.instance.init(tokenProvider: SecureStorage.instance.getToken);

  runApp(const ProviderScope(child: KidunaApp()));
}

class KidunaApp extends StatelessWidget {
  const KidunaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: pendingInviteCode != null
          ? const SignupScreen()
          : const LoginScreen(),
    );
  }
}
