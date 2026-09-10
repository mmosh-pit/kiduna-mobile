import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../field/widgets/field_inputs.dart';
import '../controllers/alliance_controller.dart';

const _kTypes = [
  'Send USDC',
  'Send SOL',
  'Add Wallet Signer',
  'Remove Wallet Signer',
  'Change Threshold',
];

final _kBase58 = RegExp(r'^[1-9A-HJ-NP-Za-km-z]{32,44}$');

/// Form to create a new proposal — shown inside a FieldPanel.
class ProposalForm extends ConsumerStatefulWidget {
  const ProposalForm({super.key, required this.realmId});

  final String realmId;

  @override
  ConsumerState<ProposalForm> createState() => _ProposalFormState();
}

class _ProposalFormState extends ConsumerState<ProposalForm> {
  final _wallet = TextEditingController();
  final _amount = TextEditingController();
  final _threshold = TextEditingController();
  final _reason = TextEditingController();
  String _type = 'Send USDC';
  bool _submitting = false;
  String? _msg;
  bool _isError = false;

  bool get _isTransfer => _type == 'Send USDC' || _type == 'Send SOL';
  bool get _isMember => _type == 'Add Wallet Signer' || _type == 'Remove Wallet Signer';
  bool get _isThreshold => _type == 'Change Threshold';

  @override
  void dispose() {
    _wallet.dispose();
    _amount.dispose();
    _threshold.dispose();
    _reason.dispose();
    super.dispose();
  }

  bool _validateWallet(String wallet) {
    if (wallet.isEmpty) {
      setState(() { _msg = 'Wallet address is required.'; _isError = true; });
      return false;
    }
    if (!_kBase58.hasMatch(wallet)) {
      setState(() { _msg = 'Invalid Solana wallet address.'; _isError = true; });
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    setState(() { _msg = null; _isError = false; });

    if (_isMember) {
      final wallet = _wallet.text.trim();
      if (!_validateWallet(wallet)) return;
      setState(() => _submitting = true);
      final error = await ref.read(allianceControllerProvider.notifier).memberProposal(
        realmId: widget.realmId,
        wallet: wallet,
        isAdd: _type == 'Add Wallet Signer',
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _msg = error ?? 'Proposal created!';
        _isError = error != null;
        if (error == null) { _wallet.clear(); }
      });
    } else if (_isThreshold) {
      final val = int.tryParse(_threshold.text.trim());
      if (val == null || val < 1) {
        setState(() { _msg = 'Enter a valid threshold (minimum 1).'; _isError = true; });
        return;
      }
      setState(() => _submitting = true);
      final error = await ref.read(allianceControllerProvider.notifier).changeThresholdProposal(
        realmId: widget.realmId,
        newThreshold: val,
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _msg = error ?? 'Proposal created!';
        _isError = error != null;
        if (error == null) { _threshold.clear(); }
      });
    } else {
      final to = _wallet.text.trim();
      if (!_validateWallet(to)) return;
      final amountText = _amount.text.trim();
      final amount = double.tryParse(amountText);
      if (amount == null || amount <= 0) {
        setState(() { _msg = 'Enter a valid amount greater than zero.'; _isError = true; });
        return;
      }
      setState(() => _submitting = true);
      final error = await ref.read(allianceControllerProvider.notifier).createTransferProposal(
        realmId: widget.realmId,
        to: to,
        amount: amount,
        isSol: _type == 'Send SOL',
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _msg = error ?? 'Proposal created!';
        _isError = error != null;
        if (error == null) { _wallet.clear(); _amount.clear(); _reason.clear(); }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Create a proposal for signers to approve.',
            style: text.bodySm.copyWith(color: colors.quiet),
          ),
          const SizedBox(height: 16),
          FieldDropdown(
            label: 'Proposal Type',
            value: _type,
            options: _kTypes,
            onChanged: (v) => setState(() { _type = v; _msg = null; }),
          ),
          const SizedBox(height: 12),

          // ── Transfer fields ──
          if (_isTransfer) ...[
            FieldTextInput(
              label: 'Recipient Wallet',
              controller: _wallet,
              hint: 'Solana wallet address',
            ),
            const SizedBox(height: 12),
            FieldTextInput(
              label: 'Amount',
              controller: _amount,
              hint: _type == 'Send SOL' ? '0.5' : '100.00',
            ),
            const SizedBox(height: 12),
            FieldTextInput(
              label: 'Reason (optional)',
              controller: _reason,
              hint: 'e.g. Tournament prize',
            ),
          ],

          // ── Member fields ──
          if (_isMember) ...[
            FieldTextInput(
              label: _type == 'Add Wallet Signer' ? 'New Signer Wallet' : 'Signer to Remove',
              controller: _wallet,
              hint: 'Solana wallet address',
            ),
          ],

          // ── Threshold fields ──
          if (_isThreshold) ...[
            FieldTextInput(
              label: 'New Threshold',
              controller: _threshold,
              hint: 'e.g. 2 (means 2-of-N must approve)',
            ),
          ],

          const SizedBox(height: 16),
          if (_msg != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (_isError ? const Color(0xFFE57373) : colors.gold).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(_msg!, style: text.bodySm.copyWith(color: _isError ? const Color(0xFFE57373) : colors.gold)),
            ),
            const SizedBox(height: 12),
          ],
          FieldPrimaryButton(
            label: _submitting ? 'Submitting...' : 'Submit Proposal',
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
