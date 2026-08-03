import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../controllers/ally_controller.dart';
import 'capacity_header.dart';
import 'field_inputs.dart';

/// Presence capacity workspace — system instructions editor wired to the
/// ally agent's `systemPrompt` field via PATCH `/api/agents/{id}`.
class PresenceCapacityPanel extends ConsumerStatefulWidget {
  const PresenceCapacityPanel({super.key, required this.realmName});

  final String realmName;

  @override
  ConsumerState<PresenceCapacityPanel> createState() =>
      _PresenceCapacityPanelState();
}

class _PresenceCapacityPanelState extends ConsumerState<PresenceCapacityPanel> {
  late final TextEditingController _instructions;
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    _instructions = TextEditingController();
  }

  @override
  void dispose() {
    _instructions.dispose();
    super.dispose();
  }

  void _syncFromAlly(AllyState allyState) {
    if (_initialised) return;
    final saved = allyState.ally?.systemPrompt ?? '';
    _instructions.text = saved.isNotEmpty
        ? saved
        : context.l10n.presenceDefaultPrompt(widget.realmName);
    _initialised = true;
  }

  String _computeStatus(AllyState allyState) {
    final l10n = context.l10n;
    if (allyState.isSavingPresence) return l10n.presenceStatusSaving;

    final saved = allyState.ally?.systemPrompt ?? '';
    final current = _instructions.text;

    if (saved.isEmpty) return l10n.presenceStatusInherited;
    if (current == saved) return l10n.presenceStatusSaved;
    return l10n.presenceStatusDraft;
  }

  Future<void> _save() async {
    await ref
        .read(allyControllerProvider.notifier)
        .updateSystemPrompt(_instructions.text);
    if (!mounted) return;
    setState(() {});
  }

  void _resetToDefault() {
    final defaultText = context.l10n.presenceDefaultPrompt(widget.realmName);
    _instructions.text = defaultText;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final allyState = ref.watch(allyControllerProvider);
    _syncFromAlly(allyState);

    final l10n = context.l10n;
    final colors = context.kiduna;
    final text = context.kidunaText;
    final status = _computeStatus(allyState);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.65,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            CapacityHeader(
              eyebrow: l10n.presence,
              heading: l10n.howRealmBehaves(widget.realmName),
              status: status,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.currentSystemInstructions,
              style: text.micro.copyWith(color: colors.cream),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _instructions,
              maxLines: 6,
              onChanged: (_) => setState(() {}),
              style: text.caption.copyWith(color: colors.text, height: 1.4),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: const Color.fromRGBO(6, 3, 4, 0.66),
                contentPadding: const EdgeInsets.all(8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(
                    color: colors.camel.withValues(alpha: 0.24),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(
                    color: colors.camel.withValues(alpha: 0.24),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: colors.sky),
                ),
              ),
            ),
            if (allyState.error != null) ...[
              const SizedBox(height: 8),
              Text(
                allyState.error!,
                style: text.micro.copyWith(color: colors.error),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              l10n.presenceRequired,
              style: text.micro.copyWith(color: colors.quiet),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                CapacityActionButton(
                  label: l10n.presenceSave,
                  onPressed: allyState.isSavingPresence ? null : _save,
                ),
                CapacityActionButton(
                  label: l10n.resetToDefault,
                  onPressed: _resetToDefault,
                ),
                CapacityActionButton(label: l10n.download, onPressed: () {}),
              ],
            ),
            const SizedBox(height: 12),
            FieldPrimaryButton(
              label: l10n.developNewPresenceWithKi,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
