import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/data/models/theater_post_model.dart';

void main() {
  group('fromJson', () {
    test('parses all fields', () {
      final post = TheaterPostModel.fromJson(const {
        'id': 'post_1',
        'videoUrl': 'https://storage.googleapis.com/bucket/videos/a.mp4',
        'assetId': 'asset_1',
        'prompt': 'a lantern drifting over water',
        'realmId': 'realm_1',
        'userWallet': 'WALLET1',
        'authorName': 'Aster',
        'status': 'published',
        'createdAt': '2026-09-02T10:45:30',
      });

      expect(post.id, 'post_1');
      expect(post.videoUrl, endsWith('a.mp4'));
      expect(post.assetId, 'asset_1');
      expect(post.prompt, 'a lantern drifting over water');
      expect(post.realmId, 'realm_1');
      expect(post.userWallet, 'WALLET1');
      expect(post.authorName, 'Aster');
      expect(post.isRemoved, isFalse);
      expect(post.createdAt, DateTime.parse('2026-09-02T10:45:30'));
    });

    test('defaults missing fields', () {
      final post = TheaterPostModel.fromJson(const <String, dynamic>{});
      expect(post.id, '');
      expect(post.videoUrl, '');
      expect(post.prompt, '');
      expect(post.authorName, isNull);
      expect(post.createdAt, isNull);
      expect(post.status, 'published');
    });

    test('tolerates an unparseable timestamp rather than throwing', () {
      final post = TheaterPostModel.fromJson(const {'createdAt': 'not-a-date'});
      expect(post.createdAt, isNull);
    });

    test('isRemoved reflects a removed post', () {
      final post = TheaterPostModel.fromJson(const {'status': 'removed'});
      expect(post.isRemoved, isTrue);
    });
  });

  test('equality tracks id and status', () {
    const a = TheaterPostModel(
      id: 'p1',
      videoUrl: 'u',
      prompt: 'p',
      userWallet: 'w',
    );
    const b = TheaterPostModel(
      id: 'p1',
      videoUrl: 'u',
      prompt: 'p',
      userWallet: 'w',
    );
    const removed = TheaterPostModel(
      id: 'p1',
      videoUrl: 'u',
      prompt: 'p',
      userWallet: 'w',
      status: 'removed',
    );

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    expect(a, isNot(equals(removed)));
  });
}
