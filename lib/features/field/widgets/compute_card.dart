import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/env.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../compute/controllers/compute_controller.dart';
import '../../compute/open_buy_kiduna.dart';
import '../../compute/screens/compute_details_screen.dart';
import '../../compute/widgets/kiduna_purchase_panel.dart';

/// The Compute panel body: the Source's live KIDUNA balance, exchange rate,
/// total value, and a "Buy More KIDUNA" action.
///
/// On desktop the buy action opens the web purchase page in the browser.
/// On web it pushes the purchase screen in-app.
class ComputeCard extends ConsumerStatefulWidget {
  const ComputeCard({super.key});

  @override
  ConsumerState<ComputeCard> createState() => _ComputeCardState();
}

class _ComputeCardState extends ConsumerState<ComputeCard>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(computeControllerProvider.notifier).loadBalance();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh the balance when the user returns from the browser purchase.
    if (state == AppLifecycleState.resumed && mounted) {
      ref.read(computeControllerProvider.notifier).refresh();
    }
  }

  Future<void> _openDetails() async {
    if (kIsWeb) {
      // Web — navigate in-app
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ComputeDetailsScreen()),
      );
    } else {
      // Desktop/mobile — open in browser
      final base =
          Env.webAppUrl.isNotEmpty ? Env.webAppUrl : 'https://mobile.kiduna.dev';
      final uri = Uri.parse('$base/compute-details');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
    if (!mounted) return;
    ref.read(computeControllerProvider.notifier).refresh();
  }

  Future<void> _openBuyPage() async {
    await openBuyKidunaPage(context);
    if (!mounted) return;
    ref.read(computeControllerProvider.notifier).refresh();
  }

  String _formatUsd(double value) {
    if (value >= 1000) return '\$${value.toStringAsFixed(0)}';
    if (value >= 1) return '\$${value.toStringAsFixed(2)}';
    return '\$${value.toStringAsFixed(4)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final compute = ref.watch(computeControllerProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ─────────────────────────────────────────
          Text(
            context.l10n.compute.toUpperCase(),
            style: text.eyebrowSmall.copyWith(color: colors.gold),
          ),

          const SizedBox(height: 10),

          // ── Buy button ───────────────────────────────────────
          Semantics(
            button: true,
            label: 'Buy More KIDUNA',
            child: InkWell(
              onTap: _openBuyPage,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: colors.gold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline,
                        size: 13, color: colors.gold),
                    const SizedBox(width: 6),
                    Text(
                      'Buy More KIDUNA',
                      style: text.label.copyWith(
                        color: colors.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
          Semantics(
            button: true,
            label: 'View compute details',
            child: InkWell(
              onTap: _openDetails,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'View Details',
                    style: text.label.copyWith(color: colors.sky),
                  ),
                  Icon(Icons.north_east, size: 12, color: colors.sky),
                ],
              ),
            ),
          ),

          if (compute.error != null) ...[
            const SizedBox(height: 6),
            Text(
              compute.error!,
              style: text.micro.copyWith(color: colors.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _Rate extends StatelessWidget {
  const _Rate({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Container(
      padding: const EdgeInsets.only(top: 7),
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
          Text(value, style: text.label.copyWith(color: colors.muted)),
        ],
      ),
    );
  }
}