import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/presale_model.dart';
import '../../../data/models/purchase_model.dart';
import 'presale_buy_sheet.dart';
import 'presale_countdown.dart';
import 'presale_formatters.dart';
import 'presale_progress_bar.dart';
import 'presale_status_badge.dart';

/// Premium presale detail view — hero header with token identity, countdown,
/// stats in grouped glassmorphic cards, and a prominent buy CTA.
class PresaleDetailView extends StatelessWidget {
  const PresaleDetailView({
    super.key,
    required this.presale,
    this.purchases = const [],
    this.isBuying = false,
    this.buySuccess,
    this.buyError,
    required this.onBuy,
    required this.onClearBuyResult,
    required this.onBack,
  });

  final PresaleModel presale;
  final List<PurchaseModel> purchases;
  final bool isBuying;
  final PurchaseModel? buySuccess;
  final String? buyError;
  final Future<PurchaseModel?> Function(double usdcAmount) onBuy;
  final VoidCallback onClearBuyResult;
  final VoidCallback onBack;

  bool get _isLive => presale.isLive;
  bool get _isUpcoming => presale.isUpcoming;

  void _openBuySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => PresaleBuySheet(
        presale: presale,
        onConfirm: (usdcAmount) async {
          return await onBuy(usdcAmount);
        },
      ),
    );
  }

  void _copyMint(BuildContext context) {
    Clipboard.setData(ClipboardData(text: presale.mintAddress));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Mint address copied'),
        backgroundColor: context.kiduna.sky.withValues(alpha: 0.9),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Column(
      children: [
        // ── Top bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 16, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: Icon(Icons.arrow_back_rounded, color: colors.cream),
                style: IconButton.styleFrom(
                  backgroundColor: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: colors.line),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  presale.tokenName,
                  style: context.kidunaText.heading.copyWith(
                    color: colors.cream,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PresaleStatusBadge(status: presale.status),
            ],
          ),
        ),

        // ── Scrollable body ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═══ Hero Section ═══
                _HeroCard(
                  presale: presale,
                  isLive: _isLive,
                  isUpcoming: _isUpcoming,
                  onCopyMint: () => _copyMint(context),
                ),
                const SizedBox(height: 16),

                // ═══ Stats Grid ═══
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'PRESALE SUPPLY',
                        value: formatTokenNumber(presale.presaleSupply),
                        fullValue: formatTokenNumberFull(presale.presaleSupply),
                        icon: Icons.token_outlined,
                        color: colors.camel,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'TOKENS SOLD',
                        value: formatTokenNumber(presale.tokensSold),
                        fullValue: formatTokenNumberFull(presale.tokensSold),
                        icon: Icons.trending_up_rounded,
                        color: colors.gold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'REMAINING',
                        value: formatTokenNumber(presale.remaining),
                        fullValue: formatTokenNumberFull(presale.remaining),
                        icon: Icons.inventory_2_outlined,
                        color: colors.mint,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'ALLOCATION',
                        value: '${presale.presalePercentage}%',
                        fullValue: '${presale.presalePercentage}% of total',
                        icon: Icons.pie_chart_outline_rounded,
                        color: colors.sky,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ═══ Progress Section ═══
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(label: 'SALE PROGRESS'),
                      const SizedBox(height: 14),
                      PresaleProgressBar(
                        sold: formatTokenNumber(presale.tokensSold),
                        total: formatTokenNumber(presale.presaleSupply),
                        progress: presale.progress,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ═══ Purchase Details ═══
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(label: 'PURCHASE DETAILS'),
                      const SizedBox(height: 14),
                      _DetailRow(
                        icon: Icons.arrow_downward_rounded,
                        label: 'Min Purchase',
                        value: '\$${formatUsdc(presale.minPurchaseUsdc)} USDC',
                        valueColor: colors.cream,
                      ),
                      _DetailDivider(),
                      _DetailRow(
                        icon: Icons.arrow_upward_rounded,
                        label: 'Max Purchase',
                        value: '\$${formatUsdc(presale.maxPurchaseUsdc)} USDC',
                        valueColor: colors.cream,
                      ),
                      _DetailDivider(),
                      _DetailRow(
                        icon: Icons.play_arrow_rounded,
                        label: 'Start Date',
                        value: formatDateFull(presale.startDate),
                        valueColor: colors.cream,
                      ),
                      _DetailDivider(),
                      _DetailRow(
                        icon: Icons.stop_rounded,
                        label: 'End Date',
                        value: formatDateFull(presale.endDate),
                        valueColor: colors.cream,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ═══ Buy Button ═══
                if (_isLive) _BuyButton(
                  symbol: presale.tokenSymbol,
                  onTap: () => _openBuySheet(context),
                ),
                if (_isUpcoming) _UpcomingNotice(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Hero card — token identity, large price, countdown, mint address.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.presale,
    required this.isLive,
    required this.isUpcoming,
    required this.onCopyMint,
  });

  final PresaleModel presale;
  final bool isLive;
  final bool isUpcoming;
  final VoidCallback onCopyMint;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1612),
            const Color(0xFF14110E),
            const Color(0xFF0F0D0B),
          ],
        ),
        border: Border.all(
          color: isLive
              ? colors.sky.withValues(alpha: 0.15)
              : colors.line,
        ),
      ),
      child: Column(
        children: [
          // ── Top accent line ──
          if (isLive)
            Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  colors: [
                    colors.sky.withValues(alpha: 0.0),
                    colors.sky.withValues(alpha: 0.6),
                    colors.mint.withValues(alpha: 0.4),
                    colors.sky.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Token identity ──
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [colors.raised, colors.raisedAlt],
                        ),
                        border: Border.all(
                          color: colors.gold.withValues(alpha: 0.25),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.gold.withValues(alpha: 0.1),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          presale.tokenSymbol.isNotEmpty
                              ? presale.tokenSymbol[0]
                              : '?',
                          style: context.kidunaText.heading.copyWith(
                            color: colors.gold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            presale.tokenName,
                            style: context.kidunaText.labelStrong.copyWith(
                              color: colors.cream,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            presale.tokenSymbol,
                            style: context.kidunaText.micro.copyWith(
                              color: colors.quiet,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Large price ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${formatPrice(presale.pricePerToken)}',
                      style: context.kidunaText.display.copyWith(
                        color: colors.sky,
                        fontSize: 36,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'per token',
                        style: context.kidunaText.bodySm.copyWith(
                          color: colors.sky.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Mint address ──
                GestureDetector(
                  onTap: onCopyMint,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.deep,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.content_copy_rounded,
                          size: 13,
                          color: colors.quiet,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _truncate(presale.mintAddress, 20),
                          style: context.kidunaText.micro.copyWith(
                            color: colors.muted,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Countdown ──
                if (isLive)
                  PresaleCountdown(
                    targetDate: presale.endDate,
                    label: 'Ends in',
                  ),
                if (isUpcoming)
                  PresaleCountdown(
                    targetDate: presale.startDate,
                    label: 'Starts in',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat card — single metric with icon, label, value.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.fullValue,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String fullValue;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: color),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: context.kidunaText.micro.copyWith(
              color: colors.quiet,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: context.kidunaText.heading.copyWith(
              color: colors.cream,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            fullValue,
            style: context.kidunaText.micro.copyWith(color: colors.quiet),
          ),
        ],
      ),
    );
  }
}

/// Glassmorphic card container.
class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.line),
      ),
      child: child,
    );
  }
}

/// Section label — uppercase eyebrow.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: context.kidunaText.micro.copyWith(
        color: context.kiduna.quiet,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Detail row with icon + label + value.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: colors.raised,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 14, color: colors.quiet),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: context.kidunaText.bodySm.copyWith(color: colors.muted),
          ),
          const Spacer(),
          Text(
            value,
            style: context.kidunaText.bodySm.copyWith(
              color: valueColor ?? colors.cream,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle divider between detail rows.
class _DetailDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 38),
      color: context.kiduna.line,
    );
  }
}

