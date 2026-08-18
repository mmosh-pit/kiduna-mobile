import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/presale_model.dart';
import 'presale_countdown.dart';
import 'presale_formatters.dart';
import 'presale_progress_bar.dart';
import 'presale_status_badge.dart';

/// Premium presale card with gradient borders, layered depth, glassmorphism,
/// and animated accents. Uses [PresaleModel] from the API.
class PresaleCard extends StatefulWidget {
  const PresaleCard({
    super.key,
    required this.presale,
    required this.onTap,
  });

  final PresaleModel presale;
  final VoidCallback onTap;

  @override
  State<PresaleCard> createState() => _PresaleCardState();
}

class _PresaleCardState extends State<PresaleCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
    if (widget.presale.isLive) _glowCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final p = widget.presale;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (context, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              transform: Matrix4.identity()..scale(_hovered ? 1.008 : 1.0),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (p.isLive)
                    BoxShadow(
                      color: colors.sky.withValues(
                        alpha: 0.04 + (_glowAnim.value * 0.08),
                      ),
                      blurRadius: 32,
                      spreadRadius: -2,
                    ),
                  if (_hovered)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                ],
              ),
              child: child,
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: p.isLive
                      ? const [
                          Color(0xFF1A1612),
                          Color(0xFF14110E),
                          Color(0xFF0F0D0B),
                        ]
                      : [colors.surface, colors.surface],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hovered
                      ? (p.isLive
                          ? colors.sky.withValues(alpha: 0.3)
                          : colors.camel.withValues(alpha: 0.3))
                      : colors.line,
                  width: _hovered ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.isLive)
                    Container(
                      height: 3,
                      decoration: BoxDecoration(
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
                    padding: EdgeInsets.fromLTRB(
                      22, p.isLive ? 18 : 22, 22, 22,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CardHeader(presale: p),
                        const SizedBox(height: 16),
                        _PriceRow(presale: p),
                        const SizedBox(height: 18),
                        PresaleProgressBar(
                          sold: formatTokenNumber(p.tokensSold),
                          total: formatTokenNumber(p.presaleSupply),
                          progress: p.progress,
                        ),
                        const SizedBox(height: 18),
                        if (p.isLive)
                          PresaleCountdown(
                            targetDate: p.endDate,
                            label: 'Ends in',
                          ),
                        if (p.isUpcoming)
                          PresaleCountdown(
                            targetDate: p.startDate,
                            label: 'Starts in',
                          ),
                        if (p.isCompleted) _CompletedRow(),
                        const SizedBox(height: 16),
                        Container(height: 1, color: colors.line),
                        const SizedBox(height: 14),
                        _CardFooter(presale: p),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.presale});
  final PresaleModel presale;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.raised, colors.raisedAlt],
            ),
            border: Border.all(
              color: colors.gold.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.gold.withValues(alpha: 0.08),
                blurRadius: 12,
              ),
            ],
          ),
          child: Center(
            child: Text(
              presale.tokenSymbol.isNotEmpty ? presale.tokenSymbol[0] : '?',
              style: context.kidunaText.heading.copyWith(
                color: colors.gold,
                fontSize: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                presale.tokenName,
                style: context.kidunaText.labelStrong.copyWith(
                  color: colors.cream,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                presale.tokenSymbol,
                style: context.kidunaText.micro.copyWith(
                  color: colors.quiet,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        PresaleStatusBadge(status: presale.status),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.presale});
  final PresaleModel presale;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '\$${formatPrice(presale.pricePerToken)}',
          style: context.kidunaText.display.copyWith(
            color: colors.sky,
            fontSize: 28,
          ),
        ),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'per token',
            style: context.kidunaText.micro.copyWith(
              color: colors.sky.withValues(alpha: 0.5),
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: colors.camel.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.camel.withValues(alpha: 0.15)),
          ),
          child: Text(
            '${formatTokenNumber(presale.presaleSupply)} supply',
            style: context.kidunaText.micro.copyWith(
              color: colors.camel,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompletedRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.muted.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: colors.muted),
          const SizedBox(width: 8),
          Text(
            'Sale completed',
            style: context.kidunaText.bodySm.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}

class _CardFooter extends StatelessWidget {
  const _CardFooter({required this.presale});
  final PresaleModel presale;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Row(
      children: [
        Icon(Icons.swap_vert_rounded, size: 13, color: colors.quiet),
        const SizedBox(width: 6),
        Text(
          '\$${formatUsdc(presale.minPurchaseUsdc)} – \$${formatUsdc(presale.maxPurchaseUsdc)}',
          style: context.kidunaText.micro.copyWith(color: colors.quiet),
        ),
        const Spacer(),
        Icon(Icons.calendar_today_outlined, size: 12, color: colors.quiet),
        const SizedBox(width: 6),
        Text(
          '${formatDate(presale.startDate)} – ${formatDate(presale.endDate)}',
          style: context.kidunaText.micro.copyWith(color: colors.quiet),
        ),
      ],
    );
  }
}
