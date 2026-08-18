import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/services/approval_service.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/field_controller.dart';
import 'capacity_header.dart';
import 'field_inputs.dart';

/// Approval panel with two forms:
/// Form 1: List of pending approvals with Approve/Reject
/// Form 2: Response editor for the selected approval
class ApprovalsPanel extends ConsumerStatefulWidget {
  const ApprovalsPanel({super.key});

  @override
  ConsumerState<ApprovalsPanel> createState() => _ApprovalsPanelState();
}

class _ApprovalsPanelState extends ConsumerState<ApprovalsPanel> {
  List<ApprovalModel> _approvals = [];
  bool _loading = true;
  ApprovalModel? _selected;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadApprovals);
  }

  Future<void> _loadApprovals() async {
    var wallet = ref.read(authControllerProvider).user?.wallet ?? '';
    if (wallet.isEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      wallet = ref.read(authControllerProvider).user?.wallet ?? '';
      if (wallet.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }
    }
    final result =
        await ApprovalService.instance.fetchPending(wallet: wallet);
    if (mounted) {
      setState(() {
        _approvals = result;
        _loading = false;
      });
    }
  }

  void _refreshCount() {
    ref.read(fieldControllerProvider.notifier).fetchPendingApprovalCount();
  }

  Future<void> _approve(ApprovalModel approval, String? editedText) async {
    final wallet = ref.read(authControllerProvider).user?.wallet ?? '';
    final success = await ApprovalService.instance.approve(
      approvalId: approval.id,
      wallet: wallet,
      editedAction: editedText,
    );
    if (success && mounted) {
      setState(() => _selected = null);
      await _loadApprovals();
      _refreshCount();
    }
  }

  Future<void> _reject(ApprovalModel approval) async {
    final wallet = ref.read(authControllerProvider).user?.wallet ?? '';
    final success = await ApprovalService.instance.reject(
      approvalId: approval.id,
      wallet: wallet,
    );
    if (success && mounted) {
      await _loadApprovals();
      _refreshCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selected != null) {
      return _ResponseForm(
        approval: _selected!,
        onBack: () => setState(() => _selected = null),
        onSend: (edited) => _approve(_selected!, edited),
      );
    }
    return _ApprovalList(
      approvals: _approvals,
      loading: _loading,
      onApprove: (a) {
        if (a.isSimpleAction) {
          _approve(a, null);
        } else {
          setState(() => _selected = a);
        }
      },
      onReject: _reject,
    );
  }
}

/// Form 1: List of pending approvals.
class _ApprovalList extends StatelessWidget {
  const _ApprovalList({
    required this.approvals,
    required this.loading,
    required this.onApprove,
    required this.onReject,
  });

  final List<ApprovalModel> approvals;
  final bool loading;
  final ValueChanged<ApprovalModel> onApprove;
  final ValueChanged<ApprovalModel> onReject;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CapacityHeader(
            eyebrow: 'Actions',
            heading: 'Pending Approvals',
            status: '${approvals.length} pending',
          ),
          const SizedBox(height: 14),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (approvals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 32, color: colors.muted),
                    const SizedBox(height: 8),
                    Text('No pending approvals',
                        style: text.caption.copyWith(color: colors.muted)),
                  ],
                ),
              ),
            )
          else
            ...List.generate(approvals.length, (i) {
              final a = approvals[i];
              return Padding(
                padding: EdgeInsets.only(
                    bottom: i < approvals.length - 1 ? 8 : 0),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.raised,
                    border: Border.all(
                        color: colors.camel.withValues(alpha: 0.14)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              a.skillName,
                              style: text.label.copyWith(
                                color: colors.cream,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.sky.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              a.triggerType,
                              style: text.micro.copyWith(
                                  color: colors.sky, fontSize: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a.summary,
                        style: text.caption.copyWith(
                            color: colors.muted, height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final confirmed = await ConfirmDialog.show(
                                context: context,
                                title: 'Reject Action',
                                message:
                                    'This will discard the pending action. This cannot be undone.',
                                confirmLabel: 'Reject',
                                isDestructive: true,
                              );
                              if (confirmed == true) {
                                onReject(a);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: const Color(0xFFEF4444)
                                        .withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(
                                    context.metrics.radiusMd),
                              ),
                              child: Text(
                                'Reject',
                                style: text.bodySmall.copyWith(
                                    color: const Color(0xFFEF4444),
                                    fontSize: 11),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FieldPrimaryButton(
                            label: 'Approve',
                            onPressed: () => onApprove(a),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// Form 2: Response editor for a single approval.
class _ResponseForm extends StatefulWidget {
  const _ResponseForm({
    required this.approval,
    required this.onBack,
    required this.onSend,
  });

  final ApprovalModel approval;
  final VoidCallback onBack;
  final ValueChanged<String?> onSend;

  @override
  State<_ResponseForm> createState() => _ResponseFormState();
}

class _ResponseFormState extends State<_ResponseForm> {
  late final TextEditingController _editCtrl;
  bool _executing = false;

  @override
  void initState() {
    super.initState();
    _editCtrl = TextEditingController(
      text: widget.approval.editedAction ??
          widget.approval.proposedAction,
    );
  }

  @override
  void dispose() {
    _editCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final a = widget.approval;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Back button ──
          GestureDetector(
            onTap: widget.onBack,
            child: Row(
              children: [
                Icon(Icons.arrow_back_ios, size: 12, color: colors.sky),
                const SizedBox(width: 4),
                Text(
                  'Back to list',
                  style: text.caption.copyWith(color: colors.sky),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          CapacityHeader(
            eyebrow: 'Review Response',
            heading: a.skillName,
            status: a.summary,
          ),
          const SizedBox(height: 14),

          // ── Ki's draft ──
          Text(
            "Ki's draft response",
            style: text.label.copyWith(color: colors.cream),
          ),
          const SizedBox(height: 2),
          Text(
            'Edit the response before sending',
            style:
                text.micro.copyWith(color: colors.quiet, fontSize: 9),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _editCtrl,
            maxLines: 5,
            style: text.caption.copyWith(
              color: colors.text,
              height: 1.4,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color.fromRGBO(6, 3, 4, 0.66),
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(
                    color: colors.camel.withValues(alpha: 0.24)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(
                    color: colors.camel.withValues(alpha: 0.24)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(color: colors.sky),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Actions ──
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _executing ? null : widget.onBack,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: colors.camel.withValues(alpha: 0.22)),
                    borderRadius:
                        BorderRadius.circular(context.metrics.radiusMd),
                  ),
                  child: Text(
                    'Cancel',
                    style: text.bodySmall
                        .copyWith(color: colors.muted, fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FieldPrimaryButton(
                label: _executing ? 'Sending...' : 'Approve & Send',
                onPressed: _executing
                    ? null
                    : () {
                        setState(() => _executing = true);
                        widget.onSend(_editCtrl.text.trim());
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }
}