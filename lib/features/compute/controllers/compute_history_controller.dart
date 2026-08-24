import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/logger.dart';
import '../../../data/services/auth_service.dart';
import '../models/compute_history_entry.dart';

const _pageSize = 20;

@immutable
class ComputeHistoryState {
  const ComputeHistoryState({
    this.usage = const [],
    this.purchases = const [],
    this.usageTotal = 0,
    this.purchaseTotal = 0,
    this.isLoadingUsage = false,
    this.isLoadingPurchases = false,
    this.error,
  });

  final List<ComputeUsageEntry> usage;
  final List<ComputePurchaseEntry> purchases;
  final int usageTotal;
  final int purchaseTotal;
  final bool isLoadingUsage;
  final bool isLoadingPurchases;
  final String? error;

  bool get hasMoreUsage => usage.length < usageTotal;
  bool get hasMorePurchases => purchases.length < purchaseTotal;

  ComputeHistoryState copyWith({
    List<ComputeUsageEntry>? usage,
    List<ComputePurchaseEntry>? purchases,
    int? usageTotal,
    int? purchaseTotal,
    bool? isLoadingUsage,
    bool? isLoadingPurchases,
    String? error,
    bool clearError = false,
  }) {
    return ComputeHistoryState(
      usage: usage ?? this.usage,
      purchases: purchases ?? this.purchases,
      usageTotal: usageTotal ?? this.usageTotal,
      purchaseTotal: purchaseTotal ?? this.purchaseTotal,
      isLoadingUsage: isLoadingUsage ?? this.isLoadingUsage,
      isLoadingPurchases: isLoadingPurchases ?? this.isLoadingPurchases,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Paginated usage and purchase history for the Compute details page.
///
/// The two lists page independently — opening the page loads only the first
/// tab's data, and the other is fetched when the user switches to it.
class ComputeHistoryController extends Notifier<ComputeHistoryState> {
  @override
  ComputeHistoryState build() => const ComputeHistoryState();

  /// Loads the first page of usage history, replacing anything already held.
  Future<void> loadUsage({bool refresh = false}) async {
    if (state.isLoadingUsage) return;
    if (!refresh && state.usage.isNotEmpty) return;

    state = state.copyWith(isLoadingUsage: true, clearError: true);
    try {
      final res = await AuthService.instance.getComputeUsageHistory(
        limit: _pageSize,
        offset: 0,
      );
      final rows = (res['data'] as List<dynamic>? ?? [])
          .map((e) => ComputeUsageEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        usage: rows,
        usageTotal: (res['total'] as num?)?.toInt() ?? rows.length,
        isLoadingUsage: false,
      );
    } catch (e, st) {
      AppLogger.error('Usage history load failed', error: e, stackTrace: st);
      state = state.copyWith(
        isLoadingUsage: false,
        error: 'Could not load usage history.',
      );
    }
  }

  /// Appends the next page of usage history.
  Future<void> loadMoreUsage() async {
    if (state.isLoadingUsage || !state.hasMoreUsage) return;

    state = state.copyWith(isLoadingUsage: true);
    try {
      final res = await AuthService.instance.getComputeUsageHistory(
        limit: _pageSize,
        offset: state.usage.length,
      );
      final rows = (res['data'] as List<dynamic>? ?? [])
          .map((e) => ComputeUsageEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        usage: [...state.usage, ...rows],
        usageTotal: (res['total'] as num?)?.toInt() ?? state.usageTotal,
        isLoadingUsage: false,
      );
    } catch (e, st) {
      AppLogger.error('Usage page load failed', error: e, stackTrace: st);
      state = state.copyWith(isLoadingUsage: false);
    }
  }

  /// Loads the first page of purchase history.
  Future<void> loadPurchases({bool refresh = false}) async {
    if (state.isLoadingPurchases) return;
    if (!refresh && state.purchases.isNotEmpty) return;

    state = state.copyWith(isLoadingPurchases: true, clearError: true);
    try {
      final res = await AuthService.instance.getComputePurchaseHistory(
        limit: _pageSize,
        offset: 0,
      );
      final rows = (res['data'] as List<dynamic>? ?? [])
          .map((e) => ComputePurchaseEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        purchases: rows,
        purchaseTotal: (res['total'] as num?)?.toInt() ?? rows.length,
        isLoadingPurchases: false,
      );
    } catch (e, st) {
      AppLogger.error('Purchase history load failed', error: e, stackTrace: st);
      state = state.copyWith(
        isLoadingPurchases: false,
        error: 'Could not load purchase history.',
      );
    }
  }

  /// Appends the next page of purchase history.
  Future<void> loadMorePurchases() async {
    if (state.isLoadingPurchases || !state.hasMorePurchases) return;

    state = state.copyWith(isLoadingPurchases: true);
    try {
      final res = await AuthService.instance.getComputePurchaseHistory(
        limit: _pageSize,
        offset: state.purchases.length,
      );
      final rows = (res['data'] as List<dynamic>? ?? [])
          .map((e) => ComputePurchaseEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        purchases: [...state.purchases, ...rows],
        purchaseTotal:
            (res['total'] as num?)?.toInt() ?? state.purchaseTotal,
        isLoadingPurchases: false,
      );
    } catch (e, st) {
      AppLogger.error('Purchase page load failed', error: e, stackTrace: st);
      state = state.copyWith(isLoadingPurchases: false);
    }
  }
}

final computeHistoryControllerProvider =
    NotifierProvider<ComputeHistoryController, ComputeHistoryState>(
  ComputeHistoryController.new,
);
