import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/video_job_model.dart';
import '../../../data/services/theater_service.dart';
import '../../../features/auth/controllers/auth_controller.dart';

@immutable
class MyVideosState {
  const MyVideosState({
    this.videos = const [],
    this.publishedJobIds = const {},
    this.isLoading = false,
    this.error,
    this.hasLoaded = false,
    this.publishingJobId,
    this.deletingJobId,
  });

  final List<VideoJobModel> videos;

  /// Jobs that already have a Theater post, so the button reads as published.
  final Set<String> publishedJobIds;

  final bool isLoading;
  final String? error;
  final bool hasLoaded;

  /// The job currently being published, for a per-row spinner.
  final String? publishingJobId;

  /// The job currently being deleted, so its row can show progress.
  final String? deletingJobId;

  MyVideosState copyWith({
    List<VideoJobModel>? videos,
    Set<String>? publishedJobIds,
    bool? isLoading,
    String? error,
    bool? hasLoaded,
    String? publishingJobId,
    String? deletingJobId,
    bool clearError = false,
    bool clearPublishingJobId = false,
    bool clearDeletingJobId = false,
  }) {
    return MyVideosState(
      videos: videos ?? this.videos,
      publishedJobIds: publishedJobIds ?? this.publishedJobIds,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      hasLoaded: hasLoaded ?? this.hasLoaded,
      publishingJobId: clearPublishingJobId
          ? null
          : (publishingJobId ?? this.publishingJobId),
      deletingJobId: clearDeletingJobId
          ? null
          : (deletingJobId ?? this.deletingJobId),
    );
  }
}

/// Every video the signed-in user has generated — the durable home for clips
/// that chat only holds in memory.
class MyVideosController extends Notifier<MyVideosState> {
  @override
  MyVideosState build() => const MyVideosState();

  String? get _wallet => ref.read(authControllerProvider).user?.wallet;

  Future<void> load() async {
    final wallet = _wallet;
    if (wallet == null || wallet.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        error: 'You need to be signed in.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final videos = await TheaterService.instance.fetchMyJobs(wallet: wallet);

      // Which of these are already on Theater. A failure here shouldn't hide
      // the videos themselves, so it degrades to "none known published".
      var published = <String>{};
      try {
        final posts = await TheaterService.instance.fetchMyPosts(
          wallet: wallet,
        );
        published = posts
            .where((p) => !p.isRemoved)
            .map((p) => p.assetId)
            .whereType<String>()
            .toSet();
      } on AppException catch (e) {
        AppLogger.warning(
          'Could not load published posts: ${e.message}',
          tag: 'MyVideos',
        );
      }

      if (!ref.mounted) return;

      // Posts reference assets, jobs reference the same asset — match on that.
      final publishedJobIds = videos
          .where((v) => v.assetId != null && published.contains(v.assetId))
          .map((v) => v.jobId)
          .toSet();

      state = state.copyWith(
        videos: videos,
        publishedJobIds: publishedJobIds,
        isLoading: false,
        hasLoaded: true,
      );
    } on AppException catch (e) {
      if (!ref.mounted) return;
      AppLogger.error('My videos load failed', tag: 'MyVideos', error: e);
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        error: e.message ?? 'Unable to load your videos.',
      );
    }
  }

  /// Publish one video to Theater.
  ///
  /// Returns null on success, or a message to show the user.
  Future<String?> publish(String jobId) async {
    final wallet = _wallet;
    if (wallet == null || wallet.isEmpty) {
      return 'You need to be signed in to publish.';
    }

    state = state.copyWith(publishingJobId: jobId);
    try {
      await TheaterService.instance.publish(jobId: jobId, wallet: wallet);
    } on ValidationException catch (e) {
      if (ref.mounted) state = state.copyWith(clearPublishingJobId: true);
      return e.message ?? 'This video can\'t be published to Theater.';
    } on AppException catch (e) {
      AppLogger.error('Publish failed', tag: 'MyVideos', error: e);
      if (ref.mounted) state = state.copyWith(clearPublishingJobId: true);
      return e.message ?? 'Unable to publish. Please try again.';
    }

    if (!ref.mounted) return null;
    state = state.copyWith(
      publishedJobIds: {...state.publishedJobIds, jobId},
      clearPublishingJobId: true,
    );
    return null;
  }

  /// Permanently delete one of the caller's videos.
  ///
  /// Returns null on success, or a message to show the user. The row is
  /// removed from the list only after the server confirms, so a failed delete
  /// doesn't hide a video that still exists.
  Future<String?> delete(String jobId) async {
    final wallet = _wallet;
    if (wallet == null || wallet.isEmpty) {
      return 'You need to be signed in.';
    }

    state = state.copyWith(deletingJobId: jobId);
    try {
      await TheaterService.instance.deleteJob(jobId: jobId, wallet: wallet);
    } on NotFoundException {
      // Already gone server-side — drop it locally rather than complain.
      if (ref.mounted) _dropLocally(jobId);
      return null;
    } on AppException catch (e) {
      AppLogger.error('Delete failed', tag: 'MyVideos', error: e);
      if (ref.mounted) state = state.copyWith(clearDeletingJobId: true);
      return e.message ?? 'Unable to delete the video.';
    }

    if (!ref.mounted) return null;
    _dropLocally(jobId);
    return null;
  }

  void _dropLocally(String jobId) {
    state = state.copyWith(
      videos: state.videos.where((v) => v.jobId != jobId).toList(),
      publishedJobIds: {...state.publishedJobIds}..remove(jobId),
      clearDeletingJobId: true,
    );
  }

  bool isPublished(String jobId) => state.publishedJobIds.contains(jobId);
}

final myVideosControllerProvider =
    NotifierProvider<MyVideosController, MyVideosState>(MyVideosController.new);
