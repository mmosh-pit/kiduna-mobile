import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/theater_post_model.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../controllers/theater_controller.dart';
import '../widgets/theater_post_card.dart';

/// The Theater feed — videos people generated with Ki and chose to publish.
class TheaterScreen extends ConsumerStatefulWidget {
  const TheaterScreen({super.key});

  @override
  ConsumerState<TheaterScreen> createState() => _TheaterScreenState();
}

class _TheaterScreenState extends ConsumerState<TheaterScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      if (mounted) ref.read(theaterControllerProvider.notifier).loadFeed();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      ref.read(theaterControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _confirmRemove(TheaterPostModel post) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: context.l10n.removeFromTheater,
      message: context.l10n.removePostConfirm,
    );
    if (confirmed != true || !mounted) return;

    final error = await ref
        .read(theaterControllerProvider.notifier)
        .removePost(post.id);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(theaterControllerProvider);
    final controller = ref.read(theaterControllerProvider.notifier);

    return Container(
      color: context.kiduna.field,
      child: switch (state) {
        TheaterState(isLoading: true, hasLoaded: false) => const Center(
          child: CircularProgressIndicator(),
        ),
        TheaterState(error: final error?) when state.posts.isEmpty =>
          _TheaterMessage(message: error, onRetry: controller.loadFeed),
        TheaterState(posts: final posts) when posts.isEmpty => _TheaterMessage(
          message: context.l10n.theaterEmpty,
          hint: context.l10n.theaterEmptyHint,
          onRetry: controller.loadFeed,
        ),
        _ => RefreshIndicator(
          onRefresh: controller.loadFeed,
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: state.posts.length + (state.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              if (index >= state.posts.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final post = state.posts[index];
              return TheaterPostCard(
                post: post,
                canRemove: controller.isOwnPost(post),
                onRemove: () => _confirmRemove(post),
              );
            },
          ),
        ),
      },
    );
  }
}

class _TheaterMessage extends StatelessWidget {
  const _TheaterMessage({required this.message, this.hint, this.onRetry});

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
              Icons.movie_outlined,
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
