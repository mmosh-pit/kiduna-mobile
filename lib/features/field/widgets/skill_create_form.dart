import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/skill_trigger_type.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/saved_tool_model.dart';
import '../controllers/field_controller.dart';
import '../data/field_fixtures.dart';
import 'field_inputs.dart';
import 'skill_form_sections.dart';

/// Form for creating or editing a Skill — opens as a separate [FieldPanel].
///
/// Tools and trigger type are auto-detected from when/then text.
/// If detected tools are not connected in Empower, shows an error.
class SkillCreateForm extends ConsumerStatefulWidget {
  const SkillCreateForm({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<SkillCreateForm> createState() => _SkillCreateFormState();
}

class _SkillCreateFormState extends ConsumerState<SkillCreateForm> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _whenCtrl;
  late final TextEditingController _thenCtrl;
  late bool _requiresApproval;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final editing = ref.read(fieldControllerProvider).editingSkill;
      _nameCtrl = TextEditingController(text: editing?.name ?? '');
      _whenCtrl = TextEditingController(text: editing?.whenText ?? '');
      _thenCtrl = TextEditingController(text: editing?.thenText ?? '');
      _requiresApproval = editing?.requiresApproval ?? false;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _whenCtrl.dispose();
    _thenCtrl.dispose();
    super.dispose();
  }

  /// Auto-detect tools from when + then text.
  Set<String> get _detectedTools => FieldFixtures.detectTools(
        _whenCtrl.text,
        _thenCtrl.text,
      );

  /// Connected tool providers from Empower.
  Set<String> _connectedTools(List<SavedToolModel> savedTools) {
    return savedTools
        .where((t) => t.isActive)
        .map((t) => t.toolName)
        .toSet();
  }

  /// Tools detected but not connected.
  List<String> _missingTools(Set<String> detected, Set<String> connected) {
    return detected.where((t) => !connected.contains(t)).toList();
  }

  /// Auto-detect trigger type from when text.
  SkillTriggerType get _inferredTriggerType {
    final type = FieldFixtures.detectTriggerType(_whenCtrl.text);
    return SkillTriggerType.values.firstWhere(
      (t) => t.name == type,
      orElse: () => SkillTriggerType.command,
    );
  }

  bool _canCreate(Set<String> detected, Set<String> connected) {
    final missing = _missingTools(detected, connected);
    return _nameCtrl.text.trim().isNotEmpty &&
        _whenCtrl.text.trim().isNotEmpty &&
        _thenCtrl.text.trim().isNotEmpty &&
        missing.isEmpty;
  }

  void _submit(Set<String> detected) {
    final controller = ref.read(fieldControllerProvider.notifier);
    final editing = ref.read(fieldControllerProvider).editingSkill;

    // Auto-set tools: detected external tools + "chat" for chat-triggered
    final tools = <String>{...detected};
    if (tools.isEmpty) {
      tools.add('chat');
    }

    if (editing != null) {
      controller.updateSkill(
        skillId: editing.id,
        name: _nameCtrl.text.trim(),
        triggerType: _inferredTriggerType,
        whenText: _whenCtrl.text.trim(),
        thenText: _thenCtrl.text.trim(),
        tools: tools.toList(),
        requiresApproval: _requiresApproval,
      );
    } else {
      controller.createSkill(
        name: _nameCtrl.text.trim(),
        triggerType: _inferredTriggerType,
        whenText: _whenCtrl.text.trim(),
        thenText: _thenCtrl.text.trim(),
        tools: tools.toList(),
        requiresApproval: _requiresApproval,
      );
    }
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final l10n = context.l10n;
    final text = context.kidunaText;
    final isEditing = ref.read(fieldControllerProvider).editingSkill != null;
    final savedTools = ref.watch(
      fieldControllerProvider.select((s) => s.savedTools),
    );
    final connected = _connectedTools(savedTools);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(6, 3, 4, 0.36),
        border: Border.all(color: colors.camel.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          // ── Header ──
          Row(
            children: [
              Expanded(
                child: Text(
                  isEditing ? 'Edit Skill' : l10n.createNewSkillWithKi,
                  style: text.label.copyWith(
                    color: colors.cream,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onClose,
                child: Icon(Icons.close, size: 14, color: colors.muted),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Skill Name ──
          FieldTextInput(
            label: l10n.skillName,
            controller: _nameCtrl,
            hint: l10n.nameThisSkill,
            maxLength: 20,
          ),
          const SizedBox(height: 14),

          // ── When ──
          FieldTextInput(
            label: l10n.whenLabel,
            controller: _whenCtrl,
            hint: l10n.whenHint,
            maxLength: 200,
          ),
          const SizedBox(height: 4),
          QuickPickChips(
            suggestions: FieldFixtures.whenSuggestions,
            onSelected: (v) => setState(() => _whenCtrl.text = v),
          ),
          const SizedBox(height: 14),

          // ── Then ──
          FieldTextInput(
            label: l10n.thenLabel,
            controller: _thenCtrl,
            hint: l10n.thenHint,
            maxLength: 200,
          ),
          const SizedBox(height: 4),
          QuickPickChips(
            suggestions: FieldFixtures.thenSuggestions,
            onSelected: (v) => setState(() => _thenCtrl.text = v),
          ),

          // ── Auto-detected tools info ──
          ListenableBuilder(
            listenable: Listenable.merge([_whenCtrl, _thenCtrl]),
            builder: (context, _) {
              final detected = _detectedTools;
              final missing = _missingTools(detected, connected);
              return DetectedToolsInfo(
                detectedTools: detected,
                connectedTools: connected,
                missingTools: missing,
              );
            },
          ),
          const SizedBox(height: 14),

          // ── Submit ──
          ListenableBuilder(
            listenable: Listenable.merge([_nameCtrl, _whenCtrl, _thenCtrl]),
            builder: (context, _) {
              final detected = _detectedTools;
              final canCreate = _canCreate(detected, connected);
              return Align(
                alignment: Alignment.centerRight,
                child: FieldPrimaryButton(
                  label: isEditing ? 'Save changes' : l10n.createSkill,
                  onPressed: canCreate ? () => _submit(detected) : null,
                ),
              );
            },
          ),
        ],
      ),
      ),
    );
  }
}
