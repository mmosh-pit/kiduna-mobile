import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/data/models/image_job_model.dart';

void main() {
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
