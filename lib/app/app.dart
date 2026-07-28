import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../config/theme.dart';
import '../features/home/screens/home_screen.dart';
import '../l10n/app_localizations.dart';

/// Root application widget.
///
/// Configures the global [MaterialApp] — theme and title. Routing (go_router)
/// and global providers (Riverpod) are wired here as they are introduced; see
/// README → "Next steps".
class KidunaApp extends StatelessWidget {
  const KidunaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    );
  }
}
