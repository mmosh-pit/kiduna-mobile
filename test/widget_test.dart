import 'package:flutter_test/flutter_test.dart';
<<<<<<< Updated upstream
import 'package:kiduna_mobile/app/app.dart';
=======

import 'package:kiduna/main.dart';
>>>>>>> Stashed changes

void main() {
  testWidgets('KidunaApp boots and shows the home screen', (tester) async {
    await tester.pumpWidget(const KidunaApp());

    expect(find.text('Kiduna'), findsWidgets);
    expect(find.textContaining('Welcome to'), findsOneWidget);
  });
}
