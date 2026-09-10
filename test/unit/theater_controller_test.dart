import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/data/models/theater_post_model.dart';
import 'package:kiduna/features/theater/controllers/theater_controller.dart';

void main() {
  const post = TheaterPostModel(
    id: 'p1',
    videoUrl: 'https://example.com/a.mp4',
    prompt: 'a kite over the sea',
    userWallet: 'WALLET1',
  );

  group('TheaterState', () {
    test('starts empty and unloaded', () {
      const state = TheaterState();
      expect(state.posts, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isLoadingMore, isFalse);
      expect(state.error, isNull);
      expect(state.hasLoaded, isFalse);
      expect(state.hasMore, isFalse);
    });

    test('hasMore is true only while a cursor is held', () {
      const withCursor = TheaterState(nextCursor: '2026-09-02T10:00:00');
      expect(withCursor.hasMore, isTrue);
      expect(const TheaterState().hasMore, isFalse);
    });

    test('copyWith preserves an existing error when clearError is false', () {
      const state = TheaterState(error: 'offline');
      final next = state.copyWith(isLoading: true);
      expect(next.error, 'offline');
      expect(next.isLoading, isTrue);
    });

    test('copyWith clears the error when clearError is true', () {
      const state = TheaterState(error: 'offline');
      expect(state.copyWith(clearError: true).error, isNull);
    });

    test('copyWith clears the cursor when clearCursor is true', () {
      const state = TheaterState(nextCursor: 'cursor');
      final next = state.copyWith(clearCursor: true);
      expect(next.nextCursor, isNull);
      expect(next.hasMore, isFalse);
    });

    test('copyWith replaces the post list', () {
      const state = TheaterState();
      final next = state.copyWith(posts: const [post]);
      expect(next.posts, hasLength(1));
      expect(next.posts.first.id, 'p1');
    });

    test('copyWith leaves untouched fields alone', () {
      const state = TheaterState(posts: [post], hasLoaded: true);
      final next = state.copyWith(isLoadingMore: true);
      expect(next.posts, hasLength(1));
      expect(next.hasLoaded, isTrue);
      expect(next.isLoadingMore, isTrue);
    });
  });
}
