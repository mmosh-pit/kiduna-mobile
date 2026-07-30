import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna_mobile/core/extensions/context_extensions.dart';

void main() {
  testWidgets('exposes theme, text, and sizing helpers', (tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(capturedContext.colors, isA<ColorScheme>());
    expect(capturedContext.textStyles, isA<TextTheme>());
    expect(capturedContext.screenWidth, greaterThan(0));
  });
}
