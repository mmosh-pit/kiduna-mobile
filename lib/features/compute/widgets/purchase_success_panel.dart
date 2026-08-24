import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/file_download.dart' show closeWebWindow;
import '../../../shared/widgets/kiduna_gold_button.dart';
import 'kiduna_purchase_panel.dart';

/// Shown after a successful KIDUNA purchase.
/// On web, prompts the user to close the tab and return to the app.
class PurchaseSuccessPanel extends StatefulWidget {
  const PurchaseSuccessPanel({
    super.key,
    required this.kidunaReceived,
    required this.newBalance,
    this.onDone,
  });

  final double kidunaReceived;
  final double newBalance;

  /// Called when the user taps the primary action (non-web).
  final VoidCallback? onDone;

  @override
  State<PurchaseSuccessPanel> createState() => _PurchaseSuccessPanelState();
}

class _PurchaseSuccessPanelState extends State<PurchaseSuccessPanel> {
  /// True once we've tried to close the tab and the browser refused.
  bool _closeBlocked = false;

  void _handlePrimaryAction() {
    if (!kIsWeb) {
      widget.onDone?.call();
      return;
    }
    final closed = closeWebWindow();
    if (!closed && mounted) {
      setState(() => _closeBlocked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),

        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.gold.withValues(alpha: 0.12),
            border: Border.all(color: colors.gold.withValues(alpha: 0.35)),
          ),
          child: Icon(Icons.check_rounded, size: 38, color: colors.gold),
        ),

        const SizedBox(height: 22),

        Text(
          'Purchase Complete!',
          style: text.h4.copyWith(color: colors.gold),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 20),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.deep.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.camel.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              _Row(
                label: 'You Received',
                value:
                    '${KidunaPurchasePanel.formatKiduna(widget.kidunaReceived)} KIDUNA',
                colors: colors,
                text: text,
                isGold: true,
              ),
              const SizedBox(height: 10),
              Container(height: 1, color: colors.camel.withValues(alpha: 0.15)),
              const SizedBox(height: 10),
              _Row(
                label: 'New Balance',
                value:
                    '${KidunaPurchasePanel.formatKiduna(widget.newBalance)} KIDUNA',
                colors: colors,
                text: text,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.sky.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.sky.withValues(alpha: 0.18)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: colors.sky),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  kIsWeb
                      ? 'You can close this page and return to the Kiduna app. '
                          'Your balance will update automatically.'
                      : 'Your balance has been updated.',
                  style: text.caption.copyWith(
                    color: colors.muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        if (_closeBlocked)
          // The browser refused to close the tab (it wasn't opened by script).
          // Tell the user to close it themselves instead of leaving a dead button.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.gold.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                Icon(Icons.tab_unselected, size: 22, color: colors.gold),
                const SizedBox(height: 8),
                Text(
                  'Please close this tab manually',
                  style: text.body.copyWith(
                    color: colors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Your browser only allows tabs it opened to be closed '
                  'automatically. Your purchase is complete — you can safely '
                  'close this tab and return to the Kiduna app.',
                  style: text.caption.copyWith(
                    color: colors.muted,
                    fontSize: 11,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          KidunaGoldButton(
            label: kIsWeb ? 'Close Window' : 'Done',
            onPressed: _handlePrimaryAction,
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.colors,
    required this.text,
    this.isGold = false,
  });

  final String label;
  final String value;
  final dynamic colors;
  final dynamic text;
  final bool isGold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: text.caption.copyWith(color: colors.muted, fontSize: 12),
        ),
        Text(
          value,
          style: text.body.copyWith(
            color: isGold ? colors.gold : colors.text,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}