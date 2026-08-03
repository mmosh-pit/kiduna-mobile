import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/knowledge_base_model.dart';
import '../../../l10n/app_localizations.dart';
import '../controllers/knowledge_controller.dart';
import 'capacity_header.dart';
import 'drive_import_panel.dart';
import 'field_inputs.dart';

/// Wisdom capacity workspace — knowledge base items, upload zone,
/// create/delete KB, and "Create new Wisdom with Ki" action.
///
/// Watches [knowledgeControllerProvider] for real data from the API.
class WisdomPanel extends ConsumerStatefulWidget {
  const WisdomPanel({super.key, required this.realmName});

  final String realmName;

  @override
  ConsumerState<WisdomPanel> createState() => _WisdomPanelState();
}

class _WisdomPanelState extends ConsumerState<WisdomPanel> {
  final TextEditingController _kbNameCtrl = TextEditingController();
  bool _showCreateForm = false;

  @override
  void initState() {
    super.initState();
    final ctrl = ref.read(knowledgeControllerProvider.notifier);
    Future.microtask(ctrl.loadKnowledgeBases);
  }

  @override
  void dispose() {
    _kbNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kbState = ref.watch(knowledgeControllerProvider);
    final activeKb = kbState.activeKb;
    final items = activeKb?.items ?? const [];
    final hasKbs = kbState.knowledgeBases.isNotEmpty;

    final status = _statusText(kbState, l10n);

    return Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CapacityHeader(
            eyebrow: l10n.wisdom,
            heading: l10n.whatRealmMayKnow(widget.realmName),
            status: status,
          ),
          const SizedBox(height: 14),

          // Loading state.
          if (kbState.isLoading && items.isEmpty && !_showCreateForm)
            _LoadingIndicator(label: l10n.kbLoading),

          // Error state.
          if (kbState.error != null) ...[
            _ErrorRow(
              message: kbState.error!,
              onRetry: () => ref
                  .read(knowledgeControllerProvider.notifier)
                  .loadKnowledgeBases(),
            ),
            const SizedBox(height: 7),
          ],

          // Active KB header with delete option.
          if (activeKb != null) ...[
            _KbHeader(
              kbName: activeKb.name,
              onDelete: () => _confirmDeleteKb(context, activeKb.id),
            ),
            const SizedBox(height: 7),
          ],

          // Visibility selector.
          _KbPrivacySelector(hasActiveKb: activeKb != null),
          const SizedBox(height: 7),

          // Empty state — no KBs exist yet.
          if (!kbState.isLoading &&
              !hasKbs &&
              kbState.error == null &&
              !_showCreateForm)
            _EmptyState(label: l10n.noWisdomItems),

          // Items nested under the active KB.
          for (final item in items) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: _WisdomItemRow(item: item),
            ),
            const SizedBox(height: 7),
          ],

          // Create KB form.
          if (_showCreateForm) ...[
            _CreateKbForm(
              controller: _kbNameCtrl,
              isLoading: kbState.isLoading,
              selectedPrivacy: kbState.selectedPrivacy,
              onPrivacyChanged: (p) =>
                  ref.read(knowledgeControllerProvider.notifier).setPrivacy(p),
              onSubmit: _onCreateKb,
              onCancel: () => setState(() => _showCreateForm = false),
            ),
            const SizedBox(height: 7),
          ],

          const SizedBox(height: 7),
          _DropZone(
            isUploading: kbState.isUploading,
            onFilesAdded: _onUploadPressed,
          ),
          const SizedBox(height: 7),
          const DriveImportPanel(),
          const SizedBox(height: 14),
          FieldPrimaryButton(
            label: hasKbs
                ? l10n.createNewWisdomWithKi
                : l10n.createKnowledgeBase,
            onPressed: kbState.isLoading
                ? null
                : () {
                    if (!hasKbs || _showCreateForm) {
                      setState(() => _showCreateForm = true);
                    }
                  },
          ),
        ],
      ),
    );
  }

  String _statusText(KnowledgeState kbState, AppLocalizations l10n) {
    if (kbState.isUploading) {
      return l10n.uploadingFiles;
    }
    if (kbState.isImportingDrive) {
      return l10n.driveImportProgress(
        kbState.driveImportDone,
        kbState.driveImportTotal,
      );
    }
    final activeKb = kbState.activeKb;
    if (activeKb != null && activeKb.items.isNotEmpty) {
      return l10n.nSourcesAvailable(activeKb.items.length);
    }
    return l10n.noWisdomItems;
  }

  void _onCreateKb() {
    final name = _kbNameCtrl.text.trim();
    if (name.isEmpty) return;

    final privacy = ref.read(knowledgeControllerProvider).selectedPrivacy;
    ref
        .read(knowledgeControllerProvider.notifier)
        .createAndLinkKb(name: name, privacy: privacy);
    _kbNameCtrl.clear();
    setState(() => _showCreateForm = false);
  }

  void _confirmDeleteKb(BuildContext context, String kbId) {
    final l10n = context.l10n;
    final colors = context.kiduna;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.raised,
        title: Text(
          l10n.deleteKnowledgeBase,
          style: TextStyle(color: colors.cream),
        ),
        content: Text(
          l10n.deleteKbConfirm,
          style: TextStyle(color: colors.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete, style: TextStyle(color: colors.sky)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        ref.read(knowledgeControllerProvider.notifier).unlinkAndDeleteKb(kbId);
      }
    });
  }

  Future<void> _onUploadPressed() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['txt', 'md', 'doc', 'docx', 'pdf'],
      withData: true,
    );
    if (!mounted) return;
    if (result == null || result.files.isEmpty) return;

    final files = <({String name, List<int> bytes})>[];
    for (final f in result.files) {
      if (f.bytes != null && f.name.isNotEmpty) {
        files.add((name: f.name, bytes: f.bytes!));
      }
    }
    if (files.isEmpty) return;

    unawaited(
      ref.read(knowledgeControllerProvider.notifier).uploadFiles(files),
    );
  }
}

