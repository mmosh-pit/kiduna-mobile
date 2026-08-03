import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/config/theme.dart';
import 'package:kiduna_mobile/features/field/screens/field_screen.dart';
import 'package:kiduna_mobile/l10n/app_localizations.dart';

Future<void> _pumpAt(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const FieldScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the side-by-side Field and Ki layout on desktop widths', (
    tester,
  ) async {
    await _pumpAt(tester, 1200);

    expect(find.byKey(const ValueKey('field-wide')), findsOneWidget);
    expect(find.byKey(const ValueKey('field-narrow')), findsNothing);
  });

  testWidgets('stacks Field over Ki on narrow widths', (tester) async {
    await _pumpAt(tester, 420);

    expect(find.byKey(const ValueKey('field-narrow')), findsOneWidget);
    expect(find.byKey(const ValueKey('field-wide')), findsNothing);
  });
}
