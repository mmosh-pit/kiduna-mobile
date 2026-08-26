import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/knowledge_base_model.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../controllers/ally_controller.dart';
import '../controllers/knowledge_controller.dart';
import 'capacity_header.dart';
import 'field_inputs.dart';

/// Wisdom capacity workspace — KB listing only.
///
/// Detail view (edit, upload, Drive import) opens as a separate
/// [FieldPanel] via [KbDetailPanel].
class WisdomPanel extends ConsumerStatefulWidget {
  const WisdomPanel({super.key, required this.realmName});

  final String realmName;

  @override
  ConsumerState<WisdomPanel> createState() => _WisdomPanelState();
}

class _WisdomPanelState extends ConsumerState<WisdomPanel> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      ref.read(knowledgeControllerProvider.notifier).loadKnowledgeBases,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kbState = ref.watch(knowledgeControllerProvider);
    final ctrl = ref.read(knowledgeControllerProvider.notifier);
    final kbs = kbState.knowledgeBases;

    // Reload KBs when ally loads (fixes first-open empty state)
    ref.listen(allyControllerProvider, (prev, next) {
      final prevIds = prev?.ally?.knowledgeBaseIds ?? [];
      final nextIds = next.ally?.knowledgeBaseIds ?? [];
      if (prevIds.length != nextIds.length) {
        ctrl.loadKnowledgeBases();
      }
    });

    return Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CapacityHeader(
            eyebrow: l10n.wisdom,
            heading: l10n.whatRealmMayKnow(widget.realmName),
            status: '${kbs.length} knowledge bases',
          ),
          const SizedBox(height: 14),

          // Loading.
          if (kbState.isLoading && kbs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF03CCD9),
                  ),
                ),
              ),
            ),

          // Error.
          if (kbState.error != null) ...[
            _ErrorRow(
              message: kbState.error!,
              onRetry: ctrl.loadKnowledgeBases,
            ),
            const SizedBox(height: 7),
          ],

          // Empty.
          if (!kbState.isLoading && kbs.isEmpty && kbState.error == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                l10n.noWisdomItems,
                style: context.kidunaText.caption.copyWith(
                  color: context.kiduna.muted,
                ),
              ),
            ),

          // KB list.
          for (final kb in kbs) ...[
            _KbRow(
              kb: kb,
              onEdit: () => ctrl.openKbDetail(kb.id),
              onDelete: () => _confirmDelete(context, ctrl, kb),
            ),
            const SizedBox(height: 6),
          ],

          const SizedBox(height: 14),
          FieldPrimaryButton(
            label: l10n.createKnowledgeBase,
            onPressed: kbState.isLoading ? null : ctrl.openCreateKbForm,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    KnowledgeController ctrl,
    KnowledgeBaseModel kb,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Delete Knowledge Base',
      message:
          'Delete "${kb.name}" and all its sources? '
          'This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed == true) {
      unawaited(ctrl.unlinkAndDeleteKb(kb.id));
    }
  }
}

class _KbRow extends StatelessWidget {
  const _KbRow({
    required this.kb,
    required this.onEdit,
    required this.onDelete,
  });

  final KnowledgeBaseModel kb;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final itemCount = kb.items.length;
    final privacy = kb.privacy;

    return GestureDetector(
      onTap: onEdit,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(6, 3, 4, 0.36),
            border: Border.all(color: colors.sky.withValues(alpha: 0.18)),
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
                child: Icon(Icons.auto_stories, size: 16, color: colors.sky),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kb.name,
                      style: text.label.copyWith(
                        color: colors.cream,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$itemCount sources · $privacy',
                      style: text.micro.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              CapacityActionButton(label: 'Edit', onPressed: onEdit),
              const SizedBox(width: 4),
              CapacityActionButton(label: 'Delete', onPressed: onDelete),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(6, 3, 4, 0.36),
        border: Border.all(color: colors.camel.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: text.caption.copyWith(color: colors.cream),
            ),
          ),
          const SizedBox(width: 8),
          CapacityActionButton(label: context.l10n.retry, onPressed: onRetry),
        ],
      ),
    );
  }
}
