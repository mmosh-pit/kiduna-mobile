import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../shared/animations/slide_in_animation.dart';
import '../../../shared/widgets/kiduna_gold_button.dart';

class SignupStepSeven extends StatefulWidget {
  const SignupStepSeven({
    super.key,
    required this.onPurchase,
    required this.onSkip,
    required this.onBack,
    required this.onError,
    required this.tokenPrice,
    this.isLoading = false,
    this.waitingForPayment = false,
    this.onVerifyPayment,
    this.onRetryPayment,
  });

  final ValueChanged<double> onPurchase;
  final VoidCallback onSkip;
  final VoidCallback onBack;
  final ValueChanged<String> onError;

  /// Token price: 1 KIDUNA = $tokenPrice USDC (e.g., 0.00001)
  final double tokenPrice;

  final bool isLoading;

  /// True when Stripe is open and we're waiting for the user to complete payment.
  final bool waitingForPayment;

  /// Called when user clicks "I've Paid" to verify payment.
  final VoidCallback? onVerifyPayment;

  /// Called when user wants to reopen the Stripe payment page.
  final VoidCallback? onRetryPayment;

  @override
  State<SignupStepSeven> createState() => _SignupStepSevenState();
}

class _SignupStepSevenState extends State<SignupStepSeven> {
  final _usdcController = TextEditingController(text: '100');
  double _kidunaAmount = 0;

  @override
  void initState() {
    super.initState();
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
      _kidunaAmount =
          widget.tokenPrice > 0 ? usdc / widget.tokenPrice : 0;
    });
  }

  void _validate() {
    if (widget.isLoading) return;

    final usdc = double.tryParse(_usdcController.text) ?? 0;
    if (usdc <= 0) {
      widget.onError('Please enter an amount greater than 0.');
      return;
    }

    widget.onPurchase(usdc);
  }

  String _formatKiduna(double amount) {
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
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return SlideInAnimation(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackButton(onPressed: widget.onBack),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: text.body.copyWith(
                color: colors.muted,
                fontSize: 13,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: 'Step 7 of 7',
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(text: ' · Get KIDUNA Tokens'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Purchase KIDUNA tokens to participate in the ecosystem. '
            'Pay with your card — we handle the conversion.',
            style: text.body.copyWith(
              color: colors.muted,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          // ── You Pay ──────────────────────────────────────────
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
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    style: text.h2.copyWith(
                      color: colors.text,
                      fontSize: 28,
                    ),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.sky.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.sky.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'USDC',
                    style: text.body.copyWith(
                      color: colors.sky,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Swap arrow ───────────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.deep,
                  border: Border.all(
                    color: colors.camel.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.swap_vert,
                  size: 18,
                  color: colors.gold,
                ),
              ),
            ),
          ),

          // ── You Receive ──────────────────────────────────────
          _SwapCard(
            label: 'You Receive',
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formatKiduna(_kidunaAmount),
                    style: text.h2.copyWith(
                      color: colors.gold,
                      fontSize: 28,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'KIDUNA',
                    style: text.body.copyWith(
                      color: colors.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Rate info ────────────────────────────────────────
          Center(
            child: Text(
              '1 KIDUNA = \$${widget.tokenPrice} USDC',
              style: text.caption.copyWith(
                color: colors.quiet,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Waiting for payment state ────────────────────────
          if (widget.waitingForPayment) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: colors.gold.withValues(alpha: 0.25)),
              ),
              child: Column(
                children: [
                  Icon(Icons.hourglass_top_rounded,
                      size: 28, color: colors.gold),
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
              label: widget.isLoading
                  ? 'Verifying...'
                  : "I've Paid — Verify",
              onPressed:
                  widget.isLoading ? null : widget.onVerifyPayment,
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
          ] else ...[
            // ── Normal state — buy button ──────────────────────
            KidunaGoldButton(
              label: widget.isLoading
                  ? 'Processing...'
                  : 'Buy with Card',
              onPressed: widget.isLoading ? null : _validate,
            ),
            const SizedBox(height: 16),
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
      ),
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
        border: Border.all(
          color: colors.camel.withValues(alpha: 0.25),
        ),
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

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: colors.sky,
        textStyle: const TextStyle(
          fontFamily: 'Avenir',
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: const Text('← Back'),
    );
  }
}