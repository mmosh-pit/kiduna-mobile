import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/prompt_model.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../controllers/ally_controller.dart';
import '../controllers/presence_controller.dart';
import 'capacity_header.dart';
import 'field_inputs.dart';

/// Presence listing panel — shows all prompts linked to Ki.
/// Tap Edit → opens detail panel. Same pattern as WisdomPanel.
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
        () => ref.read(presenceControllerProvider.notifier).loadPrompts(),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PresenceController ctrl,
    PromptModel prompt,
  ) async {
    final l10n = context.l10n;
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: l10n.promptDeleteTitle,
      message: l10n.promptDeleteConfirm(prompt.name),
    );
    if (confirmed == true && context.mounted) {
      await ctrl.deletePrompt(prompt.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pState = ref.watch(presenceControllerProvider);
    final ctrl = ref.read(presenceControllerProvider.notifier);
    final allyState = ref.watch(allyControllerProvider);
    final activePromptId = allyState.ally?.promptId ?? '';

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
            heading: l10n.promptHowRealmBehaves(widget.realmName),
            status: pState.isLoading
                ? l10n.promptLoading
                : l10n.promptCountStatus(pState.prompts.length),
          ),
          const SizedBox(height: 16),

          // Error row.
          if (pState.error != null) ...[
            _ErrorRow(message: pState.error!),
            const SizedBox(height: 8),
          ],

          // Empty state.
          if (pState.prompts.isEmpty && !pState.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                l10n.promptNoPrompts,
                style: text.caption.copyWith(color: colors.quiet),
                textAlign: TextAlign.center,
              ),
            ),

          // Prompt rows.
          ...pState.prompts.map((prompt) {
            final isActive = prompt.id == activePromptId;
            return _PromptRow(
              prompt: prompt,
              isActive: isActive,
              onEdit: () => ctrl.openDetail(prompt.id),
              onDelete: () => _confirmDelete(context, ctrl, prompt),
            );
          }),

          const SizedBox(height: 12),

          // Create button.
          FieldPrimaryButton(
            label: l10n.promptCreateNew,
            onPressed: ctrl.openCreate,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PromptRow extends StatelessWidget {
  const _PromptRow({
    required this.prompt,
    required this.isActive,
    required this.onEdit,
    required this.onDelete,
  });

  final PromptModel prompt;
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? colors.sky.withValues(alpha: 0.06)
              : const Color.fromRGBO(6, 3, 4, 0.36),
          border: Border.all(
            color: isActive
                ? colors.sky.withValues(alpha: 0.3)
                : colors.camel.withValues(alpha: 0.14),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.description_outlined,
              size: 16,
              color: isActive ? colors.sky : colors.quiet,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prompt.name,
                    style: text.caption.copyWith(color: colors.cream),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isActive)
                    Text(
                      l10n.promptActive,
                      style: text.micro.copyWith(color: colors.sky),
                    ),
                ],
              ),
            ),
            CapacityActionButton(
              label: l10n.promptEdit,
              onPressed: onEdit,
            ),
            const SizedBox(width: 4),
            CapacityActionButton(
              label: l10n.promptDelete,
              onPressed: onDelete,
            ),
          ],
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