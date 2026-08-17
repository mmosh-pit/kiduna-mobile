import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/extensions/context_extensions.dart';
import '../models/presale_mock_data.dart';
import 'presale_formatters.dart';

/// Bottom sheet for purchasing presale tokens.
///
/// User enters a USDC amount; the sheet live-previews how many tokens they
/// will receive. Validates against min/max purchase limits. [onConfirm] is
/// called with the validated USDC amount — for now it shows a success
/// snackbar; API integration will replace this.
class PresaleBuySheet extends StatefulWidget {
  const PresaleBuySheet({
    super.key,
    required this.presale,
    required this.onConfirm,
  });

  final PresaleMockItem presale;
  final void Function(double usdcAmount) onConfirm;

  @override
  State<PresaleBuySheet> createState() => _PresaleBuySheetState();
}

class _PresaleBuySheetState extends State<PresaleBuySheet> {
  final _controller = TextEditingController();
  String? _error;

  double get _price => double.tryParse(widget.presale.pricePerToken) ?? 0;
  double get _min => double.tryParse(widget.presale.minPurchaseUsdc) ?? 0;
  double get _max => double.tryParse(widget.presale.maxPurchaseUsdc) ?? 0;

  double get _usdcAmount => double.tryParse(_controller.text) ?? 0;
  double get _tokenAmount => _price > 0 ? _usdcAmount / _price : 0;

  void _validate() {
    final amount = _usdcAmount;
    setState(() {
      if (_controller.text.isEmpty) {
        _error = null;
      } else if (amount <= 0) {
        _error = 'Enter a valid amount';
      } else if (amount < _min) {
        _error = 'Minimum purchase is \$${formatUsdc(widget.presale.minPurchaseUsdc)} USDC';
      } else if (amount > _max) {
        _error = 'Maximum purchase is \$${formatUsdc(widget.presale.maxPurchaseUsdc)} USDC';
      } else {
        _error = null;
      }
    });
  }

  bool get _canConfirm =>
      _error == null && _controller.text.isNotEmpty && _usdcAmount > 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_validate);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    // Account for keyboard
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: colors.raised,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: colors.line),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Handle ──
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.quiet,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Title ──
          Text(
            'Buy ${widget.presale.tokenSymbol} Tokens',
            style: context.kidunaText.heading.copyWith(color: colors.cream),
          ),
          const SizedBox(height: 20),

          // ── USDC amount input ──
          Text(
            'USDC Amount',
            style: context.kidunaText.label.copyWith(color: colors.muted),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,6}')),
            ],
            style: context.kidunaText.bodyLarge.copyWith(color: colors.cream),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: context.kidunaText.bodyLarge.copyWith(
                color: colors.quiet,
              ),
              prefixText: '\$ ',
              prefixStyle: context.kidunaText.bodyLarge.copyWith(
                color: colors.muted,
              ),
              filled: true,
              fillColor: colors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.sky, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.error),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // ── Min/Max hint or error ──
          SizedBox(
            height: 20,
            child: _error != null
                ? Text(
                    _error!,
                    style: context.kidunaText.micro.copyWith(
                      color: colors.error,
                    ),
                  )
                : Text(
                    'Min: \$${formatUsdc(widget.presale.minPurchaseUsdc)}  ·  '
                    'Max: \$${formatUsdc(widget.presale.maxPurchaseUsdc)}',
                    style: context.kidunaText.micro.copyWith(
                      color: colors.quiet,
                    ),
                  ),
          ),
          const SizedBox(height: 20),

          // ── Token preview ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You will receive',
                  style: context.kidunaText.bodySm.copyWith(
                    color: colors.muted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_formatTokenPreview(_tokenAmount)} ${widget.presale.tokenSymbol}',
                  style: context.kidunaText.heading.copyWith(
                    color: colors.gold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Price: \$${formatPrice(widget.presale.pricePerToken)} per token',
                  style: context.kidunaText.micro.copyWith(
                    color: colors.quiet,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Confirm button ──
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _canConfirm
                  ? () => widget.onConfirm(_usdcAmount)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.sky,
                foregroundColor: colors.skyButtonInk,
                disabledBackgroundColor: colors.sky.withValues(alpha: 0.2),
                disabledForegroundColor: colors.muted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Confirm Purchase',
                style: context.kidunaText.labelStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formats the live token preview amount with commas.
String _formatTokenPreview(double amount) {
  if (amount <= 0) return '0';
  final n = amount.truncate();
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
