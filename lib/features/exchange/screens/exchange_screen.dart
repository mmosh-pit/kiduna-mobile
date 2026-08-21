import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';
import '../controllers/exchange_controller.dart';
import '../widgets/presale_detail_view.dart';
import '../widgets/presale_list_view.dart';

/// Root screen for the Exchange section.
///
/// Watches [exchangeControllerProvider] and switches between list and detail
/// views based on [ExchangeState.selectedPresale].
class ExchangeScreen extends ConsumerWidget {
  const ExchangeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(exchangeControllerProvider);
    final controller = ref.read(exchangeControllerProvider.notifier);
    final auth = ref.watch(authControllerProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: state.selectedPresale == null
          ? PresaleListView(
              key: const ValueKey('presale-list'),
              presales: state.presales,
              isLoading: state.isLoading,
              error: state.error,
              activeFilter: state.filter,
              loggedInEmail: auth.user?.email,
              onPresaleTap: (presale) => controller.selectPresale(presale.id),
              onFilterChanged: controller.setFilter,
              onRefresh: controller.refresh,
              onLogout: () =>
                  ref.read(authControllerProvider.notifier).logout(),
            )
          : PresaleDetailView(
              key: ValueKey('presale-detail-${state.selectedPresale!.id}'),
              presale: state.selectedPresale!,
              purchases: state.purchases,
              isBuying: state.isBuying,
              buySuccess: state.buySuccess,
              buyError: state.buyError,
              onBack: controller.clearSelection,
              onBuy: (usdcAmount) => controller.buyTokens(
                state.selectedPresale!.id,
                usdcAmount,
              ),
              onClearBuyResult: controller.clearBuyResult,
            ),
    );
  }
}
