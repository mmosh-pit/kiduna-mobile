import 'package:flutter/foundation.dart';

/// One chat request that consumed KIDUNA.
///
/// [prompt] and [response] are truncated server-side; [promptLength] and
/// [responseLength] carry the untruncated sizes so the UI can indicate when
/// text was cut without holding the full transcript.
@immutable
class ComputeUsageEntry {
  const ComputeUsageEntry({
    required this.id,
    required this.prompt,
    required this.response,
    required this.promptLength,
    required this.responseLength,
    required this.inputTokens,
    required this.outputTokens,
    required this.totalTokens,
    required this.kidunaAmount,
    required this.chargedCost,
    this.model,
    this.createdAt,
  });

  final String id;
  final String prompt;
  final String response;
  final int promptLength;
  final int responseLength;
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;
  final double kidunaAmount;

  /// USD charged for this request (actual API cost x multiplier).
  final double chargedCost;

  final String? model;
  final DateTime? createdAt;

  bool get promptTruncated => promptLength > prompt.length;

  factory ComputeUsageEntry.fromJson(Map<String, dynamic> json) {
    return ComputeUsageEntry(
      id: json['id'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      response: json['response'] as String? ?? '',
      promptLength: (json['promptLength'] as num?)?.toInt() ?? 0,
      responseLength: (json['responseLength'] as num?)?.toInt() ?? 0,
      inputTokens: (json['inputTokens'] as num?)?.toInt() ?? 0,
      outputTokens: (json['outputTokens'] as num?)?.toInt() ?? 0,
      totalTokens: (json['totalTokens'] as num?)?.toInt() ?? 0,
      kidunaAmount: (json['kidunaAmount'] as num?)?.toDouble() ?? 0,
      chargedCost: (json['chargedCost'] as num?)?.toDouble() ?? 0,
      model: json['model'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}

/// One completed KIDUNA purchase.
@immutable
class ComputePurchaseEntry {
  const ComputePurchaseEntry({
    required this.id,
    required this.usdcAmount,
    required this.kidunaAmount,
    required this.tokenPrice,
    required this.status,
    this.createdAt,
  });

  final String id;
  final double usdcAmount;
  final double kidunaAmount;
  final double tokenPrice;
  final String status;
  final DateTime? createdAt;

  factory ComputePurchaseEntry.fromJson(Map<String, dynamic> json) {
    return ComputePurchaseEntry(
      id: json['id'] as String? ?? '',
      usdcAmount: (json['usdcAmount'] as num?)?.toDouble() ?? 0,
      kidunaAmount: (json['kidunaAmount'] as num?)?.toDouble() ?? 0,
      tokenPrice: (json['tokenPrice'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'unknown',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
