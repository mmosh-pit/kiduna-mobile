import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/data/models/video_duration_request_model.dart';

void main() {
  test('parses duration picker contract from tool output', () {
    final request = VideoDurationRequestModel.fromToolOutput(const {
      'min_seconds': 5,
      'max_seconds': 60,
      'step_seconds': 5,
      'initial_seconds': 15,
      'usdc_per_second': 0.56,
    });

    expect(request.minSeconds, 5);
    expect(request.maxSeconds, 60);
    expect(request.stepSeconds, 5);
    expect(request.initialSeconds, 15);
    expect(request.usdcPerSecond, 0.56);
    expect(request.estimatedUsdcCost(15), closeTo(8.4, 0.000001));
    expect(request.isSubmitted, isFalse);
  });

  test('validates slider steps and records one submitted choice', () {
    const request = VideoDurationRequestModel();

    expect(request.accepts(5), isTrue);
    expect(request.accepts(30), isTrue);
    expect(request.accepts(60), isTrue);
    expect(request.accepts(8), isFalse);
    expect(request.accepts(65), isFalse);

    final submitted = request.copyWith(submittedSeconds: 30);
    expect(submitted.isSubmitted, isTrue);
    expect(submitted.submittedSeconds, 30);
    expect(
      submitted.copyWith(clearSubmittedSeconds: true).isSubmitted,
      isFalse,
    );
  });

  test('uses safe defaults for malformed tool values', () {
    final request = VideoDurationRequestModel.fromToolOutput(const {
      'min_seconds': 5,
      'max_seconds': 2,
      'step_seconds': 0,
      'initial_seconds': 100,
      'usdc_per_second': -1,
    });

    expect(request.maxSeconds, 60);
    expect(request.stepSeconds, 5);
    expect(request.usdcPerSecond, isNull);
    expect(request.estimatedUsdcCost(15), isNull);
    expect(request.initialSeconds, 60);
  });
}
