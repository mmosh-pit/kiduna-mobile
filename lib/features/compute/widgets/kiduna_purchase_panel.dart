import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../shared/widgets/kiduna_gold_button.dart';

/// Reusable KIDUNA purchase UI — swap input, fee breakdown, token info,
/// confirmation checkbox, and buy button. Also renders the waiting state
/// while the Stripe onramp is open.
class KidunaPurchasePanel extends StatefulWidget {
  const KidunaPurchasePanel({
    super.key,
    required this.tokenPrice,
    required this.onPurchase,
    required this.onError,
    this.currentBalance,
    this.onVerifyPayment,
    this.onRetryPayment,
    this.onSkip,
    this.isLoading = false,
    this.waitingForPayment = false,
    this.initialAmount = '100',
  });

  final double tokenPrice;
  final ValueChanged<double> onPurchase;
  final ValueChanged<String> onError;
  final double? currentBalance;
  final VoidCallback? onVerifyPayment;
  final VoidCallback? onRetryPayment;
  final VoidCallback? onSkip;
  final bool isLoading;
  final bool waitingForPayment;
  final String initialAmount;

  static String formatKiduna(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(2)}B';
    }
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)}K';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  State<KidunaPurchasePanel> createState() => _KidunaPurchasePanelState();
}

class _KidunaPurchasePanelState extends State<KidunaPurchasePanel> {
  late final TextEditingController _usdcController;
  double _kidunaAmount = 0;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _usdcController = TextEditingController(text: widget.initialAmount);
    _recalculate();
    _usdcController.addListener(_recalculate);
  }

  @override
  void dispose() {
    _usdcController.dispose();
    super.dispose();
  }

  void _recalculate() {
    final usdc = double.tryParse(_usdcController.text) ?? 0;
    setState(() {
      _kidunaAmount = widget.tokenPrice > 0 ? usdc / widget.tokenPrice : 0;
    });
  }

  double get _usdcAmount => double.tryParse(_usdcController.text) ?? 0;
  double get _estimatedFee => _usdcAmount * 0.06;
  double get _totalCharge => _usdcAmount + _estimatedFee;

  void _onBuyPressed() {
    if (widget.isLoading) return;
    if (_usdcAmount <= 0) {
      widget.onError('Please enter an amount greater than 0.');
      return;
    }
    if (!_confirmed) {
      widget.onError('Please confirm that you understand the terms.');
      return;
    }
    widget.onPurchase(_usdcAmount);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    if (widget.waitingForPayment) {
      return _buildWaitingPanel(colors, text);
    }
    return _buildSwapPanel(colors, text);
  }

  Widget _buildSwapPanel(dynamic colors, dynamic text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.currentBalance != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.gold.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.gold.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Balance',
                  style: text.caption.copyWith(
                    color: colors.muted,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${KidunaPurchasePanel.formatKiduna(widget.currentBalance!)} KIDUNA',
                  style: text.body.copyWith(
                    color: colors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        _SwapCard(
          label: 'You Pay',
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _usdcController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  style: text.h2.copyWith(color: colors.text, fontSize: 28),
                  cursorColor: colors.sky,
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: text.h2.copyWith(
                      color: colors.quiet.withValues(alpha: 0.4),
                      fontSize: 28,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              _Badge(label: 'USDC', color: colors.sky),
            ],
          ),
        ),

        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.deep,
                border: Border.all(color: colors.camel.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.swap_vert, size: 18, color: colors.gold),
            ),
          ),
        ),

        _SwapCard(
          label: 'You Receive',
          child: Row(
            children: [
              Expanded(
                child: Text(
                  KidunaPurchasePanel.formatKiduna(_kidunaAmount),
                  style: text.h2.copyWith(color: colors.gold, fontSize: 28),
                ),
              ),
              _Badge(label: 'KIDUNA', color: colors.gold),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.deep.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.camel.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              _ReviewRow(
                label: 'Amount',
                value: '\$${_usdcAmount.toStringAsFixed(2)} USD',
                colors: colors,
                text: text,
              ),
              const SizedBox(height: 6),
              _ReviewRow(
                label: 'Processing Fee (~6%)',
                value: '~\$${_estimatedFee.toStringAsFixed(2)}',
                colors: colors,
                text: text,
                isMuted: true,
              ),
              const SizedBox(height: 8),
              Container(height: 1, color: colors.camel.withValues(alpha: 0.15)),
              const SizedBox(height: 8),
              _ReviewRow(
                label: 'Total Charge',
                value: '~\$${_totalCharge.toStringAsFixed(2)} USD',
                colors: colors,
                text: text,
                isBold: true,
              ),
              const SizedBox(height: 8),
              _ReviewRow(
                label: 'You Receive',
                value:
                    '${KidunaPurchasePanel.formatKiduna(_kidunaAmount)} KIDUNA',
                colors: colors,
                text: text,
                isGold: true,
                isBold: true,
              ),
              const SizedBox(height: 4),
              _ReviewRow(
                label: 'Rate',
                value: '1 KIDUNA = \$${widget.tokenPrice}',
                colors: colors,
                text: text,
                isMuted: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.gold.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.gold.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About KIDUNA Tokens',
                style: text.body.copyWith(
                  color: colors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              _InfoBullet(
                text: text,
                colors: colors,
                label: 'Used for AI chat compute costs',
              ),
              _InfoBullet(
                text: text,
                colors: colors,
                label: 'Digital tokens held on the platform',
              ),
              _InfoBullet(
                text: text,
                colors: colors,
                label: 'Non-transferable and non-refundable',
              ),
              _InfoBullet(
                text: text,
                colors: colors,
                label: 'Cannot be withdrawn to an external wallet',
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        GestureDetector(
          onTap: () => setState(() => _confirmed = !_confirmed),
          behavior: HitTestBehavior.opaque,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _confirmed
                        ? colors.gold
                        : colors.camel.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  color: _confirmed
                      ? colors.gold.withValues(alpha: 0.15)
                      : Colors.transparent,
                ),
                child: _confirmed
                    ? Icon(Icons.check, size: 14, color: colors.gold)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'I understand this purchase is final. KIDUNA tokens are '
                  'non-refundable and non-transferable.',
                  style: text.caption.copyWith(
                    color: colors.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        KidunaGoldButton(
          label: widget.isLoading ? 'Processing...' : 'Buy with Card',
          onPressed: widget.isLoading || !_confirmed ? null : _onBuyPressed,
        ),

        if (widget.onSkip != null) ...[
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: widget.isLoading ? null : widget.onSkip,
              style: TextButton.styleFrom(
                foregroundColor: colors.muted,
                textStyle: text.body.copyWith(fontSize: 13),
              ),
              child: const Text('Skip for now →'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWaitingPanel(dynamic colors, dynamic text) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.gold.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.gold.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Icon(Icons.hourglass_top_rounded, size: 28, color: colors.gold),
              const SizedBox(height: 8),
              Text(
                'Waiting for payment...',
                style: text.body.copyWith(
                  color: colors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Complete the payment in your browser, then click the button below.',
                style: text.caption.copyWith(
                  color: colors.muted,
                  fontSize: 12,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        KidunaGoldButton(
          label: widget.isLoading ? 'Verifying...' : "I've Paid — Verify",
          onPressed: widget.isLoading ? null : widget.onVerifyPayment,
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton.icon(
            onPressed: widget.isLoading ? null : widget.onRetryPayment,
            icon: Icon(Icons.open_in_new, size: 16, color: colors.sky),
            label: Text(
              'Reopen Payment Page',
              style: text.body.copyWith(
                color: colors.sky,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SwapCard extends StatelessWidget {
  const _SwapCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.deep.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.camel.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: text.caption.copyWith(
              color: colors.quiet,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = context.kidunaText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: text.body.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    required this.colors,
    required this.text,
    this.isMuted = false,
    this.isBold = false,
    this.isGold = false,
  });

  final String label;
  final String value;
  final dynamic colors;
  final dynamic text;
  final bool isMuted;
  final bool isBold;
  final bool isGold;

  @override
  Widget build(BuildContext context) {
    final labelColor = isMuted ? colors.quiet : colors.muted;
    final valueColor = isGold ? colors.gold : colors.text;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: text.caption.copyWith(
            color: labelColor,
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: text.body.copyWith(
            color: valueColor,
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _InfoBullet extends StatelessWidget {
  const _InfoBullet({
    required this.text,
    required this.colors,
    required this.label,
  });

  final dynamic text;
  final dynamic colors;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•  ',
            style: text.caption.copyWith(color: colors.muted, fontSize: 11),
          ),
          Expanded(
            child: Text(
              label,
              style: text.caption.copyWith(
                color: colors.muted,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
