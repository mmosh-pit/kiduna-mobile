import 'package:flutter/foundation.dart';

/// A single presale purchase record.
///
/// Returned by `POST /tokens/presales/:id/buy` (the buy response) and
/// `GET /tokens/presales/:id/purchases` (purchase history list).
///
/// Contains both on-chain transaction signatures (USDC payment + token
/// delivery) and the purchase amounts.
@immutable
class PurchaseModel {
  const PurchaseModel({
    required this.id,
    required this.buyerWallet,
    required this.tokenAmount,
    required this.usdcAmount,
    required this.pricePerToken,
    required this.paymentSignature,
    this.deliverySignature,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String buyerWallet;
  final String tokenAmount;
  final String usdcAmount;
  final String pricePerToken;

  /// On-chain signature for the USDC transfer (buyer → creator).
  final String paymentSignature;

  /// On-chain signature for the token transfer (creator → buyer).
  /// May be null if status is 'failed' (USDC paid but token delivery failed).
  final String? deliverySignature;

  /// One of: 'completed', 'failed', 'refunded'.
  final String status;
  final String? createdAt;

  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isFailed => status.toLowerCase() == 'failed';

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      id: json['id'] as String? ??
          json['purchaseId'] as String? ??
          '',
      buyerWallet: json['buyerWallet'] as String? ?? '',
      tokenAmount: _str(json['tokenAmount']),
      usdcAmount: _str(json['usdcAmount']),
      pricePerToken: _str(json['pricePerToken']),
      paymentSignature: json['paymentSignature'] as String? ?? '',
      deliverySignature: json['deliverySignature'] as String?,
      status: json['status'] as String? ?? 'completed',
      createdAt: json['createdAt'] as String?,
    );
  }

  static String _str(dynamic v) {
    if (v == null) return '0';
    if (v is String) return v;
    return v.toString();
  }
}
