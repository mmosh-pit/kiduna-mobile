import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/app/app.dart';

void main() {
  testWidgets('KidunaApp boots and shows the home screen', (tester) async {
    await tester.pumpWidget(const KidunaApp());

    expect(find.text('Kiduna'), findsWidgets);
    expect(find.textContaining('Welcome to'), findsOneWidget);
  });
}
