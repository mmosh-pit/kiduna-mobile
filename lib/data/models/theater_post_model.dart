import 'package:flutter/foundation.dart';

/// A video published to the Theater feed.
@immutable
class TheaterPostModel {
  const TheaterPostModel({
    required this.id,
    required this.videoUrl,
    required this.prompt,
    required this.userWallet,
    this.assetId,
    this.realmId,
    this.authorName,
    this.status = 'published',
    this.createdAt,
  });

  final String id;
  final String videoUrl;
  final String prompt;
  final String userWallet;
  final String? assetId;
  final String? realmId;
  final String? authorName;
  final String status;
  final DateTime? createdAt;

  bool get isRemoved => status == 'removed';

  factory TheaterPostModel.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'] as String?;
    return TheaterPostModel(
      id: (json['id'] ?? '') as String,
      videoUrl: (json['videoUrl'] ?? '') as String,
      prompt: (json['prompt'] ?? '') as String,
      userWallet: (json['userWallet'] ?? '') as String,
      assetId: json['assetId'] as String?,
      realmId: json['realmId'] as String?,
      authorName: json['authorName'] as String?,
      status: (json['status'] ?? 'published') as String,
      createdAt: created != null ? DateTime.tryParse(created) : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TheaterPostModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status;

  @override
  int get hashCode => Object.hash(id, status);
}
