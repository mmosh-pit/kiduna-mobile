import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kiduna_mobile/app/routes.dart';
import 'package:kiduna_mobile/config/theme.dart';
import 'package:kiduna_mobile/l10n/app_localizations.dart';
import 'package:kiduna_mobile/shared/widgets/app_header.dart';

const Key _viewKey = ValueKey('header-view-dropdown');
const Key _personaKey = ValueKey('header-persona-dropdown');
const String _aliceLabel = 'Alice — Catalyst';
const String _ncevLabel = 'T1 · S1 · 1.0 — Newly Created Ecosystem View (NCEV)';
const String _aevLabel = 'T1 · S1 · 1.1 — Advanced Ecosystem View (AEV)';

/// A minimal router that renders the header on both the Field and AEV paths so
/// the View dropdown can navigate between them.
GoRouter _buildRouter() => GoRouter(
  initialLocation: Routes.field,
  routes: [
    GoRoute(
      path: Routes.field,
      builder: (_, _) => const Scaffold(body: AppHeader()),
    ),
    GoRoute(
      path: Routes.aev,
      builder: (_, _) => const Scaffold(body: AppHeader()),
    ),
  ],
);

Future<GoRouter> _pump(
  WidgetTester tester, {
  Size size = const Size(1200, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = _buildRouter();
  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
  return router;
}

void main() {
  testWidgets('renders the logo and the view and persona dropdowns', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byType(AppHeader), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsNWidgets(2));
    expect(find.byKey(_viewKey), findsOneWidget);
    expect(find.byKey(_personaKey), findsOneWidget);
    expect(find.text(_ncevLabel), findsWidgets);
    expect(find.text(_aliceLabel), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting the AEV view navigates and keeps the persona', (
    tester,
  ) async {
    final router = await _pump(tester);
    expect(router.routerDelegate.currentConfiguration.uri.path, Routes.field);

    await tester.tap(find.byKey(_viewKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_aevLabel).last);
    await tester.pumpAndSettle();

    // Navigated to the AEV route; persona is untouched by the View change.
    expect(router.routerDelegate.currentConfiguration.uri.path, Routes.aev);
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
