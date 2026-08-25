import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/logger.dart';
import '../../../data/local/secure_storage.dart';
import '../../../data/services/auth_service.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/kiduna_gold_button.dart';
import '../../../shared/widgets/kiduna_message_box.dart';
import '../../auth/screens/login_screen.dart';
import '../controllers/compute_controller.dart';
import '../widgets/kiduna_purchase_panel.dart';
import '../widgets/purchase_success_panel.dart';

/// Standalone full-screen KIDUNA purchase page, reachable at /buy-kiduna.
///
/// Auth comes from the existing browser session (SecureStorage), never from
/// the URL — tokens in query strings leak into browser history, server logs,
/// and Referer headers. When there's no session the user is asked to sign in
/// first and is returned here afterwards.
class BuyKidunaScreen extends ConsumerStatefulWidget {
  const BuyKidunaScreen({super.key});

  @override
  ConsumerState<BuyKidunaScreen> createState() => _BuyKidunaScreenState();
}

class _BuyKidunaScreenState extends ConsumerState<BuyKidunaScreen> {
  bool _checkingAuth = true;
  bool _isAuthenticated = false;

  bool _isLoading = false;
  bool _waitingForPayment = false;
  bool _purchaseComplete = false;

  String? _stripeSessionId;
  String? _stripeUrl;

  double _balanceBefore = 0;
  double _kidunaReceived = 0;
  double _newBalance = 0;

  String? _message;
  MessageType _messageType = MessageType.error;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  /// Check for an existing session before showing the purchase UI.
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
    } else {
      AppLogger.info('Buy KIDUNA opened without a session', tag: 'BuyKiduna');
    }
  }

  void _goToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    ).then((_) => _bootstrap());
  }

  void _showMessage(String text, MessageType type) {
    _messageTimer?.cancel();
    setState(() {
      _message = text;
      _messageType = type;
    });
    _messageTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _message = null);
    });
  }

  void _onError(String text) => _showMessage(text, MessageType.error);

  // ── Purchase ────────────────────────────────────────────────────────────

  Future<void> _purchase(double usdcAmount) async {
    setState(() => _isLoading = true);
    _balanceBefore = ref.read(computeControllerProvider).balance;

    try {
      final result =
          await AuthService.instance.purchaseKiduna(usdcAmount: usdcAmount);
      if (!mounted) return;

      _stripeUrl = result['stripeUrl'] as String?;
      _stripeSessionId = result['stripeSessionId'] as String?;

      if (_stripeUrl != null && _stripeUrl!.isNotEmpty) {
        await launchUrl(
          Uri.parse(_stripeUrl!),
          mode: LaunchMode.externalApplication,
        );
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _waitingForPayment = true;
        });
        _showMessage(
          'Complete the payment, then click "I\'ve Paid — Verify".',
          MessageType.success,
        );
      } else {
        _onError('Failed to start purchase. Please try again.');
        setState(() => _isLoading = false);
      }
    } on UnauthorizedException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isAuthenticated = false;
      });
    } on ValidationException catch (e) {
      if (!mounted) return;
      _onError(e.message ?? 'Purchase failed.');
      setState(() => _isLoading = false);
    } on NetworkException {
      if (!mounted) return;
      _onError('No internet connection.');
      setState(() => _isLoading = false);
    } catch (e, st) {
      AppLogger.error('Purchase failed', error: e, stackTrace: st);
      if (!mounted) return;
      _onError('Something went wrong. Please try again.');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _retryPayment() async {
    if (_stripeUrl == null || _stripeUrl!.isEmpty) {
      _onError('No payment session found. Please start a new purchase.');
      return;
    }
    await launchUrl(
      Uri.parse(_stripeUrl!),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _verifyPayment() async {
    if (_stripeSessionId == null) {
      _onError('No payment session found.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.instance
          .verifyOnrampSession(sessionId: _stripeSessionId!);
      if (!mounted) return;

      await ref.read(computeControllerProvider.notifier).refresh();
      if (!mounted) return;

      final balanceNow = ref.read(computeControllerProvider).balance;

      if (balanceNow > _balanceBefore) {
        setState(() {
          _kidunaReceived = balanceNow - _balanceBefore;
          _newBalance = balanceNow;
          _waitingForPayment = false;
          _purchaseComplete = true;
          _isLoading = false;
        });
      } else {
        _showMessage(
          'Payment is being processed. Please wait a moment and try again.',
          MessageType.error,
        );
        setState(() => _isLoading = false);
      }
    } catch (e, st) {
      AppLogger.error('Verify failed', error: e, stackTrace: st);
      if (!mounted) return;
      _onError('Could not verify payment. Please try again.');
      setState(() => _isLoading = false);
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

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
    final text = context.kidunaText;

    if (_checkingAuth) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: CircularProgressIndicator(color: colors.gold, strokeWidth: 2),
        ),
      );
    }

    if (!_isAuthenticated) {
      return _buildSignInPrompt();
    }

    final compute = ref.watch(computeControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_purchaseComplete) ...[
          Text('Buy KIDUNA', style: text.h4.copyWith(color: colors.gold)),
          const SizedBox(height: 6),
          Text(
            'KIDUNA powers your AI chat compute. '
            'Pay with your card — we handle the conversion.',
            style: text.body.copyWith(
              color: colors.muted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
        ],

        if (_message != null) ...[
          KidunaMessageBox(message: _message!, type: _messageType),
          const SizedBox(height: 16),
        ],

        if (compute.isLoading && !_purchaseComplete)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child:
                  CircularProgressIndicator(color: colors.gold, strokeWidth: 2),
            ),
          )
        else if (_purchaseComplete)
          PurchaseSuccessPanel(
            kidunaReceived: _kidunaReceived,
            newBalance: _newBalance,
            onDone: () => Navigator.of(context).maybePop(),
          )
        else
          KidunaPurchasePanel(
            tokenPrice: compute.tokenPrice,
            currentBalance: compute.balance,
            onPurchase: _purchase,
            onError: _onError,
            onVerifyPayment: _verifyPayment,
            onRetryPayment: _retryPayment,
            isLoading: _isLoading,
            waitingForPayment: _waitingForPayment,
          ),

        const SizedBox(height: 40),
      ],
    );
  }

  /// Shown when the browser has no Kiduna session.
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
          'Log in to your Kiduna account to buy KIDUNA tokens. '
          'You will come back to this page once signed in.',
          style: text.body.copyWith(
            color: colors.muted,
            fontSize: 14,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        KidunaGoldButton(label: 'Log In', onPressed: _goToLogin),
        const SizedBox(height: 40),
      ],
    );
  }
}