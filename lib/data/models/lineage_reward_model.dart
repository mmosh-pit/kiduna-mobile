import 'package:flutter/foundation.dart';

/// Summary of a user's lineage rewards from `GET /kiduna/lineage-rewards`.
@immutable
class LineageRewardSummary {
  const LineageRewardSummary({
    required this.wallet,
    required this.totalEarned,
    required this.totalClaimed,
    required this.readyToClaim,
    required this.notReadyToClaim,
    required this.perGeneration,
    required this.rewardCount,
    required this.rewards,
  });

  final String wallet;
  final double totalEarned;
  final double totalClaimed;
  final double readyToClaim;
  final double notReadyToClaim;
  final Map<String, double> perGeneration;
  final int rewardCount;
  final List<LineageReward> rewards;

  factory LineageRewardSummary.fromJson(Map<String, dynamic> json) {
    final perGen = <String, double>{};
    final rawGen = json['perGeneration'] as Map<String, dynamic>? ?? {};
    for (final e in rawGen.entries) {
      perGen[e.key] = (e.value as num?)?.toDouble() ?? 0;
    }

    final rawRewards = json['rewards'] as List<dynamic>? ?? [];

    return LineageRewardSummary(
      wallet: json['wallet'] as String? ?? '',
      totalEarned: double.tryParse(json['totalEarned']?.toString() ?? '') ?? 0,
      totalClaimed:
          double.tryParse(json['totalClaimed']?.toString() ?? '') ?? 0,
      readyToClaim:
          double.tryParse(json['readyToClaim']?.toString() ?? '') ?? 0,
      notReadyToClaim:
          double.tryParse(json['notReadyToClaim']?.toString() ?? '') ?? 0,
      perGeneration: perGen,
      rewardCount: (json['rewardCount'] as int?) ?? rawRewards.length,
      rewards: rawRewards
          .map((r) => LineageReward.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A single lineage reward row.
@immutable
class LineageReward {
  const LineageReward({
    required this.id,
    required this.tier,
    required this.rewardAmount,
    required this.rewardPercentage,
    required this.rateType,
    required this.purchaseUserId,
    required this.status,
    required this.claimStatus,
    this.createdAt,
  });

  final String id;
  final String tier; // GEN1, GEN2, GEN3, GEN4
  final double rewardAmount;
  final double rewardPercentage;
  final String rateType; // initial, ongoing
  final String purchaseUserId;
  final String status; // PENDING, CLAIMED
  final String claimStatus; // LOCKED, CLAIMABLE, CLAIMED
  final DateTime? createdAt;

  /// Human-readable tier label.
  String get tierLabel {
    switch (tier) {
      case 'GEN1':
        return 'Gen 1';
      case 'GEN2':
        return 'Gen 2';
      case 'GEN3':
        return 'Gen 3';
      case 'GEN4':
        return 'Gen 4';
      default:
        return tier;
    }
  }

  /// Human-readable rate type.
  String get rateLabel => rateType == 'initial' ? 'First Purchase' : 'Ongoing';

  factory LineageReward.fromJson(Map<String, dynamic> json) {
    return LineageReward(
      id: json['id'] as String? ?? '',
      tier: json['tier'] as String? ?? '',
      rewardAmount:
          double.tryParse(json['rewardAmount']?.toString() ?? '') ?? 0,
      rewardPercentage:
          double.tryParse(json['rewardPercentage']?.toString() ?? '') ?? 0,
      rateType: json['rateType'] as String? ?? 'initial',
      purchaseUserId: json['purchaseUserId'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      claimStatus: json['claimStatus'] as String? ?? 'LOCKED',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }
}
