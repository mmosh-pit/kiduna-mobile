import 'package:flutter/foundation.dart';

enum ImageJobStatus {
  generating,
  ready,
  failed;

  static ImageJobStatus fromString(String value) {
    return switch (value) {
      'ready' => ImageJobStatus.ready,
      'failed' => ImageJobStatus.failed,
      _ => ImageJobStatus.generating,
    };
  }

  bool get isTerminal => this != ImageJobStatus.generating;
}

enum ImageFailureReason {
  providerUnavailable,
  modelOutOfMemory,
  providerTimeout,
  generationFailed;

  static ImageFailureReason? fromString(String? value) {
    return switch (value) {
      'provider_unavailable' => ImageFailureReason.providerUnavailable,
      'model_out_of_memory' => ImageFailureReason.modelOutOfMemory,
      'provider_timeout' => ImageFailureReason.providerTimeout,
      'generation_failed' => ImageFailureReason.generationFailed,
      _ => null,
    };
  }
}

@immutable
class ImageJobModel {
  const ImageJobModel({
    required this.jobId,
    required this.status,
    this.prompt = '',
    this.imageUrl,
    this.assetId,
    this.error,
    this.failureReason,
    this.createdAt,
  });

  final String jobId;
  final ImageJobStatus status;
  final String prompt;
  final String? imageUrl;
  final String? assetId;
  final String? error;
  final ImageFailureReason? failureReason;
  final DateTime? createdAt;

  bool get isReady => status == ImageJobStatus.ready && imageUrl != null;

  factory ImageJobModel.fromJson(Map<String, dynamic> json) {
    return ImageJobModel(
      jobId: (json['jobId'] ?? '') as String,
      status: ImageJobStatus.fromString(
        (json['status'] ?? 'generating') as String,
      ),
      prompt: (json['prompt'] ?? '') as String,
      imageUrl: json['imageUrl'] as String?,
      assetId: json['assetId'] as String?,
      error: json['error'] as String?,
      failureReason: ImageFailureReason.fromString(
        json['failureCode'] as String?,
      ),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '') as String),
    );
  }

  factory ImageJobModel.fromToolOutput(Map<String, dynamic> json) {
    return ImageJobModel(
      jobId: (json['job_id'] ?? '') as String,
      status: ImageJobStatus.generating,
    );
  }

  ImageJobModel copyWith({
    String? jobId,
    ImageJobStatus? status,
    String? prompt,
    String? imageUrl,
    String? assetId,
    String? error,
    ImageFailureReason? failureReason,
    DateTime? createdAt,
    bool clearError = false,
    bool clearFailureReason = false,
  }) {
    return ImageJobModel(
      jobId: jobId ?? this.jobId,
      status: status ?? this.status,
      prompt: prompt ?? this.prompt,
      imageUrl: imageUrl ?? this.imageUrl,
      assetId: assetId ?? this.assetId,
      error: clearError ? null : (error ?? this.error),
      failureReason: clearFailureReason
          ? null
          : (failureReason ?? this.failureReason),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageJobModel &&
          runtimeType == other.runtimeType &&
          jobId == other.jobId &&
          status == other.status &&
          imageUrl == other.imageUrl &&
          assetId == other.assetId &&
          error == other.error &&
          failureReason == other.failureReason;

  @override
  int get hashCode =>
      Object.hash(jobId, status, imageUrl, assetId, error, failureReason);
}
