import 'package:dio/dio.dart';

import '../../core/errors/exceptions.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../models/image_job_model.dart';

class ImageGenerationService {
  ImageGenerationService._();

  static final ImageGenerationService instance = ImageGenerationService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<ImageJobModel> fetchJob({
    required String jobId,
    required String wallet,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.imageJob(jobId, wallet),
      );
      final body = response.data;
      if (body == null) {
        throw const ServerException('Empty response from image job endpoint');
      }
      return ImageJobModel.fromJson(body);
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      AppLogger.error(
        'Failed to fetch image job',
        tag: 'ImageGenerationService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const NetworkException(
        'Unable to connect. Please check your internet.',
      );
    }
  }

  /// Every image the caller has generated, newest first.
  Future<List<ImageJobModel>> fetchMyJobs({
    required String wallet,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.imageJobs(wallet, limit: limit),
      );
      final raw = response.data?['jobs'] as List<dynamic>? ?? <dynamic>[];
      return raw
          .map((item) => ImageJobModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is AppException) throw e.error!;
      AppLogger.error(
        'Failed to fetch my image jobs',
        tag: 'ImageGenerationService',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw const NetworkException(
        'Unable to connect. Please check your internet.',
      );
    }
  }
}
