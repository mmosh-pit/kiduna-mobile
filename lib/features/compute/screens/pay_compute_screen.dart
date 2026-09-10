import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../../data/local/secure_storage.dart';
import '../../../data/models/realm_model.dart';
import '../../../data/services/realm_service.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/kiduna_gold_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/screens/login_screen.dart';
import '../controllers/compute_controller.dart';
import '../open_buy_kiduna.dart';

/// Standalone full-screen Pay Compute page, reachable at /pay-compute.
///
/// Lets Catalyst/Mage/Sponsor buy KIDUNA and transfer compute to a realm
/// member. Auth comes from the existing browser session.
class PayComputeScreen extends ConsumerStatefulWidget {
  const PayComputeScreen({super.key, required this.realmId});

  final String? realmId;

  @override
  ConsumerState<PayComputeScreen> createState() => _PayComputeScreenState();
}

class _PayComputeScreenState extends ConsumerState<PayComputeScreen> {
  bool _checkingAuth = true;
  bool _isAuthenticated = false;

  List<RealmMemberModel> _members = [];
  bool _loadingMembers = true;
  String? _error;

  RealmMemberModel? _selectedMember;
  final _amountController = TextEditingController();
  bool _transferring = false;
  String? _transferResult;
  bool _transferIsError = false;

  @override
  void initState() {
    super.initState();
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
      await _loadMembers();
    }
  }

  Future<void> _loadMembers() async {
    if (widget.realmId == null) {
      setState(() {
        _loadingMembers = false;
        _error = 'No realm selected.';
      });
      return;
    }

    try {
      final realm =
          await RealmService.instance.fetchRealmById(widget.realmId!);
      final myWallet = ref.read(authControllerProvider).user?.wallet;
      if (!mounted) return;
      setState(() {
        _members =
            realm.members.where((m) => m.wallet != myWallet).toList();
        _loadingMembers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load members.';
        _loadingMembers = false;
      });
    }
  }

  Future<void> _buyKiduna() async {
    await openBuyKidunaPage(context);
    if (!mounted) return;
    ref.read(computeControllerProvider.notifier).refresh();
  }

  Future<void> _transfer() async {
    if (_selectedMember == null) {
      setState(() {
        _transferResult = 'Please select a member.';
        _transferIsError = true;
      });
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() {
        _transferResult = 'Enter a valid amount.';
        _transferIsError = true;
      });
      return;
    }

    setState(() {
      _transferring = true;
      _transferResult = null;
    });

    try {
      final response =
          await ApiClient.instance.authDio.post<Map<String, dynamic>>(
        '/kiduna/transfer',
        data: {
          'recipientWallet': _selectedMember!.wallet,
          'amount': amount,
          'realmId': widget.realmId,
        },
      );

      if (!mounted) return;

      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data?['success'] == true) {
        setState(() {
          _transferResult =
              'Transferred ${amount.toStringAsFixed(0)} KIDUNA to ${_selectedMember!.label}';
          _transferIsError = false;
          _amountController.clear();
          _selectedMember = null;
        });
        ref.read(computeControllerProvider.notifier).refresh();
      } else {
        setState(() {
          _transferResult = 'Transfer failed.';
          _transferIsError = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      AppLogger.error('Transfer failed', tag: 'PayCompute', error: e);
      String msg = 'Transfer failed.';
      try {
        final errData = (e as dynamic).response?.data;
        if (errData is Map && errData['error'] is String) {
          msg = errData['error'] as String;
        }
      } catch (_) {}
      setState(() {
        _transferResult = msg;
        _transferIsError = true;
      });
    } finally {
      if (mounted) setState(() => _transferring = false);
    }
  }

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
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
            child: CircularProgressIndicator(
                strokeWidth: 2, color: colors.gold)),
      );
    }

    if (!_isAuthenticated) {
      return Column(
        children: [
          const SizedBox(height: 40),
          Text(
            'Sign in to pay compute',
            style: text.heading.copyWith(color: colors.cream),
          ),
          const SizedBox(height: 16),
          Text(
            'You need to be signed in to transfer KIDUNA to realm members.',
            style: text.bodySmall.copyWith(color: colors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          KidunaGoldButton(
            label: 'Sign In',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
              _bootstrap();
            },
          ),
        ],
      );
    }

    if (_loadingMembers) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
            child: CircularProgressIndicator(
                strokeWidth: 2, color: colors.gold)),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(_error!,
            style: text.bodySmall.copyWith(color: colors.muted),
            textAlign: TextAlign.center),
      );
    }

    final compute = ref.watch(computeControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Title ──
        Text(
          'Pay Compute',
          style: text.heading.copyWith(color: colors.cream),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Transfer KIDUNA to a realm member',
          style: text.bodySmall.copyWith(color: colors.muted),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 28),

        // ── Your Balance ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.gold.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: colors.gold.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet,
                  size: 20, color: colors.gold),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Balance',
                      style:
                          text.eyebrowSmall.copyWith(color: colors.muted)),
                  const SizedBox(height: 2),
                  Text(
                    '${compute.balance.toStringAsFixed(0)} KIDUNA',
                    style: text.h4.copyWith(color: colors.gold),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: _buyKiduna,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: colors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Text('Buy More',
                      style: text.label.copyWith(
                          color: colors.gold, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ── Select Member ──
        Text('SEND COMPUTE TO',
            style: text.eyebrowSmall.copyWith(color: colors.muted)),
        const SizedBox(height: 8),

        if (_members.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('No other members in this realm.',
                style: text.bodySmall.copyWith(color: colors.muted),
                textAlign: TextAlign.center),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: colors.camel.withValues(alpha: 0.2)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMember?.wallet,
                hint: Text('Select a member',
                    style:
                        text.bodySmall.copyWith(color: colors.muted)),
                isExpanded: true,
                dropdownColor: colors.surface,
                icon: Icon(Icons.arrow_drop_down, color: colors.muted),
                style: text.bodySmall.copyWith(color: colors.cream),
                items: _members.map((m) {
                  return DropdownMenuItem(
                    value: m.wallet,
                    child: Text(
                      '${m.label} (${m.role})',
                      style: text.bodySmall
                          .copyWith(color: colors.cream),
                    ),
                  );
                }).toList(),
                onChanged: (wallet) {
                  setState(() {
                    _selectedMember =
                        _members.firstWhere((m) => m.wallet == wallet);
                  });
                },
              ),
            ),
          ),

        const SizedBox(height: 20),

        // ── Amount ──
        Text('AMOUNT (KIDUNA)',
            style: text.eyebrowSmall.copyWith(color: colors.muted)),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: text.bodySmall.copyWith(color: colors.cream),
          decoration: InputDecoration(
            hintText: 'e.g. 10000',
            hintStyle: text.bodySmall.copyWith(color: colors.quiet),
            filled: true,
            fillColor: colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: colors.camel.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color: colors.camel.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.gold),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ── Transfer Button ──
        KidunaGoldButton(
          label: 'Transfer Compute',
          isLoading: _transferring,
          onPressed: _transferring ? null : _transfer,
        ),

        // ── Result message ──
        if (_transferResult != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (_transferIsError
                      ? Colors.red
                      : Colors.green)
                  .withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (_transferIsError
                        ? Colors.red
                        : Colors.green)
                    .withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              _transferResult!,
              style: text.bodySmall.copyWith(
                color: _transferIsError
                    ? Colors.red.shade300
                    : Colors.green.shade300,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}
