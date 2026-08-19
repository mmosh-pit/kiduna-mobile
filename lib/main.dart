import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/constants.dart';
import 'config/env.dart';
import 'config/theme.dart';
import 'core/network/api_client.dart';
import 'core/utils/logger.dart';
import 'data/local/secure_storage.dart';
import 'features/auth/screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();
  assert(Env.isConfigured, 'Missing .env config. Copy .env.example to .env.');
  AppLogger.info('Environment loaded: ${Env.env}', tag: 'App');

  ApiClient.instance.init(tokenProvider: SecureStorage.instance.getToken);

  runApp(const ProviderScope(child: KidunaApp()));
}

class KidunaApp extends StatelessWidget {
  const KidunaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const LoginScreen(),
    );
  }
}
