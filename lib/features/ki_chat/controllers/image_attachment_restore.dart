import '../../../data/models/chat_message_model.dart';
import '../../../data/models/image_job_model.dart';

/// Reattach durable image jobs to their nearest assistant chat turn.
///
/// Conversation rows currently store text only. Image jobs are created during
/// the assistant turn, so their creation timestamp is the best durable link
/// available until chat messages carry an explicit media job ID.
List<ChatMessageModel> restoreImageAttachments(
  List<ChatMessageModel> messages,
  List<ImageJobModel> jobs,
) {
  if (messages.isEmpty || jobs.isEmpty) return messages;

  final restored = [...messages];
  final claimed = <int>{};

  for (final job in jobs) {
    final jobTime = job.createdAt;
    if (jobTime == null) continue;

    var bestIndex = -1;
    Duration? bestGap;
    for (var index = 0; index < restored.length; index++) {
      if (claimed.contains(index)) continue;
      final message = restored[index];
      if (message.role != ChatRole.assistant) continue;
      final messageTime = DateTime.tryParse(message.timestamp ?? '');
      if (messageTime == null) continue;
      final gap = messageTime.difference(jobTime).abs();
      if (gap > const Duration(minutes: 10)) continue;
      if (bestGap == null || gap < bestGap) {
        bestGap = gap;
        bestIndex = index;
      }
    }

    if (bestIndex == -1) continue;
    claimed.add(bestIndex);
    restored[bestIndex] = restored[bestIndex].copyWith(image: job);
  }

  return restored;
}
