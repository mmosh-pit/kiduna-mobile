import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../controllers/my_videos_controller.dart';
import '../widgets/my_video_card.dart';

/// Every video the signed-in user has generated with Ki.
///
/// Opened from the account menu. Chat only holds an attachment in memory, so
/// this is the durable place a generated clip can be found and published.
class MyVideosScreen extends ConsumerStatefulWidget {
  const MyVideosScreen({super.key});

  @override
  ConsumerState<MyVideosScreen> createState() => _MyVideosScreenState();
}

class _MyVideosScreenState extends ConsumerState<MyVideosScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(myVideosControllerProvider.notifier).load();
    });
  }

  Future<void> _publish(String jobId) async {
    final error = await ref
        .read(myVideosControllerProvider.notifier)
        .publish(jobId);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _confirmDelete(String jobId) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: context.l10n.deleteVideo,
      message: context.l10n.deleteVideoConfirm,
      confirmLabel: context.l10n.delete,
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    final error = await ref
        .read(myVideosControllerProvider.notifier)
        .delete(jobId);
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error ?? context.l10n.videoDeleted)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myVideosControllerProvider);
    final controller = ref.read(myVideosControllerProvider.notifier);

    return Scaffold(
      backgroundColor: context.kiduna.field,
      appBar: AppBar(
        backgroundColor: context.kiduna.deep,
        foregroundColor: context.kiduna.cream,
        title: Text(context.l10n.myVideos),
      ),
      body: switch (state) {
        MyVideosState(isLoading: true, hasLoaded: false) => const Center(
          child: CircularProgressIndicator(),
        ),
        MyVideosState(error: final error?) when state.videos.isEmpty =>
          _Message(message: error, onRetry: controller.load),
        MyVideosState(videos: final videos) when videos.isEmpty => _Message(
          message: context.l10n.myVideosEmpty,
          hint: context.l10n.myVideosEmptyHint,
          onRetry: controller.load,
        ),
        _ => RefreshIndicator(
          onRefresh: controller.load,
          child: _VideoGrid(
            state: state,
            onPublish: _publish,
            onDelete: _confirmDelete,
          ),
        ),
      },
    );
  }
}

/// Reflows from one column on a phone to a grid on wider screens.
class _VideoGrid extends StatelessWidget {
  const _VideoGrid({
    required this.state,
    required this.onPublish,
    required this.onDelete,
  });

  final MyVideosState state;
  final Future<void> Function(String jobId) onPublish;
  final Future<void> Function(String jobId) onDelete;

  @override
  Widget build(BuildContext context) {
    final columns = context.screenWidth >= 1024
        ? 3
        : context.screenWidth >= 600
        ? 2
        : 1;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.52,
      ),
      itemCount: state.videos.length,
      itemBuilder: (context, index) {
        final video = state.videos[index];
        return MyVideoCard(
          // Keyed on the job so the player isn't rebuilt when the list
          // changes — same reason the chat thread keys its items.
          key: ValueKey('my_video_${video.jobId}'),
          video: video,
          isPublished: state.publishedJobIds.contains(video.jobId),
          isPublishing: state.publishingJobId == video.jobId,
          isDeleting: state.deletingJobId == video.jobId,
          onPublish: () => onPublish(video.jobId),
          onDelete: () => onDelete(video.jobId),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, this.hint, this.onRetry});

  final String message;
  final String? hint;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 48,
              color: context.kiduna.gold.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.textStyles.bodyLarge?.copyWith(
                color: context.kiduna.text,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 8),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.kiduna.muted,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onRetry,
                child: Text(context.l10n.tryAgain),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
