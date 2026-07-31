import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import 'capacity_header.dart';
import 'field_inputs.dart';

/// Wisdom capacity workspace — file list, drop zone, link import,
/// and "Create new Wisdom with Ki" action.
class WisdomPanel extends StatefulWidget {
  const WisdomPanel({super.key, required this.realmName});

  final String realmName;

  @override
  State<WisdomPanel> createState() => _WisdomPanelState();
}

class _WisdomPanelState extends State<WisdomPanel> {
  final List<_WisdomDrop> _drops = [
    (name: 'kinship-purpose.md', classification: 'Realm · Private'),
    (name: 'member-agency-principles.md', classification: 'Ecosystem · Shared'),
    (name: 'realm-formation-guide.md', classification: 'Ecosystem · Shared'),
  ];
  String _status = 'Google · Connected';
  final TextEditingController _link = TextEditingController();

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CapacityHeader(
            eyebrow: l10n.wisdom,
            heading: l10n.whatRealmMayKnow(widget.realmName),
            status: _status,
          ),
          const SizedBox(height: 14),
          for (final drop in _drops) ...[
            AssetRow(
              name: drop.name,
              detail: '${drop.classification} · Markdown',
              actions: [
                CapacityActionButton(
                  label: l10n.edit,
                  onPressed: () =>
                      setState(() => _status = 'Editing: ${drop.name}'),
                ),
                CapacityActionButton(
                  label: l10n.remove,
                  onPressed: () => setState(
                    () => _drops.removeWhere((d) => d.name == drop.name),
                  ),
                ),
                CapacityActionButton(
                  label: l10n.download,
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 7),
          ],
          const SizedBox(height: 7),
          _DropZone(
            onFilesAdded: (count) => setState(
              () => _status = '$count source${count == 1 ? '' : 's'} prepared',
            ),
          ),
          const SizedBox(height: 14),
          _LinkImport(controller: _link, onCheck: () {}),
          const SizedBox(height: 14),
          FieldPrimaryButton(
            label: l10n.createNewWisdomWithKi,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

typedef _WisdomDrop = ({String name, String classification});

class _DropZone extends StatelessWidget {
  const _DropZone({required this.onFilesAdded});

  final ValueChanged<int> onFilesAdded;

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
          CapacityActionButton(label: l10n.uploadFiles, onPressed: () {}),
        ],
      ),
    );
  }
}

class _LinkImport extends StatelessWidget {
  const _LinkImport({required this.controller, required this.onCheck});

  final TextEditingController controller;
  final VoidCallback onCheck;

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
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.googleDocsOrDriveLink,
                    style: text.micro.copyWith(color: colors.cream),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: controller,
                    style: text.caption.copyWith(color: colors.text),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: const Color.fromRGBO(6, 3, 4, 0.66),
                      hintText: 'Paste a Google Docs or Drive link',
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
                ],
              ),
            ),
            const SizedBox(width: 8),
            CapacityActionButton(label: l10n.checkAccess, onPressed: onCheck),
          ],
        ),
      ),
    );
  }
}
