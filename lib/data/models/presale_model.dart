import 'package:flutter/foundation.dart';

/// Token info nested inside a presale response.
@immutable
class PresaleTokenInfo {
  const PresaleTokenInfo({
    this.tokenId,
    required this.name,
    required this.symbol,
    required this.mintAddress,
    this.decimals,
    this.metadataUri,
  });

  /// Only present in detail response (GET /tokens/presales/:id).
  final String? tokenId;
  final String name;
  final String symbol;
  final String mintAddress;

  /// Only present in detail response.
  final int? decimals;
  final String? metadataUri;

  factory PresaleTokenInfo.fromJson(Map<String, dynamic> json) {
    return PresaleTokenInfo(
      tokenId: json['tokenId'] as String?,
      name: json['name'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      mintAddress: json['mintAddress'] as String? ?? '',
      decimals: json['decimals'] as int?,
      metadataUri: json['metadataUri'] as String?,
    );
  }
}

/// A presale listing from the backend.
///
/// Handles both the list response (`GET /tokens/presales`) and the detail
/// response (`GET /tokens/presales/:id`). The detail response includes
/// extra fields like [buyerCount] and expanded token info.
@immutable
class PresaleModel {
  const PresaleModel({
    required this.id,
    required this.token,
    required this.presalePercentage,
    required this.presaleSupply,
    required this.tokensSold,
    required this.remaining,
    required this.pricePerToken,
    required this.minPurchaseUsdc,
    required this.maxPurchaseUsdc,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.progress,
    this.buyerCount,
  });

  final String id;
  final PresaleTokenInfo token;
  final int presalePercentage;
  final String presaleSupply;
  final String tokensSold;
  final String remaining;
  final String pricePerToken;
  final String minPurchaseUsdc;
  final String maxPurchaseUsdc;
  final String startDate;
  final String endDate;

  /// One of: 'live', 'upcoming', 'completed', 'cancelled'.
  final String status;

  /// Sale progress as 0–100.
  final double progress;

  /// Only present in the detail response.
  final int? buyerCount;

  // ── Convenience getters ──

  String get tokenName => token.name;
  String get tokenSymbol => token.symbol;
  String get mintAddress => token.mintAddress;
  String? get metadataUri => token.metadataUri;

  bool get isLive => status.toLowerCase() == 'live';
  bool get isUpcoming => status.toLowerCase() == 'upcoming';
  bool get isCompleted => status.toLowerCase() == 'completed';

  factory PresaleModel.fromJson(Map<String, dynamic> json) {
    return PresaleModel(
      id: json['id'] as String? ?? '',
      token: PresaleTokenInfo.fromJson(
        json['token'] as Map<String, dynamic>? ?? {},
      ),
      presalePercentage: (json['presalePercentage'] as num?)?.toInt() ?? 0,
      presaleSupply: _str(json['presaleSupply']),
      tokensSold: _str(json['tokensSold']),
      remaining: _str(json['remaining']),
      pricePerToken: _str(json['pricePerToken']),
      minPurchaseUsdc: _str(json['minPurchaseUsdc']),
      maxPurchaseUsdc: _str(json['maxPurchaseUsdc']),
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      status: json['status'] as String? ?? 'upcoming',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      buyerCount: json['buyerCount'] as int?,
    );
  }

  /// Safely converts any JSON value to a string.
  static String _str(dynamic v) {
    if (v == null) return '0';
    if (v is String) return v;
    return v.toString();
  }
}
