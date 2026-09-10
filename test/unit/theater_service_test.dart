import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/core/network/api_endpoints.dart';
import 'package:kiduna/data/models/theater_post_model.dart';
import 'package:kiduna/data/models/video_job_model.dart';

/// TheaterService talks to a live backend, so these tests cover the two things
/// that break without one: the URLs it builds, and the response shapes it
/// parses (the same JSON the Theater endpoints return).
void main() {
  group('endpoint construction', () {
    test('videoJob encodes the wallet', () {
      final path = ApiEndpoints.videoJob('job_1', 'WALLET/1');
      expect(path, startsWith('/api/video-jobs/job_1?wallet='));
      expect(path, contains('WALLET%2F1'));
    });

    test('theaterFeed includes realm and limit', () {
      final path = ApiEndpoints.theaterFeed(realmId: 'realm_1', limit: 5);
      expect(path, startsWith('/api/theater/feed?'));
      expect(path, contains('realmId=realm_1'));
      expect(path, contains('limit=5'));
    });

    test('theaterFeed omits realm and cursor when absent', () {
      final path = ApiEndpoints.theaterFeed();
      expect(path, isNot(contains('realmId')));
      expect(path, isNot(contains('before')));
      expect(path, contains('limit=20'));
    });

    test('theaterFeed carries the cursor when paging', () {
      final path = ApiEndpoints.theaterFeed(before: '2026-09-02T10:00:00');
      expect(path, contains('before=2026-09-02T10%3A00%3A00'));
    });

    test('theaterRemove targets the post', () {
      expect(ApiEndpoints.theaterRemove('p1'), '/api/theater/p1/remove');
    });
  });

  group('response parsing', () {
    test('parses the video job status response', () {
      final job = VideoJobModel.fromJson(const {
        'jobId': 'job_1',
        'status': 'ready',
        'prompt': 'a fox in snow',
        'durationSeconds': 8,
        'assetId': 'asset_1',
        'videoUrl': 'https://storage.googleapis.com/b/videos/a.mp4',
        'error': null,
        'kidunaCost': 2800.0,
        'createdAt': '2026-09-02T10:45:30',
        'completedAt': '2026-09-02T10:47:02',
      });

      expect(job.jobId, 'job_1');
      expect(job.isReady, isTrue);
      expect(job.error, isNull);
    });

    test('parses a failed job with its error', () {
      final job = VideoJobModel.fromJson(const {
        'jobId': 'job_2',
        'status': 'failed',
        'error': 'Veo generation timed out after 420s',
      });

      expect(job.status, VideoJobStatus.failed);
      expect(job.error, contains('timed out'));
      expect(job.isReady, isFalse);
    });

    test('parses the feed response', () {
      const body = {
        'posts': [
          {
            'id': 'post_1',
            'videoUrl': 'https://storage.googleapis.com/b/videos/a.mp4',
            'prompt': 'a fox in snow',
            'userWallet': 'WALLET1',
            'authorName': 'Aster',
            'status': 'published',
            'createdAt': '2026-09-02T10:47:02',
          },
          {
            'id': 'post_2',
            'videoUrl': 'https://storage.googleapis.com/b/videos/b.mp4',
            'prompt': 'a lantern over water',
            'userWallet': 'WALLET2',
            'status': 'published',
            'createdAt': '2026-09-02T09:12:00',
          },
        ],
        'nextCursor': '2026-09-02T09:12:00',
      };

      final posts = (body['posts']! as List<dynamic>)
          .map((e) => TheaterPostModel.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(posts, hasLength(2));
      expect(posts.first.authorName, 'Aster');
      expect(posts.last.authorName, isNull);
      expect(body['nextCursor'], isNotNull);
    });

    test('parses the publish response envelope', () {
      const body = {
        'published': true,
        'post': {
          'id': 'post_1',
          'videoUrl': 'https://storage.googleapis.com/b/videos/a.mp4',
          'prompt': 'a fox in snow',
          'userWallet': 'WALLET1',
          'status': 'published',
        },
      };

      final post = TheaterPostModel.fromJson(
        body['post']! as Map<String, dynamic>,
      );
      expect(post.id, 'post_1');
      expect(post.isRemoved, isFalse);
    });

    test('parses a moderation rejection detail', () {
      const body = {
        'detail': {
          'code': 'MODERATION_BLOCKED',
          'message': 'This video can\'t be published to Theater.',
        },
      };

      final detail = body['detail']! as Map<String, dynamic>;
      expect(detail['code'], 'MODERATION_BLOCKED');
      expect(detail['message'], contains('published'));
    });
  });
}
