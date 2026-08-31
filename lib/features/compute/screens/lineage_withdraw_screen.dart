import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/logger.dart';
import '../../../core/wallet/phantom.dart';
import '../../../data/local/secure_storage.dart';
import '../../../data/models/lineage_reward_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/kiduna_gold_button.dart';
import '../../auth/screens/login_screen.dart';
import '../controllers/wallet_controller.dart';

/// Standalone lineage reward withdrawal page, reachable at /lineage-withdraw.
///
/// Same pattern as KIDUNA WithdrawScreen:
///   1. Backend builds USDC transfer tx (admin signs as authority)
///   2. Phantom co-signs (user pays fee)
///   3. Backend broadcasts and confirms
class LineageWithdrawScreen extends ConsumerStatefulWidget {
  const LineageWithdrawScreen({super.key});

  @override
  ConsumerState<LineageWithdrawScreen> createState() =>
      _LineageWithdrawScreenState();
}

class _LineageWithdrawScreenState extends ConsumerState<LineageWithdrawScreen> {
  bool _checkingAuth = true;
  bool _isAuthenticated = false;

  bool _loadingRewards = false;
  bool _submitting = false;
  bool _done = false;

  LineageRewardSummary? _summary;

  double _withdrawnAmount = 0;
  String? _txSignature;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await SecureStorage.instance.getToken();
    if (!mounted) return;

    if (token == null || token.isEmpty) {
      setState(() {
        _checkingAuth = false;
        _isAuthenticated = false;
      });
      return;
    }

    setState(() {
      _checkingAuth = false;
      _isAuthenticated = true;
    });

