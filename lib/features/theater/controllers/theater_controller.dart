import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/theater_post_model.dart';
import '../../../data/services/theater_service.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../features/dashboard/controllers/ecosystem_controller.dart';
import '../../../features/field/controllers/field_controller.dart';

@immutable
class TheaterState {
  const TheaterState({
    this.posts = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.nextCursor,
    this.hasLoaded = false,
  });

  final List<TheaterPostModel> posts;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String? nextCursor;
  final bool hasLoaded;

  bool get hasMore => nextCursor != null;

  TheaterState copyWith({
    List<TheaterPostModel>? posts,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? nextCursor,
    bool? hasLoaded,
    bool clearError = false,
    bool clearCursor = false,
  }) {
    return TheaterState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

class TheaterController extends Notifier<TheaterState> {
  @override
  TheaterState build() => const TheaterState();

  String? get _realmId {
    final fieldRealmId = ref.read(fieldControllerProvider).currentRealmId;
    final ecosystemId = ref.read(ecosystemControllerProvider).ecosystem?.id;
    final useField =
        fieldRealmId.isNotEmpty &&
        fieldRealmId != 'kinship-duna' &&
        fieldRealmId != ecosystemId;
    return useField ? fieldRealmId : ecosystemId;
  }

  String? get _wallet => ref.read(authControllerProvider).user?.wallet;

  /// Load the first page, replacing whatever is on screen.
  Future<void> loadFeed() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await TheaterService.instance.fetchFeed(realmId: _realmId);
      if (!ref.mounted) return;
      state = state.copyWith(
        posts: result.posts,
        nextCursor: result.nextCursor,
        isLoading: false,
        hasLoaded: true,
        clearCursor: result.nextCursor == null,
      );
    } on AppException catch (e) {
      if (!ref.mounted) return;
      AppLogger.error('Theater feed load failed', tag: 'Theater', error: e);
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        error: e.message ?? 'Unable to load Theater.',
      );
    }
  }

  /// Append the next page.
  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final result = await TheaterService.instance.fetchFeed(
        realmId: _realmId,
        before: cursor,
      );
      if (!ref.mounted) return;
      state = state.copyWith(
        posts: [...state.posts, ...result.posts],
        nextCursor: result.nextCursor,
        isLoadingMore: false,
        clearCursor: result.nextCursor == null,
      );
    } on AppException catch (e) {
      if (!ref.mounted) return;
      AppLogger.error('Theater load-more failed', tag: 'Theater', error: e);
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Take one of the caller's own posts down and drop it from the feed.
  Future<String?> removePost(String postId) async {
    final wallet = _wallet;
    if (wallet == null || wallet.isEmpty) return 'You need to be signed in.';

    try {
      await TheaterService.instance.removePost(postId: postId, wallet: wallet);
    } on AppException catch (e) {
      return e.message ?? 'Unable to remove the post.';
    }

    if (!ref.mounted) return null;
    state = state.copyWith(
      posts: state.posts.where((p) => p.id != postId).toList(),
    );
    return null;
  }

  /// True when [post] belongs to the signed-in user.
  bool isOwnPost(TheaterPostModel post) {
    final wallet = _wallet;
    return wallet != null && wallet.isNotEmpty && post.userWallet == wallet;
  }
}

final theaterControllerProvider =
    NotifierProvider<TheaterController, TheaterState>(TheaterController.new);
