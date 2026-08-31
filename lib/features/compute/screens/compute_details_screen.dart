import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/env.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/lineage_reward_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../shared/layouts/responsive_layout.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/kiduna_gold_button.dart';
import '../../../shared/widgets/kiduna_secondary_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../field/screens/field_screen.dart';
import '../controllers/compute_controller.dart';
import '../controllers/compute_history_controller.dart';
import '../models/compute_history_entry.dart';
import '../open_buy_kiduna.dart';
import '../widgets/compute_usage_bar.dart';
import '../widgets/kiduna_purchase_panel.dart';
import 'lineage_withdraw_screen.dart';

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

  /// Withdrawals need a browser wallet signature, so they happen on the
  /// web app. On desktop that means handing off to the browser.
  Future<void> _withdraw() async {
    await openWithdrawPage(context);
    if (!mounted) return;
    await ref.read(computeControllerProvider.notifier).refresh();
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

    // A single scroll view over header + tabs + active tab content.
    //
    // NestedScrollView was the obvious fit, but its body is always handed
    // the full viewport height, so a short list still filled the screen and
    // left blank space to scroll into. Rendering only the active tab, sized
    // to its content, keeps the scrollable exactly as tall as the data.
    return Container(
      color: colors.deep,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              // Fixed header — does not scroll
              _buildHeader(context),

              // Fixed tab bar — does not scroll
              Container(
                decoration: BoxDecoration(
                  color: colors.deep,
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
                  labelStyle: context.kidunaText.label.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: const [
                    Tab(text: 'Purchases'),
                    Tab(text: 'Rewards'),
                  ],
                ),
              ),

              // Scrollable tab content
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    child: AnimatedBuilder(
                      animation: _tabs,
                      builder: (context, _) => _tabs.index == 0
                          ? const _PurchasesTab()
                          : const _RewardsTab(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Balance, stats, and actions — scrolls away above the pinned tab bar.
  Widget _buildHeader(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final compute = ref.watch(computeControllerProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                child: CircularProgressIndicator(strokeWidth: 2),
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
          const SizedBox(height: 10),
          KidunaSecondaryButton(
            label: 'Withdraw',
            onPressed: _withdraw,
          ),
          const SizedBox(height: 20),
        ],
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
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
      return const _EmptyState(
        icon: Icons.receipt_long_outlined,
        message: 'No purchases yet.',
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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

/// Shows the user's lineage rewards earned from compute purchases.
/// Fetches from GET /kiduna/lineage-rewards.
class _RewardsTab extends ConsumerStatefulWidget {
  const _RewardsTab();

  @override
  ConsumerState<_RewardsTab> createState() => _RewardsTabState();
}

class _RewardsTabState extends ConsumerState<_RewardsTab> {
  LineageRewardSummary? _summary;
  bool _loading = true;
  String? _error;
  bool _withdrawing = false;
  String? _withdrawResult;
  bool _withdrawSuccess = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await AuthService.instance.getLineageRewards();
      if (!mounted) return;

      if (data.isEmpty) {
        setState(() {
          _summary = null;
          _loading = false;
        });
        return;
      }

      setState(() {
        _summary = LineageRewardSummary.fromJson(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load rewards.';
        _loading = false;
      });
    }
  }

  Future<void> _withdraw() async {
    final auth = ref.read(authControllerProvider);
    final wallet = auth.user?.wallet;
    if (wallet == null || wallet.isEmpty) return;

    // On web — navigate directly to LineageWithdrawScreen
    if (kIsWeb) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const LineageWithdrawScreen(),
        ),
      );
      // Refresh on return
      if (mounted) _load();
      return;
    }

    // On desktop/mobile — open browser
    setState(() {
      _withdrawing = true;
      _withdrawResult = null;
    });

    try {
      final baseUrl =
          Env.webAppUrl.isNotEmpty ? Env.webAppUrl : 'https://mobile.kiduna.dev';
      final url = Uri.parse(
        '$baseUrl/lineage-withdraw?wallet=$wallet',
      );
      await launchUrl(url, mode: LaunchMode.externalApplication);

      if (!mounted) return;
      setState(() {
        _withdrawing = false;
        _withdrawResult =
            'Withdrawal page opened. Complete the transaction in your browser.';
        _withdrawSuccess = true;
      });

      // Refresh rewards after a delay (user may have completed withdrawal)
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) _load();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _withdrawing = false;
        _withdrawResult = 'Failed to open withdrawal page.';
        _withdrawSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    if (_loading) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: colors.gold),
        ),
      );
    }

    if (_error != null) {
      return _EmptyState(icon: Icons.error_outline, message: _error!);
    }

    if (_summary == null || _summary!.rewardCount == 0) {
      return const _EmptyState(
        icon: Icons.card_giftcard_outlined,
        message:
            'No rewards yet. You earn USDC rewards when people '
            'in your lineage purchase compute.',
      );
    }

    final s = _summary!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Summary card ──
          _SummaryCard(
            totalClaimed: s.totalClaimed,
            available: s.available,
          ),

          // ── Withdraw button ──
          if (s.available > 0) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _withdrawing
                  ? Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.gold,
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _withdraw,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.gold,
                        foregroundColor: colors.field,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: text.body.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      child: Text(
                        'Withdraw \$${s.available.toStringAsFixed(2)} USDC',
                      ),
                    ),
            ),
            if (_withdrawResult != null) ...[
              const SizedBox(height: 8),
              Text(
                _withdrawResult!,
                style: text.caption.copyWith(
                  color: _withdrawSuccess ? colors.mint : colors.orange,
                  height: 1.4,
                ),
              ),
            ],
          ],

          const SizedBox(height: 20),

          // ── Per generation breakdown ──
          Text(
            'PER GENERATION',
            style: text.eyebrowSmall.copyWith(
              color: colors.quiet,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          ...['GEN1', 'GEN2', 'GEN3', 'GEN4'].map((gen) {
            final amount = s.perGeneration[gen] ?? 0;
            final maxAmount = s.perGeneration.values.fold<double>(
              0,
              (a, b) => a > b ? a : b,
            );
            final fraction =
                maxAmount > 0 ? (amount / maxAmount).clamp(0.0, 1.0) : 0.0;
            final label = gen.replaceFirst('GEN', 'Gen ');

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 46,
                    child: Text(
                      label,
                      style:
                          text.caption.copyWith(color: colors.muted, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 14,
                        backgroundColor: colors.camel.withValues(alpha: 0.1),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(colors.gold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 70,
                    child: Text(
                      '\$${amount.toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: text.caption.copyWith(
                        color: colors.cream,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 20),

          // ── Recent rewards list ──
          if (s.rewards.isNotEmpty) ...[
            Text(
              'RECENT REWARDS',
              style: text.eyebrowSmall.copyWith(
                color: colors.quiet,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            ...s.rewards.take(20).map((r) => _RewardRow(reward: r)),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalClaimed,
    required this.available,
  });

  final double totalClaimed;
  final double available;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.gold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.gold.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          _SummaryColumn(
            label: 'Claimed',
            value: '\$${totalClaimed.toStringAsFixed(2)}',
            color: colors.mint,
          ),
          Container(
            width: 1,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: colors.camel.withValues(alpha: 0.15),
          ),
          _SummaryColumn(
            label: 'Available',
            value: '\$${available.toStringAsFixed(2)}',
            color: colors.gold,
          ),
        ],
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = context.kidunaText;
    final colors = context.kiduna;

    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: text.body.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: text.caption.copyWith(color: colors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.reward});

  final LineageReward reward;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    final dateStr = reward.createdAt != null
        ? '${_months[reward.createdAt!.month - 1]} ${reward.createdAt!.day}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.camel.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.gold.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text(
                reward.tier.replaceFirst('GEN', ''),
                style: text.caption.copyWith(
                  color: colors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${reward.tierLabel} · ${reward.rateLabel}',
                  style: text.caption.copyWith(
                    color: colors.cream,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${reward.rewardPercentage.toStringAsFixed(0)}% commission · $dateStr',
                  style: text.caption.copyWith(
                    color: colors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${reward.rewardAmount.toStringAsFixed(2)}',
            style: text.body.copyWith(
              color: colors.gold,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    // Sized to its content — the page owns the scroll, so filling the
    // viewport here would leave blank space to scroll into.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
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
