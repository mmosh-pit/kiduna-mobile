import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/core/network/api_endpoints.dart';
import 'package:kiduna/data/models/image_job_model.dart';

void main() {
  test('builds the owner-scoped image jobs endpoint', () {
    final path = ApiEndpoints.imageJobs('WALLET/1', limit: 25);
    expect(path, '/api/image-jobs?wallet=WALLET%2F1&limit=25');
  });

  group('ImageJobModel', () {
    test('parses a ready image job', () {
      final job = ImageJobModel.fromJson(const {
        'jobId': 'image-1',
        'status': 'ready',
        'prompt': 'A watercolor fox',
        'imageUrl': 'https://example.test/image.jpg',
        'assetId': 'asset-1',
      });

      expect(job.jobId, 'image-1');
      expect(job.status, ImageJobStatus.ready);
      expect(job.imageUrl, 'https://example.test/image.jpg');
      expect(job.isReady, isTrue);
    });

    test('maps tool output to a generating job', () {
      final job = ImageJobModel.fromToolOutput(const {
        'job_id': 'image-2',
        'status': 'generating',
      });

      expect(job.jobId, 'image-2');
      expect(job.status, ImageJobStatus.generating);
      expect(job.isReady, isFalse);
    });

    test('parses stable failure reasons', () {
      final job = ImageJobModel.fromJson(const {
        'jobId': 'image-3',
        'status': 'failed',
        'failureCode': 'model_out_of_memory',
      });

      expect(job.failureReason, ImageFailureReason.modelOutOfMemory);
      expect(job.status.isTerminal, isTrue);
    });
  });
}
