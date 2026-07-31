import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/config/theme.dart';
import 'package:kiduna_mobile/data/models/ki_topic.dart';
import 'package:kiduna_mobile/features/field/widgets/invite_panel.dart';
import 'package:kiduna_mobile/l10n/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester, {
  ValueChanged<KiTopic>? askAbout,
}) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(child: InvitePanel(askAbout: askAbout)),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders the form with all five fields and Prepare button', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.textContaining('Name you use for them'), findsOneWidget);
    expect(find.text('Expiration'), findsOneWidget);
    expect(find.text('Proposed role'), findsOneWidget);
    expect(find.textContaining('Private handshake'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Prepare invitation'), findsOneWidget);
    expect(find.text('* Required'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('default expiration is 7 days', (tester) async {
    await _pump(tester);

    expect(find.text('7 days'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('default role is Member', (tester) async {
    await _pump(tester);

    expect(find.text('Member'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });
}
