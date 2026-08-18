import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/presale_model.dart';
import '../../../data/models/purchase_model.dart';
import '../../../data/services/presale_service.dart';
import '../../auth/controllers/auth_controller.dart';

/// UI state for the Exchange section.
@immutable
class ExchangeState {
  const ExchangeState({
    this.presales = const [],
    this.selectedPresale,
    this.purchases = const [],
    this.isLoading = false,
    this.isBuying = false,
    this.error,
    this.buyError,
    this.buySuccess,
    this.filter = 'all',
  });

  /// All presales matching the current [filter].
  final List<PresaleModel> presales;

  /// Currently selected presale (detail view). Null = list view.
  final PresaleModel? selectedPresale;

  /// Purchase history for the selected presale.
  final List<PurchaseModel> purchases;

  /// True while loading presale list or detail.
  final bool isLoading;

  /// True while a buy transaction is in progress.
  final bool isBuying;

  /// Error from list/detail loading.
  final String? error;

  /// Error from buy attempt.
  final String? buyError;

  /// Last successful purchase (cleared on next action).
  final PurchaseModel? buySuccess;

  /// Active filter: 'all', 'live', 'upcoming'.
  final String filter;

  ExchangeState copyWith({
    List<PresaleModel>? presales,
    PresaleModel? Function()? selectedPresale,
    List<PurchaseModel>? purchases,
    bool? isLoading,
    bool? isBuying,
    String? Function()? error,
    String? Function()? buyError,
    PurchaseModel? Function()? buySuccess,
    String? filter,
  }) {
    return ExchangeState(
      presales: presales ?? this.presales,
      selectedPresale:
          selectedPresale != null ? selectedPresale() : this.selectedPresale,
      purchases: purchases ?? this.purchases,
      isLoading: isLoading ?? this.isLoading,
      isBuying: isBuying ?? this.isBuying,
      error: error != null ? error() : this.error,
      buyError: buyError != null ? buyError() : this.buyError,
      buySuccess: buySuccess != null ? buySuccess() : this.buySuccess,
      filter: filter ?? this.filter,
    );
  }
}

/// Controller for the Exchange section — presale listing, detail, and purchase.
///
/// Follows the same Notifier<T> pattern as FieldController.
class ExchangeController extends Notifier<ExchangeState> {
  PresaleService get _service => PresaleService.instance;

  @override
  ExchangeState build() {
    // Watch auth state — when user logs in, auto-load presales.
    final auth = ref.watch(authControllerProvider);
    if (auth.isAuthenticated) {
      Future.microtask(() => loadPresales());
    }
    return const ExchangeState();
  }

  /// Whether the current user is authenticated.
  bool get _isAuthenticated =>
      ref.read(authControllerProvider).isAuthenticated;

  // ─── Load presales ────────────────────────────────────────────────────

