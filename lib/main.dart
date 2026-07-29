import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  assert(
    Env.isConfigured,
    'Missing .env config. Copy .env.example to .env and fill in the values.',
  );
  runApp(const ProviderScope(child: KidunaApp()));
}
