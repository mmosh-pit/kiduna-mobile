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
import 'features/auth/screens/user_profile_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/compute/screens/buy_kiduna_screen.dart';
import 'features/compute/screens/withdraw_screen.dart';
import 'features/compute/screens/lineage_withdraw_screen.dart';
import 'features/compute/screens/compute_details_screen.dart';
import 'l10n/app_localizations.dart';

/// Extracts an invite code from the URL on web.
///
/// Supported formats:
///   https://kiduna.ai/{handle}/code/{CODE}  → new format (also sets pendingInviteHandle)
///   https://kiduna.ai/join/{CODE}           → legacy format
///   https://kiduna.ai/?code={CODE}          → query param fallback
String? _extractInviteCodeFromUrl() {
  if (!kIsWeb) return null;
  try {
    final uri = Uri.base;
    final fullUrl = uri.toString();
    AppLogger.info('Extracting invite from URL: $fullUrl', tag: 'App');

    // ── New format: /{handle}/code/{CODE} ──
    final path = uri.path;
    final codeIdx = path.indexOf('/code/');
    if (codeIdx > 0) {
      // Everything before /code/ is the handle (strip leading /)
      final handle = path.substring(1, codeIdx).trim();
      final code =
          path.substring(codeIdx + 6).replaceAll('/', '').trim();
      if (handle.isNotEmpty && code.isNotEmpty) {
        pendingInviteHandle = handle;
        AppLogger.info(
          'Invite from URL: handle=$handle, code=$code',
          tag: 'App',
        );
        return code.toUpperCase();
      }
    }

    // ── Hash-routing: #/{handle}/code/{CODE} ──
    final fragment = uri.fragment;
    final fragCodeIdx = fragment.indexOf('/code/');
    if (fragCodeIdx > 0) {
      var handlePart = fragment.substring(0, fragCodeIdx);
      if (handlePart.startsWith('/')) handlePart = handlePart.substring(1);
      final code =
          fragment.substring(fragCodeIdx + 6).replaceAll('/', '').trim();
      if (handlePart.isNotEmpty && code.isNotEmpty) {
        pendingInviteHandle = handlePart;
        AppLogger.info(
          'Invite from fragment: handle=$handlePart, code=$code',
          tag: 'App',
        );
        return code.toUpperCase();
      }
    }

    // ── Legacy format: /join/{CODE} ──
    if (path.contains('/join/')) {
      final idx = path.indexOf('/join/');
      final code = path.substring(idx + 6).replaceAll('/', '').trim();
      if (code.isNotEmpty) {
        AppLogger.info('Invite code from path: $code', tag: 'App');
        return code.toUpperCase();
      }
    }

    if (fragment.contains('/join/')) {
      final idx = fragment.indexOf('/join/');
      final code = fragment.substring(idx + 6).replaceAll('/', '').trim();
      if (code.isNotEmpty) {
        AppLogger.info('Invite code from fragment: $code', tag: 'App');
        return code.toUpperCase();
      }
    }

    // ── Full URL fallback for /code/ ──
    final fullCodeIdx = fullUrl.indexOf('/code/');
    if (fullCodeIdx > 0) {
      var code = fullUrl.substring(fullCodeIdx + 6);
      code = code.split('?').first.split('#').first.replaceAll('/', '').trim();
      if (code.isNotEmpty) {
        AppLogger.info('Invite code from full URL: $code', tag: 'App');
        return code.toUpperCase();
      }
    }

    // ── Full URL fallback for /join/ ──
    if (fullUrl.contains('/join/')) {
      final idx = fullUrl.indexOf('/join/');
      var code = fullUrl.substring(idx + 6);
      code = code.split('?').first.split('#').first.replaceAll('/', '').trim();
      if (code.isNotEmpty) {
        AppLogger.info('Invite code from full URL: $code', tag: 'App');
        return code.toUpperCase();
      }
    }

    // ── Query param: ?code=RLM-XXXXXX ──
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

/// Inviter's handle from the URL (if /{handle}/code/{CODE} format).
/// Used by InviteLandingScreen to display the inviter context.
String? pendingInviteHandle;

/// True when the app is launched at /buy-kiduna (web).
/// Auth is resolved from the existing browser session, never from the URL.
bool isBuyKidunaRoute = false;
bool isWithdrawRoute = false;
bool isLineageWithdrawRoute = false;
bool isComputeDetailsRoute = false;

/// Detects the /buy-kiduna route.
void _detectBuyKidunaRoute() {
  if (!kIsWeb) return;
  try {
    final uri = Uri.base;
    final full = uri.toString();
    if (uri.path.contains('/buy-kiduna') ||
        uri.fragment.contains('/buy-kiduna') ||
        full.contains('/buy-kiduna')) {
      isBuyKidunaRoute = true;
      AppLogger.info('Buy KIDUNA route detected', tag: 'App');
    } else if (uri.path.contains('/compute-details') ||
        uri.fragment.contains('/compute-details') ||
        full.contains('/compute-details')) {
      isComputeDetailsRoute = true;
      AppLogger.info('Compute details route detected', tag: 'App');
    } else if (uri.path.contains('/lineage-withdraw') ||
        uri.fragment.contains('/lineage-withdraw') ||
        full.contains('/lineage-withdraw')) {
      isLineageWithdrawRoute = true;
      AppLogger.info('Lineage withdraw route detected', tag: 'App');
    } else if (uri.path.contains('/withdraw') ||
        uri.fragment.contains('/withdraw') ||
        full.contains('/withdraw')) {
      isWithdrawRoute = true;
      AppLogger.info('Withdraw route detected', tag: 'App');
    }
  } catch (e) {
    AppLogger.warning('Failed to detect buy-kiduna route: $e', tag: 'App');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use path-based URLs on web (no # hash)
  usePathUrlStrategy();

  await dotenv.load();
  assert(Env.isConfigured, 'Missing .env config. Copy .env.example to .env.');
  AppLogger.info('Environment loaded: ${Env.env}', tag: 'App');

  // Route detection from URL before anything renders
  _detectBuyKidunaRoute();
  if (!isBuyKidunaRoute && !isWithdrawRoute && !isLineageWithdrawRoute && !isComputeDetailsRoute) {
    pendingInviteCode = _extractInviteCodeFromUrl();
  }

  AppLogger.info(
    'Route resolution: inviteCode=$pendingInviteCode, '
    'handle=$pendingInviteHandle, '
    'buyKiduna=$isBuyKidunaRoute, '
    'withdraw=$isWithdrawRoute, '
    'lineageWithdraw=$isLineageWithdrawRoute, '
    'computeDetails=$isComputeDetailsRoute, '
    'uri=${kIsWeb ? Uri.base.toString() : "non-web"}',
    tag: 'App',
  );

  ApiClient.instance.init(tokenProvider: SecureStorage.instance.getToken);

  runApp(const ProviderScope(child: KidunaApp()));
}

class KidunaApp extends StatelessWidget {
  const KidunaApp({super.key});

  Widget _resolveHome() {
    if (isBuyKidunaRoute) {
      return const BuyKidunaScreen();
    }
    if (isComputeDetailsRoute) {
      return const ComputeDetailsScreen();
    }
    if (isLineageWithdrawRoute) {
      return const LineageWithdrawScreen();
    }
    if (isWithdrawRoute) {
      return const WithdrawScreen();
    }
    if (pendingInviteCode != null) {
      return UserProfileScreen(
        handle: pendingInviteHandle ?? '',
        inviteCode: pendingInviteCode,
      );
    }
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: _resolveHome(),
    );
  }
}