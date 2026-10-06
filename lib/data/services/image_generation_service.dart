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
}
