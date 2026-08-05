import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/file_download.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/knowledge_base_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../controllers/knowledge_controller.dart';
import 'capacity_header.dart';
import 'drive_import_panel.dart';
import 'field_inputs.dart';

/// Knowledge base detail panel — edit mode or create mode.
///
/// Opens as a separate [FieldPanel] via [FieldWorkingPanels].
class KbDetailPanel extends ConsumerStatefulWidget {
  const KbDetailPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<KbDetailPanel> createState() => _KbDetailPanelState();
}

class _KbDetailPanelState extends ConsumerState<KbDetailPanel> {
  final TextEditingController _nameCtrl = TextEditingController();
  bool _nameInitialized = false;
  bool _sourcesExpanded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kbState = ref.watch(knowledgeControllerProvider);
    final ctrl = ref.read(knowledgeControllerProvider.notifier);
    final isCreate = kbState.isCreateMode;
    final activeKb = kbState.activeKb;
    final items = activeKb?.items ?? const [];

    // Sync name field with active KB (once).
    if (!isCreate && activeKb != null && !_nameInitialized) {
      _nameCtrl.text = activeKb.name;
      _nameInitialized = true;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.all(17),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: constraints.maxHeight - 34,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
            CapacityHeader(
              eyebrow: l10n.wisdom,
              heading: isCreate
                  ? l10n.createKnowledgeBase
                  : activeKb?.name ?? '',
              status: _statusText(kbState, l10n),
            ),
            const SizedBox(height: 14),

            // Error.
            if (kbState.error != null) ...[
              _ErrorRow(message: kbState.error!),
              const SizedBox(height: 7),
            ],

            // Name — label above, field below.
            Text(
              'Name',
              style: context.kidunaText.micro.copyWith(
                color: context.kiduna.muted,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _nameCtrl,
              style: context.kidunaText.caption.copyWith(
                color: context.kiduna.text,
                height: 1.4,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: const Color.fromRGBO(6, 3, 4, 0.66),
                hintText: l10n.kbNameHint,
                hintStyle: context.kidunaText.caption.copyWith(
                  color: context.kiduna.quiet,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 9,
                ),
                constraints: const BoxConstraints(minHeight: 36),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(
                    color: context.kiduna.camel.withValues(alpha: 0.24),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(
                    color: context.kiduna.camel.withValues(alpha: 0.24),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: context.kiduna.sky),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Visibility — label above, dropdown below.
            Text(
              l10n.kbVisibility,
              style: context.kidunaText.micro.copyWith(
                color: context.kiduna.muted,
              ),
            ),
            const SizedBox(height: 4),
            _PrivacyDropdown(
              value: kbState.selectedPrivacy,
              onChanged: (p) {
                if (isCreate) {
                  ctrl.setPrivacy(p);
                } else {
                  ctrl.updateKbPrivacy(p);
                }
              },
            ),
            const SizedBox(height: 14),

            // Create mode: Create button.
            if (isCreate) ...[
              FieldPrimaryButton(
                label: kbState.isLoading ? 'Creating…' : l10n.create,
                onPressed: kbState.isLoading ? null : () => _onCreate(ctrl),
              ),
            ],

            // Edit mode: items + upload + drive.
            if (!isCreate) ...[
              // Items list — collapsible. Default collapsed, tap to expand.
              if (items.isNotEmpty) ...[
                GestureDetector(
                  onTap: () => setState(() =>
                      _sourcesExpanded = !_sourcesExpanded),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: context.kiduna.sky.withValues(alpha: 0.04),
                        border: Border.all(
                          color: context.kiduna.sky.withValues(alpha: 0.15),
                        ),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _sourcesExpanded
                                ? Icons.keyboard_arrow_down
                                : Icons.keyboard_arrow_right,
                            size: 16,
                            color: context.kiduna.sky,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${l10n.wisdom} Sources (${items.length})',
                              style: context.kidunaText.label.copyWith(
                                color: context.kiduna.cream,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_sourcesExpanded) ...[
                  const SizedBox(height: 5),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 95),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 5),
                      itemBuilder: (_, index) {
                        final item = items[index];
                        return _ItemRow(
                          item: item,
                          kbId: activeKb!.id,
                          onRemove: () =>
                              _confirmRemoveItem(context, ctrl, item),
                          onDownload: () =>
                              _downloadItem(context, item),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 7),
              ],

              // Upload zone.
              _UploadZone(
                isUploading: kbState.isUploading,
                onUpload: () => _onUpload(ctrl),
              ),
              const SizedBox(height: 7),

              // Drive import.
              const DriveImportPanel(),
              const SizedBox(height: 14),

              // Save button — saves name changes.
              FieldPrimaryButton(
                label: kbState.isLoading ? 'Saving…' : 'Save',
                onPressed: kbState.isLoading
                    ? null
                    : () => _onSave(ctrl, activeKb!.id),
              ),
            ],
          ],
        ),
      ),
    ),
    );
      },
    );
  }

  void _onCreate(KnowledgeController ctrl) {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    ctrl.createAndLinkKb(
      name: name,
      privacy: ref.read(knowledgeControllerProvider).selectedPrivacy,
    );
    _nameCtrl.clear();
  }

  Future<void> _onSave(KnowledgeController ctrl, String kbId) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    await ctrl.updateKnowledgeBase(kbId, name: name);
    ctrl.closeKbDetail();
  }

  Future<void> _confirmRemoveItem(
    BuildContext context,
    KnowledgeController ctrl,
    KbItemModel item,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Remove Source',
      message: 'Remove "${item.name}"? This will delete it from the '
          'knowledge base and cannot be undone.',
      confirmLabel: 'Remove',
      isDestructive: true,
    );
    if (confirmed == true) {
      unawaited(ctrl.deleteItem(item.id));
    }
  }

  Future<void> _downloadItem(BuildContext context, KbItemModel item) async {
    if (item.sourceUrl != null && item.sourceUrl!.isNotEmpty) {
      // Drive-imported file — open source URL.
      // TODO: use url_launcher when available.
      AppLogger.info(
        'Download source: ${item.sourceUrl}',
        tag: 'KbDetailPanel',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Source URL: ${item.sourceUrl}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Uploaded file — no re-download available from backend.
      // Show item name as info.
      final message = await FileDownload.downloadMarkdown(
        fileName: item.name,
        content: '# ${item.name}\n\nIngested into knowledge base.\n'
            'Chunks: ${item.chunkCount}\n'
            'Status: ${item.status.name}\n',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _onUpload(KnowledgeController ctrl) async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['txt', 'md', 'docx', 'pdf'],
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

    unawaited(ctrl.uploadFiles(files));
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.kbId,
    required this.onRemove,
    required this.onDownload,
  });

  final KbItemModel item;
  final String kbId;
  final VoidCallback onRemove;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final statusLabel = _label(item.status, l10n);
    final isIngested = item.status == KbIngestStatus.ingested;

    return AssetRow(
      name: item.name,
      detail: '$statusLabel · ${item.chunkCount} chunks',
      actions: [
        CapacityActionButton(label: l10n.remove, onPressed: onRemove),
      ],
    );
  }

  String _label(KbIngestStatus status, AppLocalizations l10n) {
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

class _UploadZone extends StatelessWidget {
  const _UploadZone({required this.isUploading, required this.onUpload});

  final bool isUploading;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Container(
      constraints: const BoxConstraints(minHeight: 80),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.sky.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.sky.withValues(alpha: 0.36)),
      ),
      child: Column(
        children: [
          Text(
            l10n.dropSourcesHere,
            style: text.bodySmall.copyWith(color: colors.cream),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.dropZoneFormats,
            textAlign: TextAlign.center,
            style: text.micro.copyWith(color: colors.quiet),
          ),
          const SizedBox(height: 8),
          CapacityActionButton(
            label: isUploading ? l10n.uploadingFiles : l10n.uploadFiles,
            onPressed: isUploading ? null : onUpload,
          ),
        ],
      ),
    );
  }
}

class _PrivacyDropdown extends StatelessWidget {
  const _PrivacyDropdown({required this.value, required this.onChanged});

  final KbPrivacy value;
  final ValueChanged<KbPrivacy> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 9),
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
          if (p != null) onChanged(p);
        },
      ),
    );
  }

  String _label(KbPrivacy p, AppLocalizations l10n) {
    switch (p) {
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

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final text = context.kidunaText;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(227, 72, 72, 0.08),
        border: Border.all(color: const Color.fromRGBO(227, 72, 72, 0.4)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: Color(0xFFE34848)),
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

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.kiduna.sky,
          ),
        ),
      ),
    );
  }
}

String _statusText(KnowledgeState s, AppLocalizations l10n) {
  if (s.isUploading) return l10n.uploadingFiles;
  if (s.isImportingDrive) {
    return l10n.driveImportProgress(s.driveImportDone, s.driveImportTotal);
  }
  if (s.isCreateMode) return 'New knowledge base';
  final kb = s.activeKb;
  if (kb != null && kb.items.isNotEmpty) {
    return l10n.nSourcesAvailable(kb.items.length);
  }
  if (kb != null && kb.items.isEmpty) {
    return 'Upload or import sources below';
  }
  return '';
}