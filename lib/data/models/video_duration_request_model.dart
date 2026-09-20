import 'package:flutter/foundation.dart';

/// A deferred video generation request waiting for the user to choose a length.
@immutable
class VideoDurationRequestModel {
  const VideoDurationRequestModel({
    this.minSeconds = 5,
    this.maxSeconds = 60,
    this.stepSeconds = 5,
    this.initialSeconds = 15,
    this.usdcPerSecond,
    this.submittedSeconds,
  });

  final int minSeconds;
  final int maxSeconds;
  final int stepSeconds;
  final int initialSeconds;
  final double? usdcPerSecond;
  final int? submittedSeconds;

  bool get isSubmitted => submittedSeconds != null;

  double? estimatedUsdcCost(int seconds) {
    final rate = usdcPerSecond;
    if (rate == null) return null;
    return rate * seconds;
  }

  bool accepts(int seconds) {
    return stepSeconds > 0 &&
        seconds >= minSeconds &&
        seconds <= maxSeconds &&
        (seconds - minSeconds) % stepSeconds == 0;
  }

  factory VideoDurationRequestModel.fromToolOutput(Map<String, dynamic> json) {
    final parsedMin = _intValue(json['min_seconds'], 5);
    final minSeconds = parsedMin > 0 ? parsedMin : 5;
    final parsedMax = _intValue(json['max_seconds'], 60);
    final maxSeconds = parsedMax > minSeconds ? parsedMax : 60;
    final parsedStep = _intValue(json['step_seconds'], 5);
    final span = maxSeconds - minSeconds;
    final fallbackStep = span % 5 == 0 ? 5 : 1;
    final stepSeconds =
        parsedStep > 0 && parsedStep <= span && span % parsedStep == 0
        ? parsedStep
        : fallbackStep;
    final parsedInitial = _intValue(json['initial_seconds'], 15);
    final clampedInitial = parsedInitial.clamp(minSeconds, maxSeconds).toInt();
    final initialSeconds =
        minSeconds +
        ((clampedInitial - minSeconds) / stepSeconds).round() * stepSeconds;
    final parsedUsdcRate = json['usdc_per_second'];
    final usdcPerSecond = parsedUsdcRate is num && parsedUsdcRate >= 0
        ? parsedUsdcRate.toDouble()
        : null;

    return VideoDurationRequestModel(
      minSeconds: minSeconds,
      maxSeconds: maxSeconds,
      stepSeconds: stepSeconds,
      initialSeconds: initialSeconds,
      usdcPerSecond: usdcPerSecond,
    );
  }

  VideoDurationRequestModel copyWith({
    int? minSeconds,
    int? maxSeconds,
    int? stepSeconds,
    int? initialSeconds,
    double? usdcPerSecond,
    int? submittedSeconds,
    bool clearUsdcPerSecond = false,
    bool clearSubmittedSeconds = false,
  }) {
    return VideoDurationRequestModel(
      minSeconds: minSeconds ?? this.minSeconds,
      maxSeconds: maxSeconds ?? this.maxSeconds,
      stepSeconds: stepSeconds ?? this.stepSeconds,
      initialSeconds: initialSeconds ?? this.initialSeconds,
      usdcPerSecond: clearUsdcPerSecond
          ? null
          : (usdcPerSecond ?? this.usdcPerSecond),
      submittedSeconds: clearSubmittedSeconds
          ? null
          : (submittedSeconds ?? this.submittedSeconds),
    );
  }

  static int _intValue(Object? value, int fallback) {
    return value is num ? value.toInt() : fallback;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is VideoDurationRequestModel &&
            minSeconds == other.minSeconds &&
            maxSeconds == other.maxSeconds &&
            stepSeconds == other.stepSeconds &&
            initialSeconds == other.initialSeconds &&
            usdcPerSecond == other.usdcPerSecond &&
            submittedSeconds == other.submittedSeconds;
  }

  @override
  int get hashCode => Object.hash(
    minSeconds,
    maxSeconds,
    stepSeconds,
    initialSeconds,
    usdcPerSecond,
    submittedSeconds,
  );
}
