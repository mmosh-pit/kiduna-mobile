import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/presale_model.dart';
import '../../../data/models/purchase_model.dart';
import 'presale_formatters.dart';

/// Bottom sheet for purchasing presale tokens.
///
/// Shows a loading state with status messages while the blockchain
/// transaction processes (~60s). Displays success or error result
/// without closing — the user dismisses manually.
class PresaleBuySheet extends StatefulWidget {
  const PresaleBuySheet({
    super.key,
    required this.presale,
    required this.onConfirm,
  });

  final PresaleModel presale;
  final Future<PurchaseModel?> Function(double usdcAmount) onConfirm;

  @override
  State<PresaleBuySheet> createState() => _PresaleBuySheetState();
}

class _PresaleBuySheetState extends State<PresaleBuySheet>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  String? _error;
  bool _processing = false;
  PurchaseModel? _result;
  String? _txError;
  String _statusMessage = '';

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
      _error == null &&
      _controller.text.isNotEmpty &&
      _usdcAmount > 0 &&
      !_processing;

  Future<void> _handleConfirm() async {
    setState(() {
      _processing = true;
      _txError = null;
      _result = null;
      _statusMessage = 'Initiating transaction...';
    });

    // Simulate status progression for UX feedback
    Future.delayed(const Duration(seconds: 3), () {
      if (_processing && mounted) {
        setState(() => _statusMessage = 'Processing USDC payment...');
      }
    });
    Future.delayed(const Duration(seconds: 15), () {
      if (_processing && mounted) {
        setState(() => _statusMessage = 'Confirming payment on-chain...');
      }
    });
    Future.delayed(const Duration(seconds: 30), () {
      if (_processing && mounted) {
        setState(() => _statusMessage = 'Delivering tokens to your wallet...');
      }
    });
    Future.delayed(const Duration(seconds: 45), () {
      if (_processing && mounted) {
        setState(() => _statusMessage = 'Confirming delivery on-chain...');
      }
    });

    try {
      final result = await widget.onConfirm(_usdcAmount);
      if (mounted) {
        setState(() {
          _processing = false;
          _result = result;
          _statusMessage = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _processing = false;
          _txError = e.toString();
          _statusMessage = '';
        });
      }
    }
  }

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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: !_processing,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
        decoration: BoxDecoration(
          color: colors.raised,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          border: Border(top: BorderSide(color: colors.line)),
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

            // Show processing, success, or error state
            if (_processing)
              _ProcessingView(statusMessage: _statusMessage)
            else if (_result != null)
              _SuccessView(
                result: _result!,
                symbol: widget.presale.tokenSymbol,
                onDone: () => Navigator.of(context).pop(),
              )
            else if (_txError != null)
              _ErrorView(
                error: _txError!,
                onRetry: _handleConfirm,
                onDismiss: () => setState(() => _txError = null),
              )
            else
              _InputView(
                presale: widget.presale,
                controller: _controller,
                error: _error,
                canConfirm: _canConfirm,
                usdcAmount: _usdcAmount,
                tokenAmount: _tokenAmount,
                onConfirm: _handleConfirm,
              ),
          ],
        ),
      ),
    );
  }
}

/// The default input form — USDC amount, preview, confirm button.
class _InputView extends StatelessWidget {
  const _InputView({
    required this.presale,
    required this.controller,
    required this.error,
    required this.canConfirm,
    required this.usdcAmount,
    required this.tokenAmount,
    required this.onConfirm,
  });

