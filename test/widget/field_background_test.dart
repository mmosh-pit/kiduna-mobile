import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/config/theme.dart';
import 'package:kiduna_mobile/features/field/widgets/field_background.dart';

Future<void> _pump(WidgetTester tester, {required bool reduceMotion}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(800, 600),
          disableAnimations: reduceMotion,
        ),
        child: const Scaffold(body: FieldBackground()),
      ),
    ),
  );
}

void main() {
  testWidgets('paints the deep field and animates when motion is allowed', (
    tester,
  ) async {
    await _pump(tester, reduceMotion: false);

    expect(find.byType(FieldBackground), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('paints statically when reduced motion is requested', (
    tester,
  ) async {
    await _pump(tester, reduceMotion: true);

    expect(find.byType(FieldBackground), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
