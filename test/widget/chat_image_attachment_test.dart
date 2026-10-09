import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/data/models/image_job_model.dart';
import 'package:kiduna/features/ki_chat/widgets/chat_image_attachment.dart';
import 'package:kiduna/l10n/app_localizations.dart';

void main() {
  Widget subject(ImageJobModel image) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: ChatImageAttachment(image: image)),
    );
  }

  testWidgets('shows progress while HiDream is running', (tester) async {
    await tester.pumpWidget(
      subject(
        const ImageJobModel(
          jobId: 'image-1',
          status: ImageJobStatus.generating,
        ),
      ),
    );

    expect(find.text('Generating your image…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows a localized out-of-memory failure', (tester) async {
    await tester.pumpWidget(
      subject(
        const ImageJobModel(
          jobId: 'image-2',
          status: ImageJobStatus.failed,
          failureReason: ImageFailureReason.modelOutOfMemory,
        ),
      ),
    );

    expect(find.textContaining('ran out of memory'), findsOneWidget);
  });

  testWidgets('falls back to an HTML image when web CORS blocks decoding', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(
        const ImageJobModel(
          jobId: 'image-3',
          status: ImageJobStatus.ready,
          imageUrl: 'https://storage.googleapis.com/example/image.jpg',
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as NetworkImage;
    expect(provider.webHtmlElementStrategy, WebHtmlElementStrategy.fallback);
  });
}
