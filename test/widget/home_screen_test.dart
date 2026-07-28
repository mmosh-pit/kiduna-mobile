import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/features/home/screens/home_screen.dart';

void main() {
  testWidgets('renders the welcome content', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.textContaining('Welcome to'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });
}
