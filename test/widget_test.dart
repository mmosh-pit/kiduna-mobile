import 'package:flutter_test/flutter_test.dart';

import 'package:kiduna_mobile/main.dart';

void main() {
  testWidgets('App renders login screen with form fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KidunaApp());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
