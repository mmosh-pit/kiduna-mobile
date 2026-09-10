import 'package:flutter/foundation.dart';

/// Lifecycle of a Theater video generation job.
enum VideoJobStatus {
  generating,
  ready,
  failed;

  static VideoJobStatus fromString(String value) {
    return switch (value) {
      'ready' => VideoJobStatus.ready,
      'failed' => VideoJobStatus.failed,
      _ => VideoJobStatus.generating,
    };
  }

  bool get isTerminal => this != VideoJobStatus.generating;
}

/// A video Ki is generating (or has generated) for a chat message.
///
/// Veo takes anywhere from seconds to minutes, so a message carries this from
/// the moment generation starts: first as [VideoJobStatus.generating] with no
/// URL, then updated in place once the clip is ready.
@immutable
class VideoJobModel {
  const VideoJobModel({
    required this.jobId,
    required this.status,
    this.prompt = '',
    this.videoUrl,
    this.assetId,
    this.error,
    this.durationSeconds = 8,
    this.kidunaCost,
    this.isPublished = false,
    this.createdAt,
  });

  final String jobId;
  final VideoJobStatus status;
  final String prompt;
  final String? videoUrl;
  final String? assetId;
  final String? error;
  final int durationSeconds;
  final double? kidunaCost;

  /// When generation started — used to line a job up with the chat message
  /// that triggered it when history is reloaded.
  final DateTime? createdAt;

  /// Set locally once the user publishes it, so the button can't be re-tapped.
  final bool isPublished;

  bool get isReady => status == VideoJobStatus.ready && videoUrl != null;

  factory VideoJobModel.fromJson(Map<String, dynamic> json) {
    return VideoJobModel(
      jobId: (json['jobId'] ?? '') as String,
      status: VideoJobStatus.fromString(
        (json['status'] ?? 'generating') as String,
      ),
      prompt: (json['prompt'] ?? '') as String,
      videoUrl: json['videoUrl'] as String?,
      assetId: json['assetId'] as String?,
      error: json['error'] as String?,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 8,
      kidunaCost: (json['kidunaCost'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '') as String),
    );
  }

  /// Builds the initial attachment from the `generate_video` tool's output.
  factory VideoJobModel.fromToolOutput(Map<String, dynamic> json) {
    return VideoJobModel(
      jobId: (json['job_id'] ?? '') as String,
      status: VideoJobStatus.generating,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 8,
      kidunaCost: (json['kiduna_cost'] as num?)?.toDouble(),
    );
  }

  VideoJobModel copyWith({
    String? jobId,
    VideoJobStatus? status,
    String? prompt,
    String? videoUrl,
    String? assetId,
    String? error,
    int? durationSeconds,
    double? kidunaCost,
    bool? isPublished,
    DateTime? createdAt,
    bool clearError = false,
  }) {
    return VideoJobModel(
      jobId: jobId ?? this.jobId,
      status: status ?? this.status,
      prompt: prompt ?? this.prompt,
      videoUrl: videoUrl ?? this.videoUrl,
      assetId: assetId ?? this.assetId,
      error: clearError ? null : (error ?? this.error),
      durationSeconds: durationSeconds ?? this.durationSeconds,
      kidunaCost: kidunaCost ?? this.kidunaCost,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoJobModel &&
          runtimeType == other.runtimeType &&
          jobId == other.jobId &&
          status == other.status &&
          videoUrl == other.videoUrl &&
          assetId == other.assetId &&
          error == other.error &&
          isPublished == other.isPublished;

  @override
  int get hashCode =>
      Object.hash(jobId, status, videoUrl, assetId, error, isPublished);
}
