import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/config/theme.dart';
import 'package:kiduna_mobile/l10n/app_localizations.dart';
import 'package:kiduna_mobile/shared/widgets/app_header.dart';

const Key _viewKey = ValueKey('header-view-dropdown');
const Key _personaKey = ValueKey('header-persona-dropdown');
const String _aliceLabel = 'Alice — Catalyst';
const String _aevLabel = 'T1 · S1 · 1.1 — Advanced Ecosystem View (AEV)';

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(1200, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: AppHeader()),
    ),
  );
}

void main() {
  testWidgets('renders the logo and both the view and persona dropdowns', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byType(AppHeader), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsNWidgets(2));
    expect(find.byKey(_viewKey), findsOneWidget);
    expect(find.byKey(_personaKey), findsOneWidget);
    expect(find.text(_aliceLabel), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing the View keeps the selected Persona', (tester) async {
    await _pump(tester);

    // Open the View dropdown and pick the Advanced Ecosystem View.
    await tester.tap(find.byKey(_viewKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_aevLabel).last);
    await tester.pumpAndSettle();

    // View reflects the new selection; Persona is untouched.
    expect(find.text(_aevLabel), findsWidgets);
    expect(find.text(_aliceLabel), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the persona menu without error', (tester) async {
    await _pump(tester);

    await tester.tap(find.byKey(_personaKey));
    await tester.pumpAndSettle();
    expect(find.text(_aliceLabel), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('is a fixed-height bar usable at the top of any screen', (
    tester,
  ) async {
    await _pump(tester);

    final Size size = tester.getSize(find.byType(AppHeader));
    expect(size.height, 74);
  });
}
