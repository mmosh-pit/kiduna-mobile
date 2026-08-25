import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/logger.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/chat_service.dart';
import '../../auth/controllers/auth_controller.dart';

@immutable
class ComputeState {
  const ComputeState({
    this.balance = 0,
    this.totalPurchased = 0,
    this.totalSpent = 0,
    this.tokenPrice = 0.00001,
    this.totalWithdrawn = 0,
    this.tokensUsed = 0,
    this.requestCount = 0,
    this.chargedCost = 0,
    this.period = '',
    this.isLoading = false,
    this.error,
  });

  final double balance;
  final double totalPurchased;
  final double totalSpent;

  /// Lifetime KIDUNA cashed back out to USDC. Kept apart from [totalSpent],
  /// which covers compute only.
  final double totalWithdrawn;

  final double tokenPrice;

  /// Current-month LLM tokens consumed (input + output).
  final int tokensUsed;

  /// Current-month chat requests.
  final int requestCount;

  /// Current-month cost charged, in USD.
  final double chargedCost;

  /// Billing period the above stats cover, as 'YYYY-MM'.
  final String period;

  final bool isLoading;
  final String? error;

  /// Total USD value of the current balance.
  double get totalValueUsd => balance * tokenPrice;

  ComputeState copyWith({
    double? balance,
    double? totalPurchased,
    double? totalSpent,
    double? tokenPrice,
    double? totalWithdrawn,
    int? tokensUsed,
    int? requestCount,
    double? chargedCost,
    String? period,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ComputeState(
      balance: balance ?? this.balance,
      totalPurchased: totalPurchased ?? this.totalPurchased,
      totalSpent: totalSpent ?? this.totalSpent,
      tokenPrice: tokenPrice ?? this.tokenPrice,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      requestCount: requestCount ?? this.requestCount,
      chargedCost: chargedCost ?? this.chargedCost,
      period: period ?? this.period,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ComputeController extends Notifier<ComputeState> {
  @override
  ComputeState build() => const ComputeState();

  /// Load KIDUNA balance, token price, and current-month usage stats.
  ///
  /// The stats come from the agent API rather than kinship-backend, so a
  /// failure there must not blank out the balance — it is fetched separately
  /// and defaults to zero.
  Future<void> loadBalance({String? wallet}) async {
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
        totalWithdrawn:
            (balance['totalWithdrawn'] as num?)?.toDouble() ?? 0,
        isLoading: false,
      );

      // Usage stats are best-effort — a failure here leaves the balance intact.
      final address =
          wallet ?? ref.read(authControllerProvider).user?.wallet ?? '';
      if (address.isNotEmpty) {
        final usage =
            await ChatService.instance.fetchComputeUsage(wallet: address);
        if (usage.isNotEmpty) {
          state = state.copyWith(
            tokensUsed: (usage['used'] as num?)?.toInt() ?? 0,
            requestCount: (usage['requestCount'] as num?)?.toInt() ?? 0,
            chargedCost: (usage['chargedCost'] as num?)?.toDouble() ?? 0,
            period: usage['period'] as String? ?? '',
          );
        }
      }

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