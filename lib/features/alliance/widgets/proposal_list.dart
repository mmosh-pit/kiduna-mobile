import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../controllers/alliance_controller.dart';
/// Displays on-chain proposals with approve/reject/execute actions.
class ProposalList extends ConsumerWidget {
  const ProposalList({super.key, required this.realmId});

  final String realmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final state = ref.watch(allianceControllerProvider);
    final ctrl = ref.read(allianceControllerProvider.notifier);

    if (state.proposalsLoading) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2.0, color: colors.gold),
        ),
      );
    }

    if (state.proposals.isEmpty) {
      return Text(
        'No proposals yet.',
        style: text.bodySm.copyWith(color: colors.quiet),
      );
    }

    return Column(
      children: state.proposals.map((p) {
        return _ProposalCard(
          proposal: p,
          realmId: realmId,
          onApprove: () => ctrl.approveProposal(
            realmId,
            p['transactionIndex']?.toString() ?? '',
          ),
          onReject: () => ctrl.rejectProposal(
            realmId,
            p['transactionIndex']?.toString() ?? '',
          ),
          onExecute: () => ctrl.executeProposal(
            realmId,
            p['transactionIndex']?.toString() ?? '',
          ),
        );
      }).toList(),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.proposal,
    required this.realmId,
    required this.onApprove,
    required this.onReject,
    required this.onExecute,
  });

  final Map<String, dynamic> proposal;
  final String realmId;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onExecute;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    final status = proposal['status']?.toString() ?? 'unknown';
    final txIndex = proposal['transactionIndex']?.toString() ?? '';
    final approvals = proposal['approvals'] as int? ?? 0;
    final threshold = proposal['threshold'] as int? ?? 1;
    final memo = proposal['memo']?.toString() ?? 'Proposal #$txIndex';

    final isApproved = status == 'Approved' || approvals >= threshold;
    final isExecuted = status == 'Executed';
    final isPending = !isApproved && !isExecuted;

    final statusColor = isExecuted
        ? colors.sky
        : isApproved
            ? colors.gold
            : colors.quiet;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: colors.camel.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Memo / description
          Text(
            memo,
            style: text.bodyBase.copyWith(
              color: colors.cream,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),

          // Status row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  isExecuted
                      ? 'Executed'
                      : isApproved
                          ? 'Ready to Execute'
                          : 'Pending',
                  style: text.body.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$approvals / $threshold approved',
                style: text.bodySm.copyWith(color: colors.quiet),
              ),
            ],
          ),

          // Action buttons
          if (!isExecuted) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (isPending) ...[
                  _ActionBtn(
                    label: 'Approve',
                    color: colors.gold,
                    onTap: onApprove,
                  ),
                  const SizedBox(width: 8),
                  _ActionBtn(
                    label: 'Reject',
                    color: const Color(0xFFE57373),
                    onTap: onReject,
                  ),
                ],
                if (isApproved) ...[
                  _ActionBtn(
                    label: 'Execute',
                    color: colors.sky,
                    onTap: onExecute,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: context.kidunaText.body.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
