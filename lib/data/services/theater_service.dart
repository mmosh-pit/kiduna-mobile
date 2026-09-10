import 'package:dio/dio.dart';

import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../models/theater_post_model.dart';
import '../models/video_job_model.dart';

/// Theater: polling generated videos and publishing them to the feed.
class TheaterService {
  TheaterService._();

  static final TheaterService instance = TheaterService._();

  Dio get _dio => ApiClient.instance.dio;

  /// Current state of one generation job.
  Future<VideoJobModel> fetchJob({
    required String jobId,
    required String wallet,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.videoJob(jobId, wallet),
      );
      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response from video job endpoint');
      }
      return VideoJobModel.fromJson(body);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      AppLogger.error(
        'Failed to fetch video job',
        tag: 'TheaterService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const NetworkException(
        'Unable to connect. Please check your internet.',
      );
    }
  }

  /// Every video the caller has generated, newest first.
  Future<List<VideoJobModel>> fetchMyJobs({
    required String wallet,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.videoJobs(wallet, limit: limit),
      );
      final raw = response.data?['jobs'] as List<dynamic>? ?? <dynamic>[];
      return raw
          .map((e) => VideoJobModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      AppLogger.error(
        'Failed to fetch my video jobs',
        tag: 'TheaterService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const NetworkException(
        'Unable to connect. Please check your internet.',
      );
    }
  }

  /// The caller's own Theater posts, including removed ones.
  Future<List<TheaterPostModel>> fetchMyPosts({required String wallet}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.theaterMine(wallet),
      );
      final raw = response.data?['posts'] as List<dynamic>? ?? <dynamic>[];
      return raw
          .map((e) => TheaterPostModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      AppLogger.error(
        'Failed to fetch my theater posts',
        tag: 'TheaterService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const NetworkException(
        'Unable to connect. Please check your internet.',
      );
    }
  }

  /// Delete one of the caller's generated videos.
  ///
  /// Also retires any Theater post for it and removes the stored file, so this
  /// is not reversible.
  Future<void> deleteJob({
    required String jobId,
    required String wallet,
  }) async {
    try {
      await _dio.delete<void>(ApiEndpoints.videoJobDelete(jobId, wallet));
      AppLogger.info('Deleted video job', tag: 'TheaterService');
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      if (e.response?.statusCode == 404) {
        throw const NotFoundException('That video no longer exists.');
      }
      AppLogger.error(
        'Failed to delete video job',
        tag: 'TheaterService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const ServerException('Unable to delete the video.');
    }
  }

  /// Publish a finished video to the Theater feed.
  ///
  /// Throws [ValidationException] when moderation blocks it — the message is
  /// the reason to show the author.
  Future<TheaterPostModel> publish({
    required String jobId,
    required String wallet,
    String? authorName,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.theaterPublish,
        data: {
          'jobId': jobId,
          'userWallet': wallet,
          if (authorName != null && authorName.isNotEmpty)
            'authorName': authorName,
        },
      );
      final post = response.data?['post'] as Map<String, dynamic>?;
      if (post == null) {
        throw const ServerException('Publish returned no post');
      }
      AppLogger.info('Published video job $jobId', tag: 'TheaterService');
      return TheaterPostModel.fromJson(post);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;

      final detail = e.response?.data;
      if (e.response?.statusCode == 422 && detail is Map<String, dynamic>) {
        final inner = detail['detail'];
        final message = inner is Map<String, dynamic>
            ? inner['message'] as String?
            : null;
        throw ValidationException(
          message ?? 'This video can\'t be published to Theater.',
        );
      }

      AppLogger.error(
        'Failed to publish video',
        tag: 'TheaterService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const ServerException('Unable to publish. Please try again.');
    }
  }

  /// One page of the realm's feed, newest first.
  Future<({List<TheaterPostModel> posts, String? nextCursor})> fetchFeed({
    String? realmId,
    String? before,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.theaterFeed(
          realmId: realmId,
          before: before,
          limit: limit,
        ),
      );
      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response from theater feed');
      }
      final raw = (body['posts'] as List<dynamic>? ?? <dynamic>[]);
      final posts = raw
          .map((e) => TheaterPostModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return (posts: posts, nextCursor: body['nextCursor'] as String?);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      AppLogger.error(
        'Failed to fetch theater feed',
        tag: 'TheaterService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const NetworkException(
        'Unable to connect. Please check your internet.',
      );
    }
  }

  /// Take one of the caller's own posts down.
  Future<void> removePost({
    required String postId,
    required String wallet,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.theaterRemove(postId),
        data: {'userWallet': wallet},
      );
      AppLogger.info('Removed theater post $postId', tag: 'TheaterService');
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      AppLogger.error(
        'Failed to remove theater post',
        tag: 'TheaterService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const ServerException('Unable to remove the post.');
    }
  }
}
