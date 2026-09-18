import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/data/models/video_duration_request_model.dart';
import 'package:kiduna/features/ki_chat/widgets/video_duration_picker.dart';
import 'package:kiduna/l10n/app_localizations.dart';

void main() {
  Widget subject({
    VideoDurationRequestModel request = const VideoDurationRequestModel(),
    required Future<void> Function(int seconds) onGenerate,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: VideoDurationPicker(request: request, onGenerate: onGenerate),
        ),
      ),
    );
  }

  testWidgets('selects a five-second step and submits it', (tester) async {
    int? selected;
    await tester.pumpWidget(
      subject(
        request: const VideoDurationRequestModel(usdcPerSecond: 0.56),
        onGenerate: (seconds) async => selected = seconds,
      ),
    );

    expect(find.text('How long should this video be?'), findsOneWidget);
    expect(find.text('15s'), findsOneWidget);
    expect(find.text('Approx. cost: 8.40 USDC'), findsOneWidget);
    expect(find.text('5s'), findsOneWidget);
    expect(find.text('60s'), findsOneWidget);

    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(30);
    await tester.pump();
    expect(find.text('Approx. cost: 16.80 USDC'), findsOneWidget);
    expect(find.text('Generate 30s video'), findsOneWidget);

    await tester.tap(find.text('Generate 30s video'));
    await tester.pump();
    expect(selected, 30);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disables controls after submission', (tester) async {
    await tester.pumpWidget(
      subject(
        request: const VideoDurationRequestModel(submittedSeconds: 40),
        onGenerate: (_) async {},
      ),
    );

    expect(find.text('Generating 40s video\u2026'), findsOneWidget);
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('fits narrow and wide chat panels', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final width in [280.0, 1200.0]) {
      tester.view.physicalSize = Size(width, 800);
      await tester.pumpWidget(subject(onGenerate: (_) async {}));
      await tester.pump();
      expect(find.byType(VideoDurationPicker), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
