import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/logger.dart';
import '../../../core/wallet/phantom.dart';
import '../../../data/local/secure_storage.dart';
import '../../../data/services/auth_service.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/kiduna_gold_button.dart';
import '../../auth/screens/login_screen.dart';
import '../controllers/compute_controller.dart';
import '../controllers/wallet_controller.dart';
import '../widgets/kiduna_purchase_panel.dart';

/// Standalone KIDUNA withdrawal page, reachable at /withdraw.
///
/// Web-only by necessity: the payout requires a signature from a browser
/// wallet extension. The desktop app links here rather than trying to sign
/// locally.
class WithdrawScreen extends ConsumerStatefulWidget {
  const WithdrawScreen({super.key});

  @override
  ConsumerState<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends ConsumerState<WithdrawScreen> {
  final _amountController = TextEditingController();

  bool _checkingAuth = true;
  bool _isAuthenticated = false;

  bool _loadingEligibility = false;
  bool _submitting = false;
  bool _done = false;

  double _maxAmount = 0;
  double _tokenPrice = 0.00001;
  double _recipientSol = 0;
  double _minSol = 0.003;
  String? _blockedReason;

  double _withdrawnAmount = 0;
  String? _txSignature;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
    _bootstrap();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final token = await SecureStorage.instance.getToken();
    final signedIn = token != null && token.isNotEmpty;

    if (!mounted) return;
    setState(() {
      _isAuthenticated = signedIn;
      _checkingAuth = false;
    });

    if (signedIn) {
      await ref.read(computeControllerProvider.notifier).loadBalance();
      if (mounted) await _loadEligibility();
    }
  }

