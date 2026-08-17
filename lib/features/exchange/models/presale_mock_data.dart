import 'package:flutter/foundation.dart';

/// Mock presale item matching the exact shape of GET /tokens/presales response.
///
/// Fields use strings for numeric values (same as API JSON). When API
/// integration happens, replace this with PresaleModel.fromJson() — no widget
/// changes needed.
@immutable
class PresaleMockItem {
  const PresaleMockItem({
    required this.id,
    required this.tokenName,
    required this.tokenSymbol,
    required this.mintAddress,
    this.metadataUri,
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
  });

  final String id;
  final String tokenName;
  final String tokenSymbol;
  final String mintAddress;
  final String? metadataUri;
  final int presalePercentage;
  final String presaleSupply;
  final String tokensSold;
  final String remaining;
  final String pricePerToken;
  final String minPurchaseUsdc;
  final String maxPurchaseUsdc;
  final String startDate;
  final String endDate;
  final String status; // 'live', 'upcoming', 'completed'
  final double progress; // 0–100
}

/// Static mock presales for UI development.
const List<PresaleMockItem> kMockPresales = [
  PresaleMockItem(
    id: '29b92c61-bb1d-4b16-887f-7b45a3a39e16',
    tokenName: 'Kiduna Token',
    tokenSymbol: 'KIDUNA',
    mintAddress: 'Gsm3u5UiYEK3dCuufzDBaQbJajcuPUAS1kPcbqhDeiQy',
    metadataUri:
        'https://indigo-neat-vulture-132.mypinata.cloud/ipfs/bafkreiehaao2m5oafvl4ma3et2dzu6xnf6ohudm7vboat2pbgbhg6c63oy',
    presalePercentage: 20,
    presaleSupply: '2000000000',
    tokensSold: '500000000',
    remaining: '1500000000',
    pricePerToken: '0.010000000000',
    minPurchaseUsdc: '10.000000',
    maxPurchaseUsdc: '5000.000000',
    startDate: '2026-09-01T00:00:00.000Z',
    endDate: '2026-09-14T00:00:00.000Z',
    status: 'live',
    progress: 25.0,
  ),
  PresaleMockItem(
    id: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    tokenName: 'Alpha Protocol',
    tokenSymbol: 'ALPHA',
    mintAddress: '4WhBC5QmbSrFKfSmWYP4cPToUKW9U9bUsRE4tpLrEABT',
    metadataUri: null,
    presalePercentage: 30,
    presaleSupply: '3000000000',
    tokensSold: '0',
    remaining: '3000000000',
    pricePerToken: '0.005000000000',
    minPurchaseUsdc: '50.000000',
    maxPurchaseUsdc: '10000.000000',
    startDate: '2026-10-01T00:00:00.000Z',
    endDate: '2026-10-15T00:00:00.000Z',
    status: 'upcoming',
    progress: 0.0,
  ),
  PresaleMockItem(
    id: 'f9e8d7c6-b5a4-3210-fedc-ba0987654321',
    tokenName: 'Beta Network',
    tokenSymbol: 'BETA',
    mintAddress: 'H21Nuy1KAPngpbktDTaumkNwBPtwRSjF2RKvzkhfJszV',
    metadataUri: null,
    presalePercentage: 15,
    presaleSupply: '1500000000',
    tokensSold: '1500000000',
    remaining: '0',
    pricePerToken: '0.020000000000',
    minPurchaseUsdc: '25.000000',
    maxPurchaseUsdc: '2500.000000',
    startDate: '2026-07-01T00:00:00.000Z',
    endDate: '2026-07-14T00:00:00.000Z',
    status: 'completed',
    progress: 100.0,
  ),
];
