import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/config/theme.dart';
import 'package:kiduna/features/field/data/design_persona.dart';
import 'package:kiduna/features/field/widgets/realm_constellation.dart';

Future<void> _pump(WidgetTester tester, {DesignPersona? persona}) async {
  tester.view.physicalSize = const Size(1400, 820);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: RealmConstellation(persona: persona ?? DesignPersona.alice),
      ),
    ),
  );
}

void main() {
  testWidgets('places a crest for every realm Alice can see', (tester) async {
    await _pump(tester);

    // Alice sees all 34 top-level realms → one ClipOval crest each.
    expect(find.byType(ClipOval), findsNWidgets(34));
    expect(find.text('Dunaversity'), findsOneWidget);
    expect(find.text('Service Alliance'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('labels each cluster', (tester) async {
    await _pump(tester);

    expect(find.text('FORMATION · WORK · ECONOMY'), findsOneWidget);
    expect(find.text('CARE · FAMILY · RELATIONSHIP'), findsOneWidget);
  });

  testWidgets('shows fewer crests for a scoped persona', (tester) async {
    await _pump(tester, persona: DesignPersona.bob);

    // Bob's curated top-level set is 9 realms.
    expect(find.byType(ClipOval), findsNWidgets(9));
    expect(tester.takeException(), isNull);
  });
}
