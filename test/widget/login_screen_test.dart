import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/config/theme.dart';
import 'package:kiduna/features/auth/screens/login_screen.dart';
import 'package:kiduna/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LoginScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('renders the login form with email and password fields', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to continue to Kiduna'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows email required error when submitting empty form', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Log in'));
    await tester.pump();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shows password required error when email is filled but password empty',
    (tester) async {
      await _pump(tester);

      await tester.enterText(find.byType(TextField).first, 'alice@example.com');
      await tester.tap(find.text('Log in'));
      await tester.pump();

      expect(find.text('Please enter your password'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('password field is obscured by default', (tester) async {
    await _pump(tester);

    final passwordField = tester.widget<TextField>(find.byType(TextField).last);
    expect(passwordField.obscureText, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('password visibility toggles on icon tap', (tester) async {
    await _pump(tester);

    // Initially obscured.
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isTrue,
    );

    // Tap the visibility icon.
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pump();

    // Now visible.
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });
}
