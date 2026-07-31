import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'config/env.dart';
import 'core/network/api_client.dart';
import 'data/local/secure_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  assert(
    Env.isConfigured,
    'Missing .env config. Copy .env.example to .env and fill in the values.',
  );

  // Initialise the shared HTTP client. The token provider reads from secure
  // storage — this keeps the interceptor decoupled from auth state.
  ApiClient.instance.init(tokenProvider: SecureStorage.instance.getToken);

  runApp(const ProviderScope(child: KidunaApp()));
}
