import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/theater_post_model.dart';
import '../../../shared/widgets/theater_video_player.dart';

/// One video in the Theater feed.
class TheaterPostCard extends StatelessWidget {
  const TheaterPostCard({
    super.key,
    required this.post,
    this.canRemove = false,
    this.onRemove,
  });

  final TheaterPostModel post;
  final bool canRemove;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TheaterVideoPlayer(videoUrl: post.videoUrl),
            const SizedBox(height: 12),
            _PostMeta(post: post, canRemove: canRemove, onRemove: onRemove),
          ],
        ),
      ),
    );
  }
}

class _PostMeta extends StatelessWidget {
  const _PostMeta({
    required this.post,
    required this.canRemove,
    required this.onRemove,
  });

  final TheaterPostModel post;
  final bool canRemove;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.authorName != null && post.authorName!.isNotEmpty)
                Text(
                  post.authorName!,
                  style: context.textStyles.labelLarge?.copyWith(
                    color: context.kiduna.gold,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                post.prompt,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.kiduna.muted,
                ),
              ),
            ],
          ),
        ),
        if (canRemove)
          IconButton(
            onPressed: onRemove,
            tooltip: context.l10n.removeFromTheater,
            icon: Icon(Icons.more_horiz, size: 20, color: context.kiduna.muted),
          ),
      ],
    );
  }
}