  final PresaleModel presale;
  final TextEditingController controller;
  final String? error;
  final bool canConfirm;
  final double usdcAmount;
  final double tokenAmount;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Buy ${presale.tokenSymbol} Tokens',
          style: context.kidunaText.heading.copyWith(color: colors.cream),
        ),
        const SizedBox(height: 20),
        Text(
          'USDC Amount',
          style: context.kidunaText.label.copyWith(color: colors.muted),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,6}')),
          ],
          style: context.kidunaText.bodyLarge.copyWith(color: colors.cream),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: context.kidunaText.bodyLarge.copyWith(color: colors.quiet),
            prefixText: '\$ ',
            prefixStyle: context.kidunaText.bodyLarge.copyWith(color: colors.muted),
            filled: true,
            fillColor: colors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 20,
          child: error != null
              ? Text(error!, style: context.kidunaText.micro.copyWith(color: colors.error))
              : Text(
                  'Min: \$${formatUsdc(presale.minPurchaseUsdc)}  ·  Max: \$${formatUsdc(presale.maxPurchaseUsdc)}',
                  style: context.kidunaText.micro.copyWith(color: colors.quiet),
                ),
        ),
        const SizedBox(height: 20),
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
              Text('You will receive',
                  style: context.kidunaText.bodySm.copyWith(color: colors.muted)),
              const SizedBox(height: 6),
              Text(
                '${_formatTokenPreview(tokenAmount)} ${presale.tokenSymbol}',
                style: context.kidunaText.heading.copyWith(color: colors.gold),
              ),
              const SizedBox(height: 4),
              Text(
                'Price: \$${formatPrice(presale.pricePerToken)} per token',
                style: context.kidunaText.micro.copyWith(color: colors.quiet),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: canConfirm ? onConfirm : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.sky,
              foregroundColor: colors.skyButtonInk,
              disabledBackgroundColor: colors.sky.withValues(alpha: 0.2),
              disabledForegroundColor: colors.muted,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Confirm Purchase', style: context.kidunaText.labelStrong),
          ),
        ),
      ],
    );
  }
}

/// Processing state — spinner, status messages, progress dots.
class _ProcessingView extends StatelessWidget {
  const _ProcessingView({required this.statusMessage});

  final String statusMessage;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colors.sky,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Processing Transaction',
            style: context.kidunaText.heading.copyWith(color: colors.cream),
          ),
          const SizedBox(height: 12),
          Text(
            statusMessage,
            style: context.kidunaText.bodySm.copyWith(color: colors.sky),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.sky.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.sky.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: colors.sky.withValues(alpha: 0.6)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This involves two blockchain transactions and may take up to 60 seconds. Please do not close this window.',
                    style: context.kidunaText.micro.copyWith(
                      color: colors.sky.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Success state — purchase confirmed, signatures shown.
class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.result,
    required this.symbol,
    required this.onDone,
  });

  final PurchaseModel result;
  final String symbol;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.mint.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.check_rounded, size: 32, color: colors.mint),
          ),
          const SizedBox(height: 20),
          Text(
            'Purchase Successful!',
            style: context.kidunaText.heading.copyWith(color: colors.cream),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatTokenPreview(double.tryParse(result.tokenAmount) ?? 0)} $symbol',
            style: context.kidunaText.display.copyWith(
              color: colors.gold,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${formatUsdc(result.usdcAmount)} USDC',
            style: context.kidunaText.bodySm.copyWith(color: colors.muted),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.line),
            ),
            child: Column(
              children: [
                _SignatureRow(label: 'Payment TX', sig: result.paymentSignature),
                const SizedBox(height: 8),
                if (result.deliverySignature != null)
                  _SignatureRow(label: 'Delivery TX', sig: result.deliverySignature!),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.mint,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Done', style: context.kidunaText.labelStrong),
            ),
          ),
        ],
      ),
    );
  }
}

/// Signature row with copy button.
class _SignatureRow extends StatelessWidget {
  const _SignatureRow({required this.label, required this.sig});

  final String label;
  final String sig;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final truncated = sig.length > 20
        ? '${sig.substring(0, 10)}...${sig.substring(sig.length - 10)}'
        : sig;

    return Row(
      children: [
        Text(label, style: context.kidunaText.micro.copyWith(color: colors.quiet)),
        const Spacer(),
        Text(
          truncated,
          style: context.kidunaText.micro.copyWith(
            color: colors.muted,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: sig));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label signature copied'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Icon(Icons.content_copy_rounded, size: 13, color: colors.quiet),
        ),
      ],
    );
  }
}

/// Error state — retry or dismiss.
class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.error,
    required this.onRetry,
    required this.onDismiss,
  });

  final String error;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.error.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.close_rounded, size: 32, color: colors.error),
          ),
          const SizedBox(height: 20),
          Text(
            'Purchase Failed',
            style: context.kidunaText.heading.copyWith(color: colors.cream),
          ),
          const SizedBox(height: 12),
          Text(
            error,
            style: context.kidunaText.bodySm.copyWith(color: colors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: onDismiss,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colors.line),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Back', style: TextStyle(color: colors.muted)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.sky,
                      foregroundColor: colors.skyButtonInk,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Retry', style: context.kidunaText.labelStrong),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
