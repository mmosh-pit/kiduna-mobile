import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/video_job_model.dart';
import '../../../shared/widgets/theater_video_player.dart';

/// The video Ki generated for a chat message.
///
/// Renders one of three states: still rendering, failed, or a playable clip
/// with a Publish action.
class ChatVideoAttachment extends StatelessWidget {
  const ChatVideoAttachment({
    super.key,
    required this.video,
    required this.onPublish,
    this.isPublishing = false,
  });

  final VideoJobModel video;
  final Future<void> Function() onPublish;
  final bool isPublishing;

  @override
  Widget build(BuildContext context) {
    // Keyed on isReady, not status: a job can be marked ready while its URL is
    // still null, and rendering the player in that state throws on the null
    // assertion. Treat "ready but no video" as a failure the user can see.
    if (video.isReady) {
      return _ReadyCard(
        video: video,
        onPublish: onPublish,
        isPublishing: isPublishing,
      );
    }
    return switch (video.status) {
      VideoJobStatus.generating => const _GeneratingCard(),
      VideoJobStatus.ready || VideoJobStatus.failed => const _FailedCard(),
    };
  }
}

class _GeneratingCard extends StatelessWidget {
  const _GeneratingCard();

  @override
  Widget build(BuildContext context) {
    return _Frame(
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.kiduna.gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.generatingYourVideo,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.kiduna.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.thisTakesAFewMinutes,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.kiduna.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FailedCard extends StatelessWidget {
  const _FailedCard();

  @override
  Widget build(BuildContext context) {
    return _Frame(
      child: Text(
        context.l10n.videoGenerationFailed,
        style: context.textStyles.bodyMedium?.copyWith(
          color: context.kiduna.muted,
        ),
      ),
    );
  }
}

class _ReadyCard extends StatelessWidget {
  const _ReadyCard({
    required this.video,
    required this.onPublish,
    required this.isPublishing,
  });

  final VideoJobModel video;
  final Future<void> Function() onPublish;
  final bool isPublishing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: TheaterVideoPlayer(videoUrl: video.videoUrl!),
        ),
        const SizedBox(height: 8),
        _PublishAction(
          isPublished: video.isPublished,
          isPublishing: isPublishing,
          onPublish: onPublish,
        ),
      ],
    );
  }
}

class _PublishAction extends StatelessWidget {
  const _PublishAction({
    required this.isPublished,
    required this.isPublishing,
    required this.onPublish,
  });

  final bool isPublished;
  final bool isPublishing;
  final Future<void> Function() onPublish;

  @override
  Widget build(BuildContext context) {
    if (isPublished) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: context.kiduna.mint,
          ),
          const SizedBox(width: 6),
          Text(
            context.l10n.publishedToTheater,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.kiduna.mint,
            ),
          ),
        ],
      );
    }

    return TextButton.icon(
      onPressed: isPublishing ? null : () => onPublish(),
      icon: isPublishing
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.kiduna.gold,
              ),
            )
          : Icon(Icons.movie_outlined, size: 16, color: context.kiduna.gold),
      label: Text(
        isPublishing ? context.l10n.publishing : context.l10n.publishToTheater,
        style: context.textStyles.bodySmall?.copyWith(
          color: context.kiduna.gold,
        ),
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.kiduna.surface,
        borderRadius: BorderRadius.circular(context.metrics.radiusMd),
        border: Border.all(color: context.kiduna.line),
      ),
      child: child,
    );
  }
}
