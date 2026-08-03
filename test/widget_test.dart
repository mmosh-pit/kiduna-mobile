import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/app/app.dart';
import 'package:kiduna_mobile/features/field/screens/field_screen.dart';

void main() {
  testWidgets('KidunaApp boots into the Field', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: KidunaApp()));

    expect(find.byType(FieldScreen), findsOneWidget);
    // Ki is present in the Field.
    expect(find.text('Ki'), findsWidgets);
  });
}
