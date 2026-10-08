import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/data/models/chat_message_model.dart';
import 'package:kiduna/data/models/video_duration_request_model.dart';
import 'package:kiduna/features/ki_chat/controllers/ki_chat_controller.dart';

void main() {
  const message = ChatMessageModel(
    id: 'assistant_1',
    role: ChatRole.assistant,
    content: 'Choose a duration.',
    videoDurationRequest: VideoDurationRequestModel(),
  );

  test('marks a valid duration request as submitted', () {
    final updated = KiChatController.messagesWithSubmittedDuration(
      const [message],
      messageId: 'assistant_1',
      seconds: 30,
    );

    expect(updated, isNotNull);
    expect(updated!.single.videoDurationRequest!.submittedSeconds, 30);
    expect(message.videoDurationRequest!.isSubmitted, isFalse);
  });

  test('rejects invalid, missing, and repeated selections', () {
    expect(
      KiChatController.messagesWithSubmittedDuration(
        const [message],
        messageId: 'assistant_1',
        seconds: 8,
      ),
      isNull,
    );
    expect(
      KiChatController.messagesWithSubmittedDuration(
        const [message],
        messageId: 'missing',
        seconds: 30,
      ),
      isNull,
    );

    final submitted = message.copyWith(
      videoDurationRequest: const VideoDurationRequestModel(
        submittedSeconds: 30,
      ),
    );
    expect(
      KiChatController.messagesWithSubmittedDuration(
        [submitted],
        messageId: 'assistant_1',
        seconds: 40,
      ),
      isNull,
    );
  });

  test('reopens a submitted picker when generation does not start', () {
    final submitted = message.copyWith(
      videoDurationRequest: const VideoDurationRequestModel(
        submittedSeconds: 30,
      ),
    );

    final updated = KiChatController.messagesWithReopenedDuration([
      submitted,
    ], messageId: 'assistant_1');

    expect(updated, isNotNull);
    expect(updated!.single.videoDurationRequest!.isSubmitted, isFalse);
  });

  test('typed duration consumes the newest open picker', () {
    const older = ChatMessageModel(
      id: 'assistant_older',
      role: ChatRole.assistant,
      content: 'Choose a duration.',
      videoDurationRequest: VideoDurationRequestModel(),
    );
    const newer = ChatMessageModel(
      id: 'assistant_newer',
      role: ChatRole.assistant,
      content: 'Choose a duration.',
      videoDurationRequest: VideoDurationRequestModel(),
    );

    final updated = KiChatController.messagesWithLatestDurationSubmitted(const [
      older,
      newer,
    ], seconds: 8);

    expect(updated, isNotNull);
    expect(updated![0].videoDurationRequest!.isSubmitted, isFalse);
    expect(updated[1].videoDurationRequest!.submittedSeconds, 8);
  });

  test(
    'typed duration leaves picker open when no valid job duration exists',
    () {
      expect(
        KiChatController.messagesWithLatestDurationSubmitted(const [
          message,
        ], seconds: 61),
        isNull,
      );
      expect(
        KiChatController.messagesWithLatestDurationSubmitted(const [
          ChatMessageModel(
            id: 'plain',
            role: ChatRole.assistant,
            content: 'No picker.',
          ),
        ], seconds: 15),
        isNull,
      );
    },
  );
}