  /// Fetch presales from the API with the current filter.
  Future<void> loadPresales({String? status}) async {
    final filter = status ?? state.filter;
    state = state.copyWith(
      isLoading: true,
      error: () => null,
      filter: filter,
    );

    try {
      final presales = await _service.listPresales(status: filter);

      // Sort: live (nearest end) → upcoming (nearest start) → completed
      presales.sort(_presaleComparator);

      state = state.copyWith(
        presales: presales,
        isLoading: false,
      );
      AppLogger.info(
        'Loaded ${presales.length} presales (filter=$filter)',
        tag: 'ExchangeController',
      );
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: () => e.message,
      );
      AppLogger.error(
        'Failed to load presales',
        tag: 'ExchangeController',
        error: e,
      );
    }
  }

  // ─── Select presale (detail view) ─────────────────────────────────────

  /// Load full presale detail. Purchases are only fetched if authenticated
  /// (the purchases endpoint requires a JWT).
  Future<void> selectPresale(String presaleId) async {
    state = state.copyWith(
      isLoading: true,
      error: () => null,
      buySuccess: () => null,
      buyError: () => null,
    );

    try {
      // Presale detail is public — always fetch.
      final presale = await _service.getPresale(presaleId);

      // Purchases require auth — only fetch if logged in.
      List<PurchaseModel> purchases = [];
      if (_isAuthenticated) {
        try {
          purchases = await _service.getPurchases(presaleId);
        } catch (e) {
          AppLogger.warning(
            'Could not load purchases (auth may be missing)',
            tag: 'ExchangeController',
          );
        }
      }

      state = state.copyWith(
        selectedPresale: () => presale,
        purchases: purchases,
        isLoading: false,
      );
    } on AppException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: () => e.message,
      );
    }
  }

  /// Return to list view, clear selection.
  void clearSelection() {
    state = state.copyWith(
      selectedPresale: () => null,
      purchases: [],
      buySuccess: () => null,
      buyError: () => null,
    );
  }

  // ─── Buy tokens ───────────────────────────────────────────────────────

  /// Purchase tokens from the selected presale.
  ///
  /// Returns [PurchaseModel] on success so the buy sheet can display it.
  /// On failure: throws so the buy sheet can catch and show the error.
  Future<PurchaseModel?> buyTokens(String presaleId, double usdcAmount) async {
    state = state.copyWith(
      isBuying: true,
      buyError: () => null,
      buySuccess: () => null,
    );

    try {
      final purchase = await _service.buyTokens(presaleId, usdcAmount);

      AppLogger.info(
        'Purchase completed: ${purchase.tokenAmount} tokens for '
        '\$${purchase.usdcAmount} USDC',
        tag: 'ExchangeController',
      );

      // Refresh the presale detail (updated tokensSold, progress).
      final refreshed = await _service.getPresale(presaleId);
      final purchases = await _service.getPurchases(presaleId);

      state = state.copyWith(
        isBuying: false,
        buySuccess: () => purchase,
        selectedPresale: () => refreshed,
        purchases: purchases,
      );

      // Also refresh the list in background.
      _refreshListSilently();

      return purchase;
    } on AppException catch (e) {
      state = state.copyWith(
        isBuying: false,
        buyError: () => e.message,
      );
      AppLogger.error(
        'Purchase failed',
        tag: 'ExchangeController',
        error: e,
      );
      rethrow;
    }
  }

  /// Clear the buy success/error state (e.g. after dismissing a dialog).
  void clearBuyResult() {
    state = state.copyWith(
      buySuccess: () => null,
      buyError: () => null,
    );
  }

  // ─── Filter ───────────────────────────────────────────────────────────

  /// Change the status filter and reload.
  void setFilter(String filter) {
    if (filter == state.filter) return;
    loadPresales(status: filter);
  }

  // ─── Refresh ──────────────────────────────────────────────────────────

  /// Full refresh of the current view.
  Future<void> refresh() async {
    if (state.selectedPresale != null) {
      await selectPresale(state.selectedPresale!.id);
    } else {
      await loadPresales();
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────

  /// Refresh the list without loading indicator (background update).
  Future<void> _refreshListSilently() async {
    try {
      final presales = await _service.listPresales(status: state.filter);
      presales.sort(_presaleComparator);
      state = state.copyWith(presales: presales);
    } catch (_) {
      // Silent — don't overwrite main state with errors.
    }
  }

  /// Sort comparator: live (nearest end) → upcoming (nearest start)
  /// → completed (most recent end).
  static int _presaleComparator(PresaleModel a, PresaleModel b) {
    final ap = _statusPriority(a.status);
    final bp = _statusPriority(b.status);
    if (ap != bp) return ap.compareTo(bp);

    final aDate = a.isUpcoming
        ? DateTime.tryParse(a.startDate)
        : DateTime.tryParse(a.endDate);
    final bDate = b.isUpcoming
        ? DateTime.tryParse(b.startDate)
        : DateTime.tryParse(b.endDate);
    if (aDate == null || bDate == null) return 0;

    return a.isCompleted ? bDate.compareTo(aDate) : aDate.compareTo(bDate);
  }

  static int _statusPriority(String status) {
    switch (status.toLowerCase()) {
      case 'live':
        return 0;
      case 'upcoming':
        return 1;
      case 'completed':
        return 2;
      default:
        return 3;
    }
  }
}

/// The Riverpod provider for [ExchangeController].
final exchangeControllerProvider =
    NotifierProvider<ExchangeController, ExchangeState>(
  ExchangeController.new,
);
