import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../field/widgets/field_inputs.dart';

/// Deposit form — shown inside a FieldPanel.
/// Note: Deposit is a direct SPL transfer (user → vault), not a proposal.
/// This requires wallet signing. Until wallet adapter is ready, shows info.
class DepositForm extends ConsumerStatefulWidget {
  const DepositForm({super.key, required this.realmId, this.vaultPda});

  final String realmId;
  final String? vaultPda;

  @override
  ConsumerState<DepositForm> createState() => _DepositFormState();
}

class _DepositFormState extends ConsumerState<DepositForm> {
  final _amount = TextEditingController();
  String _token = 'USDC';
  String? _msg;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    if (widget.vaultPda == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Wallet not configured yet. Create the alliance with wallet enabled first.',
          style: text.bodySm.copyWith(color: colors.quiet),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Deposit funds into the shared wallet.',
            style: text.bodySm.copyWith(color: colors.quiet),
          ),
          const SizedBox(height: 16),
          FieldDropdown(
            label: 'Token',
            value: _token,
            options: const ['USDC', 'SOL'],
            onChanged: (v) => setState(() => _token = v),
          ),
          const SizedBox(height: 12),
          FieldTextInput(
            label: 'Amount',
            controller: _amount,
            hint: _token == 'SOL' ? '0.5' : '50.00',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.gold.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: colors.gold.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16.0, color: colors.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vault: ${widget.vaultPda!.substring(0, 16)}...',
                    style: text.bodySm.copyWith(color: colors.quiet),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_msg != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                _msg!,
                style: text.bodySm.copyWith(color: colors.gold),
              ),
            ),
            const SizedBox(height: 12),
          ],
          FieldPrimaryButton(
            label: 'Deposit $_token',
            onPressed: () {
              setState(() {
                _msg = 'Deposit requires wallet signing. '
                    'This feature will be available once wallet integration is complete.';
              });
            },
          ),
        ],
      ),
    );
  }
}
