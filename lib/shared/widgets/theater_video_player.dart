import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/utils/logger.dart';

/// Plays one Theater clip.
///
/// Owns its own [Player], so each instance is independent — a feed can mount
/// several and only the ones the user starts will play.
class TheaterVideoPlayer extends StatefulWidget {
  const TheaterVideoPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.loop = true,
    this.aspectRatio = 9 / 16,
  });

  final String videoUrl;
  final bool autoPlay;
  final bool loop;
  final double aspectRatio;

  @override
  State<TheaterVideoPlayer> createState() => _TheaterVideoPlayerState();
}

class _TheaterVideoPlayerState extends State<TheaterVideoPlayer> {
  late final Player _player;
  late final VideoController _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _open();
  }

  Future<void> _open() async {
    try {
      await _player.open(Media(widget.videoUrl), play: widget.autoPlay);
      await _player.setPlaylistMode(
        widget.loop ? PlaylistMode.loop : PlaylistMode.none,
      );
    } catch (e, st) {
      AppLogger.error(
        'Failed to open video',
        tag: 'TheaterVideoPlayer',
        error: e,
        stackTrace: st,
      );
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(TheaterVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _failed = false;
      _open();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(context.metrics.radiusMd);

    if (_failed) {
      return _VideoUnavailable(radius: radius, aspectRatio: widget.aspectRatio);
    }

    return ClipRRect(
      borderRadius: radius,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Video(
          controller: _controller,
          controls: AdaptiveVideoControls,
          fill: context.kiduna.deep,
        ),
      ),
    );
  }
}

class _VideoUnavailable extends StatelessWidget {
  const _VideoUnavailable({required this.radius, required this.aspectRatio});

  final BorderRadius radius;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.kiduna.surface,
          borderRadius: radius,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.l10n.videoUnavailable,
              textAlign: TextAlign.center,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.kiduna.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
