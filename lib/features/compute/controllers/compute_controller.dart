import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/logger.dart';
import '../../../data/services/auth_service.dart';
import '../../auth/controllers/auth_controller.dart';

@immutable
class ComputeState {
  const ComputeState({
    this.balance = 0,
    this.totalPurchased = 0,
    this.totalSpent = 0,
    this.tokenPrice = 0.00001,
    this.isLoading = false,
    this.error,
  });

  final double balance;
  final double totalPurchased;
  final double totalSpent;
  final double tokenPrice;
  final bool isLoading;
  final String? error;

  /// Total USD value of the current balance.
  double get totalValueUsd => balance * tokenPrice;

  ComputeState copyWith({
    double? balance,
    double? totalPurchased,
    double? totalSpent,
    double? tokenPrice,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ComputeState(
      balance: balance ?? this.balance,
      totalPurchased: totalPurchased ?? this.totalPurchased,
      totalSpent: totalSpent ?? this.totalSpent,
      tokenPrice: tokenPrice ?? this.tokenPrice,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ComputeController extends Notifier<ComputeState> {
  @override
  ComputeState build() => const ComputeState();

  /// Load KIDUNA balance and token price from the backend.
  Future<void> loadBalance() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Load rate and balance in parallel
      final results = await Future.wait([
        AuthService.instance.getKidunaRate(),
        AuthService.instance.getKidunaBalance(),
      ]);

      final rate = results[0];
      final balance = results[1];

      state = state.copyWith(
        tokenPrice: (rate['tokenPrice'] as num?)?.toDouble() ?? 0.00001,
        balance: (balance['balance'] as num?)?.toDouble() ?? 0,
        totalPurchased: (balance['totalPurchased'] as num?)?.toDouble() ?? 0,
        totalSpent: (balance['totalSpent'] as num?)?.toDouble() ?? 0,
        isLoading: false,
      );

      AppLogger.info(
        'Compute loaded: balance=${state.balance}, price=${state.tokenPrice}',
        tag: 'Compute',
      );
    } catch (e, st) {
      AppLogger.error('Failed to load compute balance', error: e, stackTrace: st);
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load balance.',
      );
    }
  }

  /// Refresh balance (e.g., after a purchase).
  Future<void> refresh() => loadBalance();
}

final computeControllerProvider =
    NotifierProvider<ComputeController, ComputeState>(ComputeController.new);

/// Roles that chat for free — the backend skips the balance check for these,
/// so the client must not block them either.
const _freeChatRoles = {'wizard', 'genesis', 'mage'};

/// Whether Ki chat should be blocked for lack of KIDUNA.
///
/// Mirrors the backend rule in `chatmessages.py`: free roles always pass,
/// everyone else needs a balance above zero. This is a UX guard only — the
/// backend still enforces it, so a stale or bypassed client changes nothing.
///
/// Returns false while the balance is still loading, so the composer isn't
/// blocked on a value we haven't fetched yet.
final chatBlockedProvider = Provider<bool>((ref) {
  final compute = ref.watch(computeControllerProvider);
  if (compute.isLoading) return false;

  final role = (ref.watch(authControllerProvider).user?.role ?? 'member')
      .trim()
      .toLowerCase();
  if (_freeChatRoles.contains(role)) return false;

  return compute.balance <= 0;
});