import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/config/theme.dart';
import 'package:kiduna_mobile/features/field/data/field_composition.dart';
import 'package:kiduna_mobile/features/field/data/realm_atlas.dart';
import 'package:kiduna_mobile/features/field/widgets/advanced_actions_panel.dart';
import 'package:kiduna_mobile/l10n/app_localizations.dart';

final _realm = realmAtlas['dunaversity']!;

final _placement = FieldPlacement(
  realm: _realm,
  left: 45,
  top: 30,
  band: FieldBand.near,
  cluster: FieldClusterId.formation,
  mass: 3,
  reason: 'Alice is the Catalyst of Dunaversity.',
  rolePull: true,
);

Future<void> _pump(WidgetTester tester, {bool isCurrent = false}) async {
  tester.view.physicalSize = const Size(600, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AdvancedActionsPanel(
            placement: _placement,
            isCurrent: isCurrent,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows realm name, type eyebrow, and purpose', (tester) async {
    await _pump(tester);

    expect(find.text('Dunaversity'), findsOneWidget);
    expect(find.textContaining('ORGANIZATION'), findsOneWidget);
    expect(find.textContaining('Learning, formation'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('displays the fact grid with role and nested count', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Catalyst'), findsOneWidget);
    expect(find.text('None stationed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the gravity control at the default level', (tester) async {
    await _pump(tester);

    expect(find.textContaining('GRAVITY'), findsOneWidget);
    expect(find.text('3 · Relevant'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the Why button when a reason exists', (tester) async {
    await _pump(tester);

    expect(find.text('Why is this here?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the Enter button for a non-current realm', (tester) async {
    await _pump(tester);

    expect(find.textContaining('Enter Dunaversity'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides the Enter button when the realm is current', (
    tester,
  ) async {
    await _pump(tester, isCurrent: true);

    expect(find.textContaining('Enter'), findsNothing);
    expect(find.textContaining('CURRENT REALM'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