  /// Re-checked whenever the connected wallet changes: the SOL balance and
  /// payout ceiling are both properties of that specific wallet.
  Future<void> _loadEligibility() async {
    final wallet = ref.read(walletControllerProvider);
    setState(() => _loadingEligibility = true);

    try {
      final res = await AuthService.instance.getWithdrawEligibility(
        recipient: wallet.address,
      );
      if (!mounted) return;

      final canWithdraw = res['canWithdraw'] == true;
      setState(() {
        _tokenPrice = (res['tokenPrice'] as num?)?.toDouble() ?? 0.00001;
        _maxAmount = (res['maxAmount'] as num?)?.toDouble() ??
            ref.read(computeControllerProvider).balance;
        _recipientSol = (res['recipientSol'] as num?)?.toDouble() ?? 0;
        _minSol = (res['minSol'] as num?)?.toDouble() ?? 0.003;
        _loadingEligibility = false;
        _blockedReason = canWithdraw
            ? null
            : switch (res['reason']) {
                'wallet-not-connected' => null, // handled by the connect step
                'withdrawal-in-progress' =>
                  'You already have a withdrawal in progress. '
                      'It will clear within a few minutes.',
                'insufficient-sol' =>
                  'Your wallet needs at least ${_minSol.toStringAsFixed(3)} SOL '
                      'to receive tokens. It currently has '
                      '${_recipientSol.toStringAsFixed(4)} SOL.',
                'no-balance' => 'You have no KIDUNA to withdraw.',
                _ => 'Withdrawals are temporarily unavailable. '
                    'Please try again later.',
              };
      });
    } catch (e, st) {
      AppLogger.error('Eligibility failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loadingEligibility = false;
        _blockedReason = 'Could not check withdrawal availability.';
      });
    }
  }

  double get _amount => double.tryParse(_amountController.text) ?? 0;
  bool get _valid => _amount > 0 && _amount <= _maxAmount;

  Future<void> _submit() async {
    final wallet = ref.read(walletControllerProvider);
    if (!wallet.isConnected || !_valid || _submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      // 1. Backend debits the balance and returns a transaction already
      //    signed by the admin wallet.
      final prepared = await AuthService.instance.prepareWithdraw(
        kidunaAmount: _amount,
        recipientWallet: wallet.address!,
      );
      if (!mounted) return;

      final withdrawalId = prepared['withdrawalId'] as String?;
      final txBase64 = prepared['transaction'] as String?;

      if (withdrawalId == null || txBase64 == null) {
        setState(() {
          _error = 'Could not prepare the withdrawal. Please try again.';
          _submitting = false;
        });
        return;
      }

      // 2. The user signs as fee payer. Declining leaves the prepared row
      //    to expire on its own — the balance comes back automatically.
      final signed = await PhantomWallet.signTransaction(txBase64);
      if (!mounted) return;

      if (signed == null) {
        setState(() {
          _error = 'Signature declined. Your balance will be restored '
              'within a few minutes.';
          _submitting = false;
        });
        await ref.read(computeControllerProvider.notifier).refresh();
        return;
      }

      // 3. Backend broadcasts it — not the wallet, so it lands on the
      //    cluster this backend is pointed at.
      final result = await AuthService.instance.submitWithdraw(
        withdrawalId: withdrawalId,
        signedTransaction: signed,
      );
      if (!mounted) return;

      await ref.read(computeControllerProvider.notifier).refresh();
      if (!mounted) return;

      setState(() {
        _withdrawnAmount = _amount;
        _txSignature = result['txSignature'] as String?;
        _done = true;
        _submitting = false;
      });
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
      AppLogger.error('Withdraw failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. Check your balance before '
            'trying again.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    // Reload eligibility when the wallet connects or changes.
    ref.listen(walletControllerProvider, (prev, next) {
      if (prev?.address != next.address && next.isConnected) {
        _loadEligibility();
      }
    });

    return Scaffold(
      backgroundColor: colors.deep,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: _buildBody(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final colors = context.kiduna;

    if (_checkingAuth) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (!_isAuthenticated) return _buildSignInPrompt();
    if (_done) return _buildDone();

    final wallet = ref.watch(walletControllerProvider);
    final text = context.kidunaText;
    final compute = ref.watch(computeControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Withdraw KIDUNA', style: text.h4.copyWith(color: colors.gold)),
        const SizedBox(height: 6),
        Text(
          'Send KIDUNA to a wallet you control. You pay the network fee '
          'from that wallet.',
          style: text.body.copyWith(
            color: colors.muted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        _Row(
          label: 'Your Balance',
          value: '${KidunaPurchasePanel.formatKiduna(compute.balance)} KIDUNA',
          gold: true,
        ),

        const SizedBox(height: 20),

        if (!wallet.isAvailable)
          _Notice(
            icon: Icons.extension_outlined,
            title: 'Phantom wallet required',
            body: 'Install the Phantom browser extension, then reload this '
                'page to withdraw.',
          )
        else if (!wallet.isConnected)
          _Notice(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Connect your wallet',
            body: 'Use the Connect Wallet button in the header to choose '
                'where your KIDUNA should go.',
          )
        else ...[
          _Row(label: 'Sending to', value: wallet.shortAddress),
          const SizedBox(height: 4),
          _Row(
            label: 'Wallet SOL',
            value: '${_recipientSol.toStringAsFixed(4)} SOL',
            muted: true,
          ),
          const SizedBox(height: 18),

          if (_loadingEligibility)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_blockedReason != null)
            _Notice(
              icon: Icons.info_outline,
              title: 'Cannot withdraw right now',
              body: _blockedReason!,
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.deep.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: colors.camel.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style:
                          text.h2.copyWith(color: colors.text, fontSize: 28),
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
                  TextButton(
                    onPressed: () => _amountController.text =
                        _maxAmount.toStringAsFixed(0),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      foregroundColor: colors.sky,
                    ),
                    child: Text(
                      'MAX',
                      style: text.label.copyWith(
                        color: colors.sky,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    'KIDUNA',
                    style: text.body.copyWith(
                      color: colors.gold,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Row(
              label: 'Value',
              value: '\$${(_amount * _tokenPrice).toStringAsFixed(2)} USD',
              muted: true,
            ),
            const SizedBox(height: 6),
            Text(
              'Network fee is paid from your wallet in SOL.',
              style: text.caption.copyWith(color: colors.quiet, fontSize: 13),
            ),
          ],
        ],

        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.error.withValues(alpha: 0.3)),
            ),
            child: Text(
              _error!,
              style: text.caption.copyWith(
                color: colors.error,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],

        const SizedBox(height: 22),

        if (wallet.isConnected && _blockedReason == null)
          KidunaGoldButton(
            label: _submitting ? 'Processing...' : 'Withdraw',
            onPressed: _submitting || !_valid ? null : _submit,
          ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildDone() {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Column(
      mainAxisSize: MainAxisSize.min,
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
        Text('Withdrawal Sent', style: text.h4.copyWith(color: colors.gold)),
        const SizedBox(height: 10),
        Text(
          '${KidunaPurchasePanel.formatKiduna(_withdrawnAmount)} KIDUNA is on '
          'its way to your wallet.',
          textAlign: TextAlign.center,
          style: text.body.copyWith(
            color: colors.muted,
            fontSize: 15,
            height: 1.55,
          ),
        ),
        if (_txSignature != null) ...[
          const SizedBox(height: 14),
          SelectableText(
            _txSignature!,
            textAlign: TextAlign.center,
            style: text.micro.copyWith(color: colors.quiet),
          ),
        ],
        const SizedBox(height: 26),
        KidunaGoldButton(
          label: 'Done',
          onPressed: () {
            setState(() {
              _done = false;
              _amountController.clear();
            });
            _loadEligibility();
          },
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSignInPrompt() {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.gold.withValues(alpha: 0.1),
            border: Border.all(color: colors.gold.withValues(alpha: 0.3)),
          ),
          child: Icon(Icons.lock_outline, size: 30, color: colors.gold),
        ),
        const SizedBox(height: 22),
        Text(
          'Sign in to continue',
          style: text.h4.copyWith(color: colors.gold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Log in to your Kiduna account to withdraw KIDUNA.',
          style: text.body.copyWith(
            color: colors.muted,
            fontSize: 14,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        KidunaGoldButton(
          label: 'Log In',
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute<void>(
                builder: (_) => const LoginScreen(),
              ))
              .then((_) => _bootstrap()),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.muted = false,
    this.gold = false,
  });

  final String label;
  final String value;
  final bool muted;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: text.body.copyWith(
            color: muted ? colors.quiet : colors.muted,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: text.body.copyWith(
            color: gold ? colors.gold : colors.text,
            fontWeight: FontWeight.w700,
            fontSize: gold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.gold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.gold.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 26, color: colors.gold),
          const SizedBox(height: 10),
          Text(
            title,
            style: text.body.copyWith(
              color: colors.gold,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: text.caption.copyWith(
              color: colors.muted,
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
