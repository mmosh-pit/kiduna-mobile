import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../shared/layouts/responsive_layout.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/kiduna_gold_button.dart';
import '../../field/screens/field_screen.dart';
import '../controllers/compute_controller.dart';
import '../controllers/compute_history_controller.dart';
import '../models/compute_history_entry.dart';
import '../open_buy_kiduna.dart';
import '../widgets/compute_usage_bar.dart';
import '../widgets/kiduna_purchase_panel.dart';

/// Full Compute page — balance with a used/available bar, plus usage and
/// purchase history.
class ComputeDetailsScreen extends ConsumerStatefulWidget {
  const ComputeDetailsScreen({super.key});

  @override
  ConsumerState<ComputeDetailsScreen> createState() =>
      _ComputeDetailsScreenState();
}

class _ComputeDetailsScreenState extends ConsumerState<ComputeDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(computeControllerProvider.notifier).loadBalance();
      ref.read(computeHistoryControllerProvider.notifier).loadPurchases();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _buy() async {
    await openBuyKidunaPage(context);
    if (!mounted) return;
    await ref.read(computeControllerProvider.notifier).refresh();
    if (!mounted) return;
    await ref
        .read(computeHistoryControllerProvider.notifier)
        .loadPurchases(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.kiduna.deep,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: ResponsiveLayout(
              desktop: (_) => ContentKiWide(content: _buildContent(context)),
              mobile: (_) => ContentKiNarrow(content: _buildContent(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final compute = ref.watch(computeControllerProvider);

    return Container(
      color: colors.deep,
      child: Center(
        child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: colors.sky,
                            ),
                            child: const Text('← Back'),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Compute',
                            style: text.h4.copyWith(color: colors.gold),
                          ),
                          const SizedBox(height: 16),

                          if (compute.isLoading && compute.balance == 0)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          else
                            ComputeUsageBar(
                              balance: compute.balance,
                              totalPurchased: compute.totalPurchased,
                              totalSpent: compute.totalSpent,
                              tokenPrice: compute.tokenPrice,
                            ),

                          const SizedBox(height: 12),
                          _ComputeStats(compute: compute),

                          const SizedBox(height: 14),
                          KidunaGoldButton(
                            label: 'Buy More KIDUNA',
                            onPressed: _buy,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                    // Tabs
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: colors.camel.withValues(alpha: 0.18),
                          ),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabs,
                        indicatorColor: colors.gold,
                        labelColor: colors.gold,
                        unselectedLabelColor: colors.muted,
                        labelStyle: text.label.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        tabs: const [
                          Tab(text: 'Purchases'),
                          Tab(text: 'Rewards'),
                        ],
                      ),
                    ),

                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: const [
                          _PurchasesTab(),
                          _RewardsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Stats
// ═══════════════════════════════════════════════════════════════════════

/// Rate plus current-month compute figures. The month-scoped values come from
/// the agent's metering table, so they cover this billing period only — the
/// lifetime spend total lives in the bar above.
class _ComputeStats extends StatelessWidget {
  const _ComputeStats({required this.compute});

  final ComputeState compute;

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.deep.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.camel.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RATE',
                style: text.eyebrowSmall.copyWith(color: colors.quiet),
              ),
              Text(
                '1 KIDUNA = \$${compute.tokenPrice}',
                style: text.label.copyWith(color: colors.cream),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                compute.period.isEmpty
                    ? 'THIS MONTH'
                    : 'THIS MONTH · ${compute.period}',
                style: text.eyebrowSmall.copyWith(color: colors.quiet),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCell(
                  label: 'Requests',
                  value: _formatCount(compute.requestCount),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCell(
                  label: 'Tokens',
                  value: _formatCount(compute.tokensUsed),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.camel.withValues(alpha: 0.14)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.micro.copyWith(color: colors.quiet)),
          const SizedBox(height: 3),
          Text(
            value,
            style: text.label.copyWith(
              color: colors.cream,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Purchases tab
// ═══════════════════════════════════════════════════════════════════════

class _PurchasesTab extends ConsumerWidget {
  const _PurchasesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(computeHistoryControllerProvider);

    if (history.purchases.isEmpty) {
      if (history.isLoadingPurchases) {
        return const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }
      return const _EmptyState(
        icon: Icons.receipt_long_outlined,
        message: 'No purchases yet.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      itemCount:
          history.purchases.length + (history.hasMorePurchases ? 1 : 0),
      itemBuilder: (context, i) {
        if (i >= history.purchases.length) {
          return _LoadMore(
            isLoading: history.isLoadingPurchases,
            onTap: () => ref
                .read(computeHistoryControllerProvider.notifier)
                .loadMorePurchases(),
          );
        }
        return _PurchaseRow(entry: history.purchases[i]);
      },
    );
  }
}

class _PurchaseRow extends StatelessWidget {
  const _PurchaseRow({required this.entry});

  final ComputePurchaseEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.deep.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.camel.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatDate(entry.createdAt),
                style: text.micro.copyWith(color: colors.quiet),
              ),
              const SizedBox(height: 6),
              Text(
                '\$${entry.usdcAmount.toStringAsFixed(2)} USD',
                style: text.body.copyWith(color: colors.cream, fontSize: 13),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${KidunaPurchasePanel.formatKiduna(entry.kidunaAmount)} KIDUNA',
                style: text.label.copyWith(
                  color: colors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                entry.status,
                style: text.micro.copyWith(color: colors.quiet),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Rewards tab
// ═══════════════════════════════════════════════════════════════════════

/// Placeholder for KIDUNA rewards. Nothing is earned or tracked yet, so this
/// states that plainly rather than showing an empty list that could read as a
/// zero balance.
class _RewardsTab extends StatelessWidget {
  const _RewardsTab();

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.gold.withValues(alpha: 0.1),
                border: Border.all(color: colors.gold.withValues(alpha: 0.3)),
              ),
              child: Icon(
                Icons.card_giftcard_outlined,
                size: 26,
                color: colors.gold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Coming Soon',
              style: text.h4.copyWith(color: colors.gold),
            ),
            const SizedBox(height: 8),
            Text(
              'Earn KIDUNA through participation in the ecosystem. '
              'Rewards will appear here once available.',
              textAlign: TextAlign.center,
              style: text.caption.copyWith(
                color: colors.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Shared
// ═══════════════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: colors.quiet),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: text.caption.copyWith(
              color: colors.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadMore extends StatelessWidget {
  const _LoadMore({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(foregroundColor: colors.sky),
                child: Text(
                  'Load more',
                  style: text.label.copyWith(color: colors.sky),
                ),
              ),
      ),
    );
  }
}

String _formatDate(DateTime? dt) {
  if (dt == null) return '';
  final local = dt.toLocal();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final ampm = local.hour < 12 ? 'AM' : 'PM';
  final min = local.minute.toString().padLeft(2, '0');
  return '${months[local.month - 1]} ${local.day}, $hour12:$min $ampm';
}
