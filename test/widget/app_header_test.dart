import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/config/theme.dart';
import 'package:kiduna_mobile/shared/widgets/app_header.dart';

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: AppHeader()),
    ),
  );
}

void main() {
  testWidgets('renders the logo lockup without error', (tester) async {
    await _pump(tester);

    expect(find.byType(AppHeader), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
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