/// Shows the selected KB name and a delete button.
class _KbHeader extends StatelessWidget {
  const _KbHeader({required this.kbName, required this.onDelete});

  final String kbName;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.sky.withValues(alpha: 0.04),
        border: Border.all(color: colors.sky.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.kbSelectedName(kbName),
              style: text.label.copyWith(
                color: colors.cream,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CapacityActionButton(label: l10n.delete, onPressed: onDelete),
        ],
      ),
    );
  }
}

/// Inline form for creating a new knowledge base.
class _CreateKbForm extends StatelessWidget {
  const _CreateKbForm({
    required this.controller,
    required this.isLoading,
    required this.selectedPrivacy,
    required this.onPrivacyChanged,
    required this.onSubmit,
    required this.onCancel,
  });

  final TextEditingController controller;
  final bool isLoading;
  final KbPrivacy selectedPrivacy;
  final ValueChanged<KbPrivacy> onPrivacyChanged;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(6, 3, 4, 0.3),
        border: Border.all(color: colors.camel.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.createKnowledgeBase,
            style: text.label.copyWith(
              color: colors.cream,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            autofocus: true,
            style: text.caption.copyWith(color: colors.text),
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color.fromRGBO(6, 3, 4, 0.66),
              hintText: l10n.kbNameHint,
              hintStyle: text.caption.copyWith(color: colors.quiet),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 7,
              ),
              constraints: const BoxConstraints(minHeight: 35),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(
                  color: colors.camel.withValues(alpha: 0.24),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(
                  color: colors.camel.withValues(alpha: 0.24),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _PrivacyDropdown(value: selectedPrivacy, onChanged: onPrivacyChanged),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CapacityActionButton(label: l10n.cancel, onPressed: onCancel),
              const SizedBox(width: 6),
              CapacityActionButton(
                label: isLoading ? l10n.kbLoading : l10n.create,
                onPressed: isLoading ? null : onSubmit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WisdomItemRow extends ConsumerWidget {
  const _WisdomItemRow({required this.item});

  final KbItemModel item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final statusLabel = _statusLabel(item.status, l10n);
    return AssetRow(
      name: item.name,
      detail: '$statusLabel · ${item.type}',
      actions: [
        CapacityActionButton(
          label: l10n.remove,
          onPressed: () => ref
              .read(knowledgeControllerProvider.notifier)
              .deleteItem(item.id),
        ),
      ],
    );
  }

  String _statusLabel(KbIngestStatus status, AppLocalizations l10n) {
    switch (status) {
      case KbIngestStatus.pending:
        return l10n.kbItemPending;
      case KbIngestStatus.ingested:
        return l10n.kbItemIngested;
      case KbIngestStatus.failed:
        return l10n.kbItemFailed;
    }
  }
}

class _DropZone extends StatelessWidget {
  const _DropZone({required this.isUploading, required this.onFilesAdded});

  final bool isUploading;
  final VoidCallback onFilesAdded;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.sky.withValues(alpha: 0.025),
        border: Border.all(
          color: colors.sky.withValues(alpha: 0.36),
          style: BorderStyle.none,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.sky.withValues(alpha: 0.36)),
      ),
      child: Column(
        children: [
          Text(
            l10n.dropSourcesHere,
            style: text.bodySmall.copyWith(color: colors.cream),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.dropZoneFormats,
            textAlign: TextAlign.center,
            style: text.micro.copyWith(color: colors.quiet),
          ),
          const SizedBox(height: 8),
          CapacityActionButton(
            label: isUploading ? l10n.uploadingFiles : l10n.uploadFiles,
            onPressed: isUploading ? null : onFilesAdded,
          ),
        ],
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: colors.sky),
          ),
          const SizedBox(height: 8),
          Text(label, style: text.micro.copyWith(color: colors.quiet)),
        ],
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

/// Row showing a "Visibility" label and a privacy dropdown.
///
/// When a KB is active, changing the dropdown PATCHes the KB's privacy.
/// When no KB exists, it sets the default for the next auto-created KB.
class _KbPrivacySelector extends ConsumerWidget {
  const _KbPrivacySelector({required this.hasActiveKb});

  final bool hasActiveKb;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kbState = ref.watch(knowledgeControllerProvider);

    return _PrivacyDropdown(
      value: kbState.selectedPrivacy,
      onChanged: (privacy) {
        final ctrl = ref.read(knowledgeControllerProvider.notifier);
        if (hasActiveKb) {
          ctrl.updateKbPrivacy(privacy);
        } else {
          ctrl.setPrivacy(privacy);
        }
      },
    );
  }
}

/// Compact dropdown for selecting a [KbPrivacy] value.
class _PrivacyDropdown extends StatelessWidget {
  const _PrivacyDropdown({required this.value, required this.onChanged});

