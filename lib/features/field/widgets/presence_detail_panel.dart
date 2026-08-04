import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/knowledge_base_model.dart';
import '../controllers/knowledge_controller.dart';
import '../controllers/presence_controller.dart';
import 'field_inputs.dart';

/// Minimum characters for the Goal field before AI generation is allowed.
const _kMinGoalLength = 50;

/// Minimum characters for the Name field.
const _kMinNameLength = 3;

/// Detail panel for creating or editing a single Prompt (system stance).
class PresenceDetailPanel extends ConsumerStatefulWidget {
  const PresenceDetailPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<PresenceDetailPanel> createState() =>
      _PresenceDetailPanelState();
}

class _PresenceDetailPanelState extends ConsumerState<PresenceDetailPanel> {
  late TextEditingController _nameCtrl;
  late TextEditingController _stanceCtrl;
  late TextEditingController _goalCtrl;

  String? _selectedKbId;
  String? _selectedKbName;
  String? _goalWarning;
  String? _nameWarning;

  @override
  void initState() {
    super.initState();
    final s = ref.read(presenceControllerProvider);
    final p = s.activePrompt;

    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _stanceCtrl = TextEditingController(text: p?.content ?? '');
    _goalCtrl = TextEditingController(text: p?.goal ?? '');
    _selectedKbId = p?.connectedKbId;
    _selectedKbName = p?.connectedKbName;

    _goalCtrl.addListener(_onFieldChanged);
    _stanceCtrl.addListener(_onFieldChanged);
    _nameCtrl.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (_goalWarning != null &&
        _goalCtrl.text.trim().length >= _kMinGoalLength) {
      _goalWarning = null;
    }
    if (_nameWarning != null &&
        _nameCtrl.text.trim().length >= _kMinNameLength) {
      _nameWarning = null;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _goalCtrl.removeListener(_onFieldChanged);
    _stanceCtrl.removeListener(_onFieldChanged);
    _nameCtrl.removeListener(_onFieldChanged);
    _nameCtrl.dispose();
    _stanceCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  /// Tap handler: length check → validate-goal → generate.
  Future<void> _onGenerateTap() async {
    final goal = _goalCtrl.text.trim();

    // Length gate.
    if (goal.length < _kMinGoalLength) {
      setState(() {
        _goalWarning =
            'Goal must be at least $_kMinGoalLength characters. '
            'Currently ${goal.length}.';
      });
      return;
    }

    // AI validation.
    final ctrl = ref.read(presenceControllerProvider.notifier);
    final validation = await ctrl.validateGoal(
      goal: goal,
      name: _nameCtrl.text.trim(),
    );
    if (!mounted) return;

    if (!validation.valid) {
      setState(() => _goalWarning = validation.message);
      return;
    }

    // Validation passed — generate.
    _goalWarning = null;
    await _generateWithAi();
  }

  Future<void> _generateWithAi() async {
    final goal = _goalCtrl.text.trim();
    if (goal.isEmpty) return;

    final ctrl = ref.read(presenceControllerProvider.notifier);
    final content = await ctrl.generateFromGoal(
      goal: goal,
      name: _nameCtrl.text.trim(),
      knowledgeBaseName: _selectedKbName,
    );
    if (content != null && mounted) {
      _stanceCtrl.text = content;
      setState(() {});
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.length < _kMinNameLength) {
      setState(() {
        _nameWarning =
            'Name must be at least $_kMinNameLength characters.';
      });
      return;
    }

    final ctrl = ref.read(presenceControllerProvider.notifier);
    final s = ref.read(presenceControllerProvider);

    if (s.isCreateMode) {
      await ctrl.createPrompt(
        name: name,
        content: _stanceCtrl.text,
        goal: _goalCtrl.text.trim(),
        connectedKbId: _selectedKbId,
        connectedKbName: _selectedKbName,
      );
    } else if (s.activePrompt != null) {
      await ctrl.updatePrompt(
        s.activePrompt!.id,
        name: name,
        content: _stanceCtrl.text,
        goal: _goalCtrl.text.trim(),
        connectedKbId: _selectedKbId,
        connectedKbName: _selectedKbName,
      );
    }

    if (mounted) {
      ctrl.closeDetail();
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pState = ref.watch(presenceControllerProvider);
    final kbState = ref.watch(knowledgeControllerProvider);
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = context.l10n;

    final nameText = _nameCtrl.text.trim();
    final goalText = _goalCtrl.text.trim();
    final stanceText = _stanceCtrl.text;
    final charCount = stanceText.length;
    final wordCount = stanceText.trim().isEmpty
        ? 0
        : stanceText.trim().split(RegExp(r'\s+')).length;

    final nameValid = nameText.length >= _kMinNameLength;
    final goalLongEnough = goalText.length >= _kMinGoalLength;
    final isBusy = pState.isGenerating || pState.isValidating;

    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: constraints.maxHeight - 34),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Name ──
                _CounterField(
                  label: l10n.promptName,
                  controller: _nameCtrl,
                  hint: l10n.promptNameHint,
                  current: nameText.length,
                  min: _kMinNameLength,
                ),
                if (_nameWarning != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _nameWarning!,
                      style: text.micro.copyWith(
                        color: const Color(0xFFE34848),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

                // ── Goal ──
                _CounterField(
                  label: l10n.promptGoal,
                  controller: _goalCtrl,
                  hint: l10n.promptGoalHint,
                  current: goalText.length,
                  min: _kMinGoalLength,
                ),

                // ── Goal warning (length or AI validation feedback) ──
                if (_goalWarning != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _goalWarning!,
                      style: text.micro.copyWith(
                        color: const Color(0xFFE34848),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),

                // ── Generate with AI ──
                Align(
                  alignment: Alignment.centerRight,
                  child: isBusy
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                pState.isValidating
                                    ? 'Validating…'
                                    : 'Generating…',
                                style: text.micro.copyWith(
                                  color: colors.quiet,
                                ),
                              ),
                            ],
                          ),
                        )
                      : TextButton.icon(
                          onPressed: _onGenerateTap,
                          icon: Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: goalLongEnough
                                ? colors.sky
                                : colors.quiet,
                          ),
                          label: Text(
                            l10n.promptGenerateWithAi,
                            style: text.caption.copyWith(
                              color: goalLongEnough
                                  ? colors.sky
                                  : colors.quiet,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 8),

                // ── Stance ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.promptStance,
                      style: text.caption.copyWith(color: colors.quiet),
                    ),
                    Text(
                      l10n.promptCharsWords(charCount, wordCount),
                      style: text.micro.copyWith(color: colors.quiet),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(6, 3, 4, 0.36),
                    border: Border.all(
                      color: colors.camel.withValues(alpha: 0.14),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _stanceCtrl,
                    maxLines: null,
                    expands: true,
                    style: text.body.copyWith(
                      color: colors.cream,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.promptStanceHint,
                      hintStyle: text.body.copyWith(
                        color: colors.quiet,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Inform KB dropdown ──
                Text(
                  l10n.promptInformKb,
                  style: text.caption.copyWith(color: colors.quiet),
                ),
                const SizedBox(height: 4),
                _KbDropdown(
                  knowledgeBases: kbState.knowledgeBases,
                  selectedId: _selectedKbId,
                  isLoading: kbState.isLoading,
                  onChanged: (kb) {
                    setState(() {
                      _selectedKbId = kb?.id;
                      _selectedKbName = kb?.name;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // ── Error ──
                if (pState.error != null) ...[
                  Text(
                    pState.error!,
                    style: text.caption.copyWith(
                      color: const Color(0xFFE34848),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // ── Save ──
                FieldPrimaryButton(
                  label: pState.isLoading
                      ? l10n.promptSaving
                      : l10n.promptSave,
                  onPressed: pState.isLoading || !nameValid
                      ? null
                      : _save,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Counter Field — label left, n/total right, TextField below. Counter inside.
// ─────────────────────────────────────────────────────────────────────────────

class _CounterField extends StatelessWidget {
  const _CounterField({
    required this.label,
    required this.controller,
    required this.current,
    required this.min,
    this.hint,
  });

  final String label;
  final TextEditingController controller;
  final int current;
  final int min;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final valid = current >= min;
    // Only show error state after user starts typing.
    final showError = current > 0 && !valid;

    return TextField(
      controller: controller,
      style: text.caption.copyWith(color: colors.text, height: 1.4),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: text.caption.copyWith(color: colors.quiet),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: hint,
        hintStyle: text.caption.copyWith(color: colors.quiet, height: 1.4),
        suffixText: '$current/$min',
        suffixStyle: text.micro.copyWith(
          color: showError ? const Color(0xFFE34848) : colors.quiet,
        ),
        filled: true,
        fillColor: const Color.fromRGBO(6, 3, 4, 0.36),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colors.camel.withValues(alpha: 0.14),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: showError
                ? const Color(0xFFE34848).withValues(alpha: 0.3)
                : colors.camel.withValues(alpha: 0.14),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colors.sky.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KB Dropdown — ally's linked KBs from knowledgeControllerProvider.
// ─────────────────────────────────────────────────────────────────────────────

class _KbDropdown extends StatelessWidget {
  const _KbDropdown({
    required this.knowledgeBases,
    required this.selectedId,
    required this.onChanged,
    this.isLoading = false,
  });

  final List<KnowledgeBaseModel> knowledgeBases;
  final String? selectedId;
  final ValueChanged<KnowledgeBaseModel?> onChanged;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(6, 3, 4, 0.36),
        border: Border.all(color: colors.camel.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: isLoading
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                l10n.promptLoading,
                style: text.caption.copyWith(color: colors.quiet),
              ),
            )
          : DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: knowledgeBases.any((kb) => kb.id == selectedId)
                    ? selectedId
                    : null,
                isExpanded: true,
                dropdownColor: const Color(0xFF1A1410),
                hint: Text(
                  l10n.promptNone,
                  style: text.caption.copyWith(color: colors.quiet),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    child: Text(
                      l10n.promptNone,
                      style: text.caption.copyWith(color: colors.quiet),
                    ),
                  ),
                  ...knowledgeBases.map(
                    (kb) => DropdownMenuItem<String?>(
                      value: kb.id,
                      child: Text(
                        kb.name,
                        style: text.caption.copyWith(color: colors.cream),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (id) {
                  if (id == null) {
                    onChanged(null);
                  } else {
                    final kb =
                        knowledgeBases.where((k) => k.id == id).firstOrNull;
                    onChanged(kb);
                  }
                },
              ),
            ),
    );
  }
}