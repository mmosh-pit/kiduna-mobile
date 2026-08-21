import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/shared/layouts/responsive_layout.dart';

Future<void> _pumpAt(
  WidgetTester tester,
  double width, {
  WidgetBuilder? tablet,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ResponsiveLayout(
          mobile: (_) => const Text('mobile'),
          tablet: tablet,
          desktop: (_) => const Text('desktop'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders the mobile builder below the tablet breakpoint', (
    tester,
  ) async {
    await _pumpAt(tester, 420, tablet: (_) => const Text('tablet'));
    expect(find.text('mobile'), findsOneWidget);
  });

  testWidgets('renders the tablet builder between the breakpoints', (
    tester,
  ) async {
    await _pumpAt(tester, 800, tablet: (_) => const Text('tablet'));
    expect(find.text('tablet'), findsOneWidget);
  });

  testWidgets('renders the desktop builder at desktop widths', (tester) async {
    await _pumpAt(tester, 1200, tablet: (_) => const Text('tablet'));
    expect(find.text('desktop'), findsOneWidget);
  });

  testWidgets('falls back to the desktop builder when no tablet is given', (
    tester,
  ) async {
    await _pumpAt(tester, 800);
    expect(find.text('desktop'), findsOneWidget);
  });
}
