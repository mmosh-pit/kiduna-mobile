import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import 'routes.dart';

/// Root application widget.
///
/// Configures the global [MaterialApp] — theme, localization, and routing via
/// [appRouter] (go_router). Global providers are supplied by the `ProviderScope`
/// in `main.dart`.
class KidunaApp extends StatelessWidget {
  const KidunaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: appRouter,
    );
  }
}
