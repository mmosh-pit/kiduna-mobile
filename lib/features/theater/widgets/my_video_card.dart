import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/video_job_model.dart';
import '../../../shared/widgets/theater_video_player.dart';

/// One of the user's generated videos, with its publish state.
class MyVideoCard extends StatelessWidget {
  const MyVideoCard({
    super.key,
    required this.video,
    required this.isPublished,
    required this.isPublishing,
    required this.isDeleting,
    required this.onPublish,
    required this.onDelete,
  });

  final VideoJobModel video;
  final bool isPublished;
  final bool isPublishing;
  final bool isDeleting;
  final VoidCallback onPublish;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.kiduna.surface,
        borderRadius: BorderRadius.circular(context.metrics.radiusMd),
        border: Border.all(color: context.kiduna.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (video.isReady)
            TheaterVideoPlayer(videoUrl: video.videoUrl!)
          else
            _StatusBox(video: video),
          const SizedBox(height: 12),
          Text(
            video.prompt.isEmpty ? '—' : video.prompt,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.kiduna.muted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (video.isReady)
                Expanded(
                  child: _PublishRow(
                    isPublished: isPublished,
                    isPublishing: isPublishing,
                    onPublish: onPublish,
                  ),
                )
              else
                const Spacer(),
              _DeleteButton(isDeleting: isDeleting, onDelete: onDelete),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  const _StatusBox({required this.video});

  final VideoJobModel video;

  @override
  Widget build(BuildContext context) {
    final generating = video.status == VideoJobStatus.generating;
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.kiduna.deep,
          borderRadius: BorderRadius.circular(context.metrics.radiusMd),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (generating)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.kiduna.gold,
                  ),
                )
              else
                Icon(
                  Icons.error_outline,
                  size: 24,
                  color: context.kiduna.muted,
                ),
              const SizedBox(height: 12),
              Text(
                generating
                    ? context.l10n.videoStillGenerating
                    : context.l10n.videoFailed,
                textAlign: TextAlign.center,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.kiduna.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublishRow extends StatelessWidget {
  const _PublishRow({
    required this.isPublished,
    required this.isPublishing,
    required this.onPublish,
  });

  final bool isPublished;
  final bool isPublishing;
  final VoidCallback onPublish;

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
            context.l10n.onTheater,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.kiduna.mint,
            ),
          ),
        ],
      );
    }

    return TextButton.icon(
      onPressed: isPublishing ? null : onPublish,
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

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.isDeleting, required this.onDelete});

  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (isDeleting) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.kiduna.muted,
          ),
        ),
      );
    }

    return IconButton(
      onPressed: onDelete,
      tooltip: context.l10n.deleteVideo,
      visualDensity: VisualDensity.compact,
      icon: Icon(Icons.delete_outline, size: 18, color: context.kiduna.muted),
    );
  }
}
