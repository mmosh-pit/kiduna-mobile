import 'package:flutter/foundation.dart';

/// Visibility level for a knowledge base.
enum KbPrivacy {
  public,
  private,
  secret,
  personal;

  static KbPrivacy fromString(String value) {
    return KbPrivacy.values.firstWhere(
      (p) => p.name == value,
      orElse: () => KbPrivacy.private,
    );
  }
}

/// Ingest status of a knowledge base item.
enum KbIngestStatus {
  pending,
  ingested,
  failed;

  static KbIngestStatus fromString(String value) {
    return KbIngestStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => KbIngestStatus.pending,
    );
  }
}

/// Aggregate statistics for a knowledge base.
@immutable
class KbStatsModel {
  const KbStatsModel({
    this.totalItems = 0,
    this.ingestedCount = 0,
    this.pendingCount = 0,
    this.failedCount = 0,
  });

  final int totalItems;
  final int ingestedCount;
  final int pendingCount;
  final int failedCount;

  factory KbStatsModel.fromJson(Map<String, dynamic> json) {
    return KbStatsModel(
      totalItems: (json['total_items'] as num?)?.toInt() ?? 0,
      ingestedCount: (json['ingested_count'] as num?)?.toInt() ?? 0,
      pendingCount: (json['pending_count'] as num?)?.toInt() ?? 0,
      failedCount: (json['failed_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'total_items': totalItems,
    'ingested_count': ingestedCount,
    'pending_count': pendingCount,
    'failed_count': failedCount,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KbStatsModel &&
          runtimeType == other.runtimeType &&
          totalItems == other.totalItems &&
          ingestedCount == other.ingestedCount &&
          pendingCount == other.pendingCount &&
          failedCount == other.failedCount;

  @override
  int get hashCode =>
      Object.hash(totalItems, ingestedCount, pendingCount, failedCount);

  @override
  String toString() =>
      'KbStatsModel(total: $totalItems, ingested: $ingestedCount, '
      'pending: $pendingCount, failed: $failedCount)';
}

/// A single item within a knowledge base (uploaded file, text, or Drive link).
@immutable
class KbItemModel {
  const KbItemModel({
    required this.id,
    required this.name,
    this.type = 'file',
    this.status = KbIngestStatus.pending,
    this.chunkCount = 0,
    this.sourceUrl,
    this.error,
    this.createdAt,
  });

  final String id;
  final String name;
  final String type;
  final KbIngestStatus status;
  final int chunkCount;
  final String? sourceUrl;
  final String? error;
  final String? createdAt;

  factory KbItemModel.fromJson(Map<String, dynamic> json) {
    return KbItemModel(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      type: (json['type'] ?? 'file') as String,
      status: KbIngestStatus.fromString(
        (json['status'] ?? 'pending') as String,
      ),
      chunkCount:
          ((json['chunkCount'] ?? json['chunk_count']) as num?)?.toInt() ?? 0,
      sourceUrl:
          (json['url'] ?? json['sourceUrl'] ?? json['source_url']) as String?,
      error: json['error'] as String?,
      createdAt: (json['createdAt'] ?? json['created_at']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'status': status.name,
    'chunk_count': chunkCount,
    if (sourceUrl != null) 'source_url': sourceUrl,
    if (error != null) 'error': error,
    if (createdAt != null) 'created_at': createdAt,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KbItemModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          status == other.status &&
          chunkCount == other.chunkCount &&
          sourceUrl == other.sourceUrl &&
          error == other.error &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    status,
    chunkCount,
    sourceUrl,
    error,
    createdAt,
  );

  @override
  String toString() =>
      'KbItemModel(id: $id, name: $name, status: ${status.name})';
}

/// A knowledge base containing uploaded wisdom for a Ki agent.
///
/// Mirrors the response from `GET /api/knowledge` (list) and
/// `GET /api/knowledge/{kb_id}` (detail with items + stats).
@immutable
class KnowledgeBaseModel {
  const KnowledgeBaseModel({
    required this.id,
    required this.name,
    required this.wallet,
    this.platformId,
    this.privacy = 'private',
    this.createdAt,
    this.updatedAt,
    this.items = const [],
    this.stats,
  });

  final String id;
  final String name;
  final String wallet;
  final String? platformId;
  final String privacy;
  final String? createdAt;
  final String? updatedAt;
  final List<KbItemModel> items;
  final KbStatsModel? stats;

  factory KnowledgeBaseModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>?;
    final rawStats = json['stats'] as Map<String, dynamic>?;

    return KnowledgeBaseModel(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      wallet: (json['wallet'] ?? '') as String,
      platformId: (json['platformId'] ?? json['platform_id']) as String?,
      privacy: (json['privacy'] ?? 'private') as String,
      createdAt: (json['createdAt'] ?? json['created_at']) as String?,
      updatedAt: (json['updatedAt'] ?? json['updated_at']) as String?,
      items:
          rawItems
              ?.map((e) => KbItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      stats: rawStats != null ? KbStatsModel.fromJson(rawStats) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'wallet': wallet,
    if (platformId != null) 'platform_id': platformId,
    'privacy': privacy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
    'items': items.map((i) => i.toJson()).toList(),
    if (stats != null) 'stats': stats!.toJson(),
  };

  KnowledgeBaseModel copyWith({
    String? id,
    String? name,
    String? wallet,
    String? platformId,
    String? privacy,
    String? createdAt,
    String? updatedAt,
    List<KbItemModel>? items,
    KbStatsModel? stats,
    bool clearPlatformId = false,
    bool clearStats = false,
  }) {
    return KnowledgeBaseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      wallet: wallet ?? this.wallet,
      platformId: clearPlatformId ? null : (platformId ?? this.platformId),
      privacy: privacy ?? this.privacy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      stats: clearStats ? null : (stats ?? this.stats),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeBaseModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          wallet == other.wallet &&
          platformId == other.platformId &&
          privacy == other.privacy &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          listEquals(items, other.items) &&
          stats == other.stats;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    wallet,
    platformId,
    privacy,
    createdAt,
    updatedAt,
    Object.hashAll(items),
    stats,
  );

  @override
  String toString() =>
      'KnowledgeBaseModel(id: $id, name: $name, items: ${items.length})';
}
