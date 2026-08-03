import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import 'routes.dart';

/// Root application widget.
///
/// Configures the global [MaterialApp] — theme, localization, and routing via
/// [appRouterProvider] (go_router + auth redirect). Global providers are
/// supplied by the `ProviderScope` in `main.dart`.
class KidunaApp extends ConsumerWidget {
  const KidunaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
