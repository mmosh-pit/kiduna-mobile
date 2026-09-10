import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/data/models/video_job_model.dart';
import 'package:kiduna/features/theater/controllers/my_videos_controller.dart';

void main() {
  const ready = VideoJobModel(
    jobId: 'j1',
    status: VideoJobStatus.ready,
    videoUrl: 'https://example.com/a.mp4',
    assetId: 'a1',
    prompt: 'a serene forest',
  );
  const generating = VideoJobModel(
    jobId: 'j2',
    status: VideoJobStatus.generating,
  );

  group('MyVideosState defaults', () {
    test('starts empty and unloaded', () {
      const state = MyVideosState();
      expect(state.videos, isEmpty);
      expect(state.publishedJobIds, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.hasLoaded, isFalse);
      expect(state.publishingJobId, isNull);
    });
  });

  group('copyWith', () {
    test('preserves an existing error when clearError is false', () {
      const state = MyVideosState(error: 'offline');
      final next = state.copyWith(isLoading: true);
      expect(next.error, 'offline');
      expect(next.isLoading, isTrue);
    });

    test('clears the error when clearError is true', () {
      const state = MyVideosState(error: 'offline');
      expect(state.copyWith(clearError: true).error, isNull);
    });

    test('clears publishingJobId only via its flag', () {
      const state = MyVideosState(publishingJobId: 'j1');
      expect(state.copyWith(isLoading: true).publishingJobId, 'j1');
      expect(
        state.copyWith(clearPublishingJobId: true).publishingJobId,
        isNull,
      );
    });

    test('replaces the video list', () {
      const state = MyVideosState();
      final next = state.copyWith(videos: const [ready, generating]);
      expect(next.videos, hasLength(2));
      expect(next.videos.first.jobId, 'j1');
    });

    test('leaves untouched fields alone', () {
      const state = MyVideosState(videos: [ready], hasLoaded: true);
      final next = state.copyWith(isLoading: true);
      expect(next.videos, hasLength(1));
      expect(next.hasLoaded, isTrue);
    });

    test('clears deletingJobId only via its flag', () {
      const state = MyVideosState(deletingJobId: 'j1');
      expect(state.copyWith(isLoading: true).deletingJobId, 'j1');
      expect(state.copyWith(clearDeletingJobId: true).deletingJobId, isNull);
    });

    test('publishing and deleting are tracked independently', () {
      const state = MyVideosState(publishingJobId: 'j1');
      final next = state.copyWith(deletingJobId: 'j2');
      expect(next.publishingJobId, 'j1');
      expect(next.deletingJobId, 'j2');
    });

    test('accumulates published job ids', () {
      const state = MyVideosState(publishedJobIds: {'j1'});
      final next = state.copyWith(
        publishedJobIds: {...state.publishedJobIds, 'j2'},
      );
      expect(next.publishedJobIds, containsAll(<String>['j1', 'j2']));
    });
  });

  group('local removal', () {
    test('drops the job and forgets its published mark', () {
      const state = MyVideosState(
        videos: [ready, generating],
        publishedJobIds: {'j1'},
      );

      // Mirrors _dropLocally in the controller.
      final next = state.copyWith(
        videos: state.videos.where((v) => v.jobId != 'j1').toList(),
        publishedJobIds: {...state.publishedJobIds}..remove('j1'),
        clearDeletingJobId: true,
      );

      expect(next.videos.map((v) => v.jobId), <String>['j2']);
      expect(next.publishedJobIds, isEmpty);
      expect(next.deletingJobId, isNull);
    });
  });

  group('publish-state derivation', () {
    test('a job is published when its assetId has a live post', () {
      // Mirrors the controller: posts reference assets, jobs reference the
      // same asset, so the match is on assetId — not jobId.
      const videos = [ready, generating];
      final publishedAssetIds = <String>{'a1'};

      final publishedJobIds = videos
          .where(
            (v) => v.assetId != null && publishedAssetIds.contains(v.assetId),
          )
          .map((v) => v.jobId)
          .toSet();

      expect(publishedJobIds, <String>{'j1'});
      expect(publishedJobIds.contains('j2'), isFalse);
    });

    test('a job with no assetId is never treated as published', () {
      const videos = [generating];
      final publishedAssetIds = <String>{'a1'};

      final publishedJobIds = videos
          .where(
            (v) => v.assetId != null && publishedAssetIds.contains(v.assetId),
          )
          .map((v) => v.jobId)
          .toSet();

      expect(publishedJobIds, isEmpty);
    });
  });
}