/// Premium buy button with gradient and glow.
class _BuyButton extends StatefulWidget {
  const _BuyButton({required this.symbol, required this.onTap});

  final String symbol;
  final VoidCallback onTap;

  @override
  State<_BuyButton> createState() => _BuyButtonState();
}

class _BuyButtonState extends State<_BuyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              colors.sky,
              colors.sky.withValues(alpha: 0.85),
              colors.mint.withValues(alpha: 0.7),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: colors.sky.withValues(alpha: _pressed ? 0.15 : 0.25),
              blurRadius: _pressed ? 12 : 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        transform: Matrix4.identity()
          ..scale(_pressed ? 0.98 : 1.0),
        transformAlignment: Alignment.center,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shopping_cart_rounded,
                size: 18,
                color: colors.skyButtonInk,
              ),
              const SizedBox(width: 10),
              Text(
                'Buy ${widget.symbol} Tokens',
                style: context.kidunaText.labelStrong.copyWith(
                  color: colors.skyButtonInk,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Notice for upcoming presales.
class _UpcomingNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.gold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.gold.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 18, color: colors.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This presale has not started yet. Come back when the countdown reaches zero.',
              style: context.kidunaText.bodySm.copyWith(
                color: colors.gold.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _truncate(String s, int max) {
  if (s.length <= max) return s;
  final half = (max - 3) ~/ 2;
  return '${s.substring(0, half)}...${s.substring(s.length - half)}';
}
