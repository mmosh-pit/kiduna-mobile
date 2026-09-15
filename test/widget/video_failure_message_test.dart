import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/data/models/video_job_model.dart';
import 'package:kiduna/features/ki_chat/widgets/chat_video_attachment.dart';
import 'package:kiduna/features/theater/widgets/my_video_card.dart';
import 'package:kiduna/l10n/app_localizations.dart';

void main() {
  Widget subject(VideoFailureReason? reason) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ChatVideoAttachment(
          video: VideoJobModel(
            jobId: 'failed-job',
            status: VideoJobStatus.failed,
            failureReason: reason,
          ),
          onPublish: () async {},
        ),
      ),
    );
  }

  testWidgets('explains that a rejected prompt should be rephrased', (
    tester,
  ) async {
    await tester.pumpWidget(subject(VideoFailureReason.promptBlocked));

    expect(find.textContaining('prompt was blocked'), findsOneWidget);
    expect(find.textContaining('Try rephrasing it'), findsOneWidget);
  });

  testWidgets('uses a generic localized message for unknown failures', (
    tester,
  ) async {
    await tester.pumpWidget(subject(null));

    expect(find.text('The video could not be generated.'), findsOneWidget);
  });

  testWidgets('shows the same prompt guidance in My Videos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 260,
            child: MyVideoCard(
              video: const VideoJobModel(
                jobId: 'failed-job',
                status: VideoJobStatus.failed,
                prompt: 'A test prompt',
                failureReason: VideoFailureReason.promptBlocked,
              ),
              isPublished: false,
              isPublishing: false,
              isDeleting: false,
              onPublish: () {},
              onDelete: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('prompt was blocked'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