    _loadRewards();
  }

  Future<void> _loadRewards() async {
    setState(() {
      _loadingRewards = true;
      _error = null;
    });

    try {
      final data = await AuthService.instance.getLineageRewards();
      if (!mounted) return;

      if (data.isEmpty) {
        setState(() {
          _summary = null;
          _loadingRewards = false;
        });
        return;
      }

      setState(() {
        _summary = LineageRewardSummary.fromJson(data);
        _loadingRewards = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingRewards = false;
        _error = 'Failed to load rewards.';
      });
    }
  }

  Future<void> _withdraw() async {
    if (_summary == null || _summary!.available <= 0) return;

    final walletState = ref.read(walletControllerProvider);
    final phantomAddress = walletState.address;

    if (phantomAddress == null || phantomAddress.isEmpty) {
      setState(() => _error = 'Please connect your Phantom wallet first.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      // 1. Backend builds USDC transfer tx (admin signs as token authority)
      final prepared = await AuthService.instance.postWithAuth(
        '/kiduna/lineage-withdraw',
        {'recipient': phantomAddress},
      );

      if (!mounted) return;

      final data = prepared?['data'] as Map<String, dynamic>? ?? prepared;
      final txBase64 = data?['transaction'] as String?;
      final claimableIds = (data?['claimableRewardIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final readyAmount =
          double.tryParse(data?['available']?.toString() ?? '') ?? 0;

      if (txBase64 == null || txBase64.isEmpty) {
        setState(() {
          _error = data?['error'] as String? ??
              'Could not prepare withdrawal. Please try again.';
          _submitting = false;
        });
        return;
      }

      // 2. Phantom co-signs (user pays SOL fee)
      final signed = await PhantomWallet.signTransaction(txBase64);
      if (!mounted) return;

      if (signed == null) {
        setState(() {
          _error = 'Signature declined. No funds were moved.';
          _submitting = false;
        });
        return;
      }

      // 3. Backend broadcasts the fully-signed tx and records withdrawal
      final result = await AuthService.instance.postWithAuth(
        '/kiduna/lineage-withdraw/confirm',
        {
          'signedTransaction': signed,
          'claimedAmount': readyAmount,
        },
      );

      if (!mounted) return;

      final resultData =
          result?['data'] as Map<String, dynamic>? ?? result;
      final success = resultData?['success'] == true;

      if (!success) {
        setState(() {
          _error = resultData?['error'] as String? ??
              'Transaction failed. Your funds are safe — please try again.';
          _submitting = false;
        });
        return;
      }

      setState(() {
        _submitting = false;
        _done = true;
        _withdrawnAmount = readyAmount;
        _txSignature = resultData?['txSignature'] as String?;
      });

      AppLogger.info(
        'Lineage withdrawal complete: \$$readyAmount USDC, tx=$_txSignature',
        tag: 'LineageWithdraw',
      );
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message ?? 'Withdrawal failed.';
        _submitting = false;
      });
    } on NetworkException {
      if (!mounted) return;
      setState(() {
        _error = 'This is taking longer than expected. Check your balance '
            'before trying again.';
        _submitting = false;
      });
    } catch (e, st) {
      AppLogger.error('Lineage withdraw failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Scaffold(
      backgroundColor: colors.field,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildBody(colors, text),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(dynamic colors, dynamic text) {
    if (_checkingAuth) {
      return Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: colors.gold),
      );
    }

    if (!_isAuthenticated) {
      return _buildLoginPrompt(colors, text);
    }

    if (_done) {
      return _buildSuccess(colors, text);
    }

    if (_loadingRewards) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2, color: colors.gold),
            const SizedBox(height: 16),
            Text('Loading rewards...',
                style: text.body.copyWith(color: colors.muted)),
          ],
        ),
      );
    }

    return _buildWithdrawForm(colors, text);
  }

  Widget _buildLoginPrompt(dynamic colors, dynamic text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_outline, size: 48, color: colors.gold),
        const SizedBox(height: 16),
        Text('Sign In Required',
            style: text.h4.copyWith(color: colors.cream)),
        const SizedBox(height: 8),
        Text(
          'Please sign in to withdraw your lineage rewards.',
          textAlign: TextAlign.center,
          style: text.body.copyWith(color: colors.muted),
        ),
        const SizedBox(height: 24),
        KidunaGoldButton(
          label: 'Sign In',
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSuccess(dynamic colors, dynamic text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.mint.withValues(alpha: 0.15),
          ),
          child: Icon(Icons.check, size: 36, color: colors.mint),
        ),
        const SizedBox(height: 20),
        Text('Withdrawal Complete',
            style: text.h4.copyWith(color: colors.mint)),
        const SizedBox(height: 10),
        Text(
          '\$${_withdrawnAmount.toStringAsFixed(2)} USDC withdrawn successfully.',
          textAlign: TextAlign.center,
          style: text.body.copyWith(color: colors.cream, fontSize: 16),
        ),
        if (_txSignature != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.camel.withValues(alpha: 0.14)),
            ),
            child: Column(
              children: [
                Text('Transaction ID',
                    style: text.caption.copyWith(color: colors.muted, fontSize: 11)),
                const SizedBox(height: 6),
                Text(
                  _txSignature!,
                  textAlign: TextAlign.center,
                  style: text.caption.copyWith(
                    color: colors.cream,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _TxActionButton(
                      icon: Icons.copy,
                      label: 'Copy',
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: _txSignature!));
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Transaction ID copied'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: colors.mint,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    _TxActionButton(
                      icon: Icons.open_in_new,
                      label: 'Explorer',
                      onPressed: () {
                        final url = Uri.parse(
                          'https://solscan.io/tx/$_txSignature',
                        );
                        launchUrl(url, mode: LaunchMode.externalApplication);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'You can close this window.',
          style: text.caption.copyWith(color: colors.quiet),
        ),
      ],
    );
  }

  Widget _buildWithdrawForm(dynamic colors, dynamic text) {
    final ready = _summary?.available ?? 0;
    final claimed = _summary?.totalClaimed ?? 0;
    final walletState = ref.watch(walletControllerProvider);
    final isConnected =
        walletState.address != null && walletState.address!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Lineage Reward Withdrawal',
          style: text.h4.copyWith(color: colors.cream),
        ),
        const SizedBox(height: 6),
        Text(
          'Withdraw your available USDC lineage rewards to your Phantom wallet.',
          style: text.body.copyWith(color: colors.muted, height: 1.5),
        ),
        const SizedBox(height: 24),

        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.gold.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.gold.withValues(alpha: 0.18)),
          ),
          child: Column(
            children: [
              _summaryRow(colors, text, 'Available',
                  '\$${ready.toStringAsFixed(2)}', colors.gold),
              const SizedBox(height: 8),
              _summaryRow(colors, text, 'Previously Claimed',
                  '\$${claimed.toStringAsFixed(2)}', colors.mint),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Phantom wallet connection
        if (!isConnected) ...[
          Text(
            'Connect your Phantom wallet to withdraw:',
            style: text.body.copyWith(color: colors.muted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: KidunaGoldButton(
              label: 'Connect Phantom Wallet',
              onPressed: () {
                ref.read(walletControllerProvider.notifier).connect();
              },
            ),
          ),
        ] else ...[
          // Connected — show address + withdraw button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.mint.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet,
                    size: 18, color: colors.mint),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${walletState.address!.substring(0, 6)}...${walletState.address!.substring(walletState.address!.length - 4)}',
                    style: text.caption.copyWith(
                      color: colors.cream,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Text('Connected',
                    style: text.caption.copyWith(color: colors.mint)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (ready > 0) ...[
            SizedBox(
              width: double.infinity,
              child: _submitting
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                              strokeWidth: 2, color: colors.gold),
                          const SizedBox(height: 10),
                          Text('Waiting for signature...',
                              style: text.caption
                                  .copyWith(color: colors.muted)),
                        ],
                      ),
                    )
                  : KidunaGoldButton(
                      label:
                          'Withdraw \$${ready.toStringAsFixed(2)} USDC',
                      onPressed: _withdraw,
                    ),
            ),
          ] else
            Text(
              'No rewards available to withdraw at this time.',
              style: text.body.copyWith(color: colors.muted),
            ),
        ],

        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: colors.orange.withValues(alpha: 0.3)),
            ),
            child: Text(
              _error!,
              style:
                  text.caption.copyWith(color: colors.orange, height: 1.4),
            ),
          ),
        ],
      ],
    );
  }

  Widget _summaryRow(dynamic colors, dynamic text, String label, String value,
      Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: text.body.copyWith(color: colors.muted)),
        Text(
          value,
          style:
              text.body.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _TxActionButton extends StatelessWidget {
  const _TxActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14, color: colors.sky),
      label: Text(label, style: text.caption.copyWith(color: colors.sky)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        side: BorderSide(color: colors.sky.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
