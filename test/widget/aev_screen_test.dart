import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kiduna/app/routes.dart';
import 'package:kiduna/config/theme.dart';
import 'package:kiduna/features/field/data/field_fixtures.dart';
import 'package:kiduna/features/field/screens/aev_screen.dart';
import 'package:kiduna/features/field/widgets/enamel_icon.dart';
import 'package:kiduna/l10n/app_localizations.dart';
import 'package:kiduna/shared/widgets/app_header.dart';

const String _narrowWarning = 'Studio needs a little more room.';

GoRouter _router() => GoRouter(
  initialLocation: Routes.aev,
  routes: [GoRoute(path: Routes.aev, builder: (_, _) => const AevScreen())],
);

Future<void> _pump(WidgetTester tester, {required double width}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _router(),
      ),
    ),
  );
}

void main() {
  testWidgets('renders the header, constellation, panels, and Ki at desktop '
      'widths', (tester) async {
    await _pump(tester, width: 1400);

    expect(find.byType(AppHeader), findsOneWidget);
    expect(find.text(_narrowWarning), findsNothing);
    // Context-pill and Ki-header medallions still use EnamelIcon.
    expect(find.byType(EnamelIcon), findsNWidgets(2));
    // Constellation crests render emblem images directly via ClipOval.
    expect(find.byType(ClipOval), findsAtLeastNWidgets(34));
    // Overlaid panels + Ki content.
    expect(find.text('Atlas'), findsOneWidget);
    expect(find.text('Scene'), findsOneWidget);
    expect(find.text(FieldFixtures.computeBalance), findsOneWidget);
    expect(
      find.textContaining('Kinship Duna is the current Realm'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the reopen-wider notice below the desktop breakpoint', (
    tester,
  ) async {
    await _pump(tester, width: 900);

    expect(find.text(_narrowWarning), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
