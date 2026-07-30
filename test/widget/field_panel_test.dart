import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/config/theme.dart';
import 'package:kiduna_mobile/features/field/widgets/field_panel.dart';
import 'package:kiduna_mobile/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester, Widget panel) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 600,
          height: 400,
          child: Stack(children: [panel]),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the label and body when expanded', (tester) async {
    await _pump(
      tester,
      const FieldPanel(
        label: 'Compute',
        bounds: Size(600, 400),
        width: 256,
        child: Text('BODY'),
      ),
    );

    expect(find.text('Compute'), findsOneWidget);
    expect(find.text('BODY'), findsOneWidget);
  });

  testWidgets('minimize hides the body', (tester) async {
    await _pump(
      tester,
      const FieldPanel(
        label: 'Compute',
        bounds: Size(600, 400),
        width: 256,
        child: Text('BODY'),
      ),
    );

    await tester.tap(find.byTooltip('Minimize'));
    await tester.pump();

    expect(find.text('BODY'), findsNothing);
  });

  testWidgets('collapse hides the body and shows the summary', (tester) async {
    await _pump(
      tester,
      const FieldPanel(
        label: 'Compute',
        summary: 'Compute summary',
        bounds: Size(600, 400),
        width: 256,
        child: Text('BODY'),
      ),
    );

    await tester.tap(find.byTooltip('Collapse'));
    await tester.pump();

    expect(find.text('BODY'), findsNothing);
    expect(find.text('Compute summary'), findsOneWidget);
  });

  testWidgets('close invokes the callback', (tester) async {
    var closed = false;
    await _pump(
      tester,
      FieldPanel(
        label: 'Compute',
        bounds: const Size(600, 400),
        width: 256,
        onClose: () => closed = true,
        child: const Text('BODY'),
      ),
    );

    await tester.tap(find.byTooltip('Close'));
    await tester.pump();

    expect(closed, isTrue);
  });
}
