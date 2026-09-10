import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/data/models/video_job_model.dart';

void main() {
  group('VideoJobStatus', () {
    test('fromString parses known values', () {
      expect(VideoJobStatus.fromString('ready'), VideoJobStatus.ready);
      expect(VideoJobStatus.fromString('failed'), VideoJobStatus.failed);
      expect(VideoJobStatus.fromString('pending'), VideoJobStatus.generating);
    });

    test('fromString falls back to generating for unknown values', () {
      expect(VideoJobStatus.fromString('nonsense'), VideoJobStatus.generating);
      expect(VideoJobStatus.fromString(''), VideoJobStatus.generating);
    });

    test('isTerminal is true only once generation has stopped', () {
      expect(VideoJobStatus.generating.isTerminal, isFalse);
      expect(VideoJobStatus.ready.isTerminal, isTrue);
      expect(VideoJobStatus.failed.isTerminal, isTrue);
    });
  });

  group('VideoJobModel.fromJson', () {
    test('parses a ready job', () {
      final job = VideoJobModel.fromJson(const {
        'jobId': 'job_1',
        'status': 'ready',
        'prompt': 'a dragon over a castle',
        'videoUrl': 'https://storage.googleapis.com/bucket/videos/a.mp4',
        'assetId': 'asset_1',
        'durationSeconds': 6,
        'kidunaCost': 2800.0,
      });

      expect(job.jobId, 'job_1');
      expect(job.status, VideoJobStatus.ready);
      expect(job.prompt, 'a dragon over a castle');
      expect(job.assetId, 'asset_1');
      expect(job.durationSeconds, 6);
      expect(job.kidunaCost, 2800.0);
      expect(job.isReady, isTrue);
    });

    test('defaults missing fields', () {
      final job = VideoJobModel.fromJson(const <String, dynamic>{});
      expect(job.jobId, '');
      expect(job.status, VideoJobStatus.generating);
      expect(job.videoUrl, isNull);
      expect(job.durationSeconds, 8);
      expect(job.isReady, isFalse);
    });

    test('is not ready when status is ready but the URL is missing', () {
      final job = VideoJobModel.fromJson(const {
        'jobId': 'job_2',
        'status': 'ready',
      });
      expect(job.status, VideoJobStatus.ready);
      expect(job.isReady, isFalse);
    });
  });

  group('VideoJobModel.fromToolOutput', () {
    test('builds a generating placeholder from the tool payload', () {
      final job = VideoJobModel.fromToolOutput(const {
        'success': true,
        'job_id': 'job_9',
        'status': 'generating',
        'duration_seconds': 4,
        'kiduna_cost': 1400.0,
      });

      expect(job.jobId, 'job_9');
      expect(job.status, VideoJobStatus.generating);
      expect(job.durationSeconds, 4);
      expect(job.kidunaCost, 1400.0);
      expect(job.videoUrl, isNull);
    });

    test('defaults duration when the tool omits it', () {
      final job = VideoJobModel.fromToolOutput(const {'job_id': 'job_10'});
      expect(job.durationSeconds, 8);
    });
  });

  group('copyWith', () {
    const base = VideoJobModel(
      jobId: 'job_1',
      status: VideoJobStatus.generating,
      error: 'boom',
    );

    test('preserves existing error when clearError is false', () {
      final next = base.copyWith(status: VideoJobStatus.ready);
      expect(next.error, 'boom');
      expect(next.status, VideoJobStatus.ready);
    });

    test('clears error when clearError is true', () {
      final next = base.copyWith(clearError: true);
      expect(next.error, isNull);
    });

    test('carries the local isPublished flag', () {
      expect(base.isPublished, isFalse);
      expect(base.copyWith(isPublished: true).isPublished, isTrue);
    });
  });

  test('equality covers the fields the UI rebuilds on', () {
    const a = VideoJobModel(jobId: 'j', status: VideoJobStatus.ready);
    const b = VideoJobModel(jobId: 'j', status: VideoJobStatus.ready);
    const c = VideoJobModel(jobId: 'j', status: VideoJobStatus.generating);

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    expect(a, isNot(equals(c)));
  });
}