  final KbPrivacy value;
  final ValueChanged<KbPrivacy> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Row(
      children: [
        Text(
          l10n.kbVisibility,
          style: text.label.copyWith(color: colors.cream),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(6, 3, 4, 0.66),
              border: Border.all(color: colors.camel.withValues(alpha: 0.24)),
              borderRadius: BorderRadius.circular(5),
            ),
            child: DropdownButton<KbPrivacy>(
              value: value,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              dropdownColor: colors.raised,
              icon: Icon(Icons.arrow_drop_down, color: colors.sky, size: 18),
              style: text.caption.copyWith(color: colors.text),
              items: KbPrivacy.values.map((p) {
                return DropdownMenuItem<KbPrivacy>(
                  value: p,
                  child: Text(_label(p, l10n)),
                );
              }).toList(),
              onChanged: (p) {
                if (p != null) {
                  onChanged(p);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  String _label(KbPrivacy privacy, AppLocalizations l10n) {
    switch (privacy) {
      case KbPrivacy.public:
        return l10n.kbVisibilityPublic;
      case KbPrivacy.private:
        return l10n.kbVisibilityPrivate;
      case KbPrivacy.secret:
        return l10n.kbVisibilitySecret;
      case KbPrivacy.personal:
        return l10n.kbVisibilityPersonal;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: text.caption.copyWith(color: colors.quiet),
      ),
    );
  }
}
