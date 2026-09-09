import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../controllers/alliance_controller.dart';

const _kNoVoteRoles = {'guest'};

/// Displays on-chain proposals with approve/reject/execute actions.
class ProposalList extends ConsumerWidget {
  const ProposalList({super.key, required this.realmId, this.userRole});

  final String realmId;
  final String? userRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final state = ref.watch(allianceControllerProvider);

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

    final canVote = userRole != null && !_kNoVoteRoles.contains(userRole);

    return Column(
      children: state.proposals.map((p) {
        return _ProposalCard(
          proposal: p,
          realmId: realmId,
          canVote: canVote,
        );
      }).toList(),
    );
  }
}

class _ProposalCard extends ConsumerStatefulWidget {
  const _ProposalCard({
    required this.proposal,
    required this.realmId,
    required this.canVote,
  });

  final Map<String, dynamic> proposal;
  final String realmId;
  final bool canVote;

  @override
  ConsumerState<_ProposalCard> createState() => _ProposalCardState();
}

class _ProposalCardState extends ConsumerState<_ProposalCard> {
  bool _actionLoading = false;
  String? _actionError;

  Future<void> _confirmAndRun({
    required String title,
    required String message,
    required Future<String?> Function() action,
  }) async {
    final colors = context.kiduna;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(title, style: TextStyle(color: colors.cream)),
        content: Text(message, style: TextStyle(color: colors.quiet)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: colors.quiet)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Confirm', style: TextStyle(color: colors.gold)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() { _actionLoading = true; _actionError = null; });
    final error = await action();
    if (!mounted) return;
    setState(() {
      _actionLoading = false;
      _actionError = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final ctrl = ref.read(allianceControllerProvider.notifier);

    final status = widget.proposal['status']?.toString() ?? 'unknown';
    final txIndex = widget.proposal['transactionIndex']?.toString() ?? '';
    final approvals = widget.proposal['approvals'] as int? ?? 0;
    final rejections = widget.proposal['rejections'] as int? ?? 0;
    final threshold = widget.proposal['threshold'] as int? ?? 1;
    final memo = widget.proposal['memo']?.toString() ?? 'Proposal #$txIndex';
    final proposalType = widget.proposal['type']?.toString();
    final explorerUrl = widget.proposal['explorerUrl']?.toString();
    final isCancelled = status == 'Cancelled' || status == 'Rejected';

    final isExecuted = status == 'Executed';
    final isApproved = !isExecuted && !isCancelled && (status == 'Approved' || approvals >= threshold);
    final isPending = !isApproved && !isExecuted && !isCancelled;

    final statusColor = isExecuted
        ? colors.sky
        : isCancelled
            ? const Color(0xFFE57373)
            : isApproved
                ? colors.gold
                : colors.quiet;

    final statusLabel = isExecuted
        ? 'Executed'
        : isCancelled
            ? 'Cancelled'
            : isApproved
                ? 'Ready to Execute'
                : 'Pending';

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
          Row(
            children: [
              if (proposalType != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.sky.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    proposalType,
                    style: text.body.copyWith(color: colors.sky, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  memo,
                  style: text.bodyBase.copyWith(
                    color: colors.cream,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

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
                  statusLabel,
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
              if (rejections > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '$rejections rejected',
                  style: text.bodySm.copyWith(color: const Color(0xFFE57373)),
                ),
              ],
            ],
          ),

          if (_actionError != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE57373).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Text(
                _actionError!,
                style: text.bodySm.copyWith(color: const Color(0xFFE57373)),
              ),
            ),
          ],

          if (isExecuted && explorerUrl != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.open_in_new, size: 14, color: colors.sky),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'View on Solana Explorer',
                    style: text.bodySm.copyWith(color: colors.sky),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          if (!isExecuted && !isCancelled && widget.canVote) ...[
            const SizedBox(height: 12),
            if (_actionLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colors.gold),
                  ),
                ),
              )
            else
              Row(
                children: [
                  if (isPending) ...[
                    _ActionBtn(
                      label: 'Approve',
                      color: colors.gold,
                      onTap: () => _confirmAndRun(
                        title: 'Approve Proposal',
                        message: 'Are you sure you want to approve this proposal?',
                        action: () => ctrl.approveProposal(widget.realmId, txIndex),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ActionBtn(
                      label: 'Reject',
                      color: const Color(0xFFE57373),
                      onTap: () => _confirmAndRun(
                        title: 'Reject Proposal',
                        message: 'Are you sure you want to reject this proposal?',
                        action: () => ctrl.rejectProposal(widget.realmId, txIndex),
                      ),
                    ),
                  ],
                  if (isApproved) ...[
                    _ActionBtn(
                      label: 'Execute',
                      color: colors.sky,
                      onTap: () => _confirmAndRun(
                        title: 'Execute Proposal',
                        message: 'This will execute the proposal on-chain. Continue?',
                        action: () => ctrl.executeProposal(widget.realmId, txIndex),
                      ),
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
