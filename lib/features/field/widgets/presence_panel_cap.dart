import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/instruct_model.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../controllers/ally_controller.dart';
import '../controllers/presence_controller.dart';
import 'capacity_header.dart';
import 'field_inputs.dart';

/// Presence listing panel — shows all instructs linked to Ki.
class PresenceCapacityPanel extends ConsumerStatefulWidget {
  const PresenceCapacityPanel({super.key, required this.realmName});

  final String realmName;

  @override
  ConsumerState<PresenceCapacityPanel> createState() =>
      _PresenceCapacityPanelState();
}

class _PresenceCapacityPanelState
    extends ConsumerState<PresenceCapacityPanel> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      Future.microtask(
        () => ref.read(presenceControllerProvider.notifier).loadInstructs(),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PresenceController ctrl,
    InstructModel instruct,
  ) async {
    final l10n = context.l10n;
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: l10n.instructDeleteTitle,
      message: l10n.instructDeleteConfirm(instruct.name),
    );
    if (confirmed == true && context.mounted) {
      await ctrl.deleteInstruct(instruct.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pState = ref.watch(presenceControllerProvider);
    final ctrl = ref.read(presenceControllerProvider.notifier);
    final allyState = ref.watch(allyControllerProvider);
    final activeInstructId = allyState.ally?.promptId ?? '';

    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CapacityHeader(
            eyebrow: l10n.presence,
            heading: l10n.instructHowRealmBehaves(widget.realmName),
            status: pState.isLoading
                ? l10n.instructLoading
                : l10n.instructCountStatus(pState.instructs.length),
          ),
          const SizedBox(height: 16),

          // Error row.
          if (pState.error != null) ...[
            _ErrorRow(message: pState.error!),
            const SizedBox(height: 8),
          ],

          // Empty state.
          if (pState.instructs.isEmpty && !pState.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                l10n.instructNoInstructs,
                style: text.caption.copyWith(color: colors.quiet),
                textAlign: TextAlign.center,
              ),
            ),

          // Instruct rows.
          ...pState.instructs.map((instruct) {
            final isActive = instruct.id == activeInstructId;
            return _InstructRow(
              instruct: instruct,
              isActive: isActive,
              onEdit: () => ctrl.openDetail(instruct.id),
              onDelete: () => _confirmDelete(context, ctrl, instruct),
            );
          }),

          const SizedBox(height: 12),

          // Create button.
          FieldPrimaryButton(
            label: l10n.instructCreateNew,
            onPressed: ctrl.openCreate,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _InstructRow extends StatelessWidget {
  const _InstructRow({
    required this.instruct,
    required this.isActive,
    required this.onEdit,
    required this.onDelete,
  });

  final InstructModel instruct;
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onEdit,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(6, 3, 4, 0.36),
              border: Border.all(
                color: isActive
                    ? colors.sky.withValues(alpha: 0.3)
                    : colors.sky.withValues(alpha: 0.18),
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colors.sky.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.description_outlined,
                    size: 16,
                    color: colors.sky,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instruct.name,
                        style: text.label.copyWith(
                          color: colors.cream,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isActive
                            ? l10n.instructActive
                            : instruct.goal ?? '',
                        style: text.micro.copyWith(
                          color: isActive ? colors.sky : colors.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CapacityActionButton(
                  label: l10n.instructEdit,
                  onPressed: onEdit,
                ),
                const SizedBox(width: 4),
                CapacityActionButton(
                  label: l10n.instructDelete,
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final text = context.kidunaText;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(227, 72, 72, 0.08),
        border: Border.all(color: const Color.fromRGBO(227, 72, 72, 0.4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            size: 16,
            color: Color(0xFFE34848),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: text.caption.copyWith(color: const Color(0xFFE34848)),
            ),
          ),
        ],
      ),
    );
  }
}