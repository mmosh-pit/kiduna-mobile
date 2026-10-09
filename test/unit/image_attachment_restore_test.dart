import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/data/models/chat_message_model.dart';
import 'package:kiduna/data/models/image_job_model.dart';
import 'package:kiduna/features/ki_chat/controllers/image_attachment_restore.dart';

void main() {
  test('restores each image onto the nearest assistant message', () {
    const messages = [
      ChatMessageModel(
        id: 'user-1',
        role: ChatRole.user,
        content: 'Draw a forest',
        timestamp: '2026-10-09T12:00:00',
      ),
      ChatMessageModel(
        id: 'assistant-1',
        role: ChatRole.assistant,
        content: 'Your image is being generated.',
        timestamp: '2026-10-09T12:00:04',
      ),
      ChatMessageModel(
        id: 'assistant-2',
        role: ChatRole.assistant,
        content: 'Your second image is being generated.',
        timestamp: '2026-10-09T12:05:04',
      ),
    ];
    final jobs = [
      ImageJobModel(
        jobId: 'image-2',
        status: ImageJobStatus.ready,
        imageUrl: 'https://example.test/second.jpg',
        createdAt: DateTime.parse('2026-10-09T12:05:00'),
      ),
      ImageJobModel(
        jobId: 'image-1',
        status: ImageJobStatus.ready,
        imageUrl: 'https://example.test/first.jpg',
        createdAt: DateTime.parse('2026-10-09T12:00:00'),
      ),
    ];

    final restored = restoreImageAttachments(messages, jobs);

    expect(restored[0].image, isNull);
    expect(restored[1].image?.jobId, 'image-1');
    expect(restored[2].image?.jobId, 'image-2');
  });

  test('ignores jobs without a nearby timestamped assistant reply', () {
    const messages = [
      ChatMessageModel(
        id: 'assistant-1',
        role: ChatRole.assistant,
        content: 'An unrelated reply',
        timestamp: '2026-10-09T12:00:00',
      ),
    ];
    final jobs = [
      ImageJobModel(
        jobId: 'image-old',
        status: ImageJobStatus.ready,
        createdAt: DateTime.parse('2026-10-09T13:00:00'),
      ),
    ];

    final restored = restoreImageAttachments(messages, jobs);

    expect(restored.single.image, isNull);
  });
}
