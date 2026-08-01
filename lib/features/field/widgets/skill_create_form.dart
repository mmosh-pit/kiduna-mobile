import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/skill_trigger_type.dart';
import '../../../core/extensions/context_extensions.dart';
import '../controllers/field_controller.dart';
import '../data/field_fixtures.dart';
import 'field_inputs.dart';
import 'skill_form_sections.dart';

/// Inline form for creating a new Skill — shown inside the skills panel
/// when the user taps "Create a new Skill with Ki".
class SkillCreateForm extends ConsumerStatefulWidget {
  const SkillCreateForm({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<SkillCreateForm> createState() => _SkillCreateFormState();
}

class _SkillCreateFormState extends ConsumerState<SkillCreateForm> {
  final _nameCtrl = TextEditingController();
  final _whenCtrl = TextEditingController();
  final _thenCtrl = TextEditingController();
  SkillTriggerType _triggerType = SkillTriggerType.command;
  final Set<String> _selectedTools = {};
  bool _requiresApproval = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _whenCtrl.dispose();
    _thenCtrl.dispose();
    super.dispose();
  }

  bool get _canCreate =>
      _nameCtrl.text.trim().isNotEmpty &&
      _whenCtrl.text.trim().isNotEmpty &&
      _thenCtrl.text.trim().isNotEmpty;

  void _submit() {
    if (!_canCreate) {
      return;
    }
    ref
        .read(fieldControllerProvider.notifier)
        .createSkill(
          name: _nameCtrl.text.trim(),
          triggerType: _triggerType,
          whenText: _whenCtrl.text.trim(),
          thenText: _thenCtrl.text.trim(),
          tools: _selectedTools.toList(),
          requiresApproval: _requiresApproval,
        );
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final l10n = context.l10n;
    final text = context.kidunaText;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(6, 3, 4, 0.36),
        border: Border.all(color: colors.camel.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.createNewSkillWithKi,
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
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FieldTextInput(
                  label: l10n.skillName,
                  controller: _nameCtrl,
                  hint: l10n.nameThisSkill,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FieldDropdown(
                  label: l10n.triggerType,
                  value: _triggerType.name,
                  options: SkillTriggerType.values.map((t) => t.name).toList(),
                  onChanged: (v) => setState(() {
                    _triggerType = SkillTriggerType.fromJson(v);
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FieldTextInput(
            label: l10n.whenLabel,
            controller: _whenCtrl,
            hint: l10n.whenHint,
          ),
          const SizedBox(height: 4),
          QuickPickChips(
            suggestions:
                FieldFixtures.whenSuggestions[_triggerType] ?? const [],
            onSelected: (v) => _whenCtrl.text = v,
          ),
          const SizedBox(height: 8),
          FieldTextInput(
            label: l10n.thenLabel,
            controller: _thenCtrl,
            hint: l10n.thenHint,
          ),
          const SizedBox(height: 4),
          QuickPickChips(
            suggestions: FieldFixtures.thenSuggestions,
            onSelected: (v) => _thenCtrl.text = v,
          ),
          const SizedBox(height: 8),
          ToolChips(
            tools: FieldFixtures.skillTools,
            selected: _selectedTools,
            onToggle: (tool) => setState(() {
              if (_selectedTools.contains(tool)) {
                _selectedTools.remove(tool);
              } else {
                _selectedTools.add(tool);
              }
            }),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ApprovalToggle(
                  value: _requiresApproval,
                  onChanged: (v) => setState(() => _requiresApproval = v),
                ),
              ),
              const SizedBox(width: 12),
              ListenableBuilder(
                listenable: Listenable.merge([_nameCtrl, _whenCtrl, _thenCtrl]),
                builder: (context, _) => FieldPrimaryButton(
                  label: l10n.createSkill,
                  onPressed: _canCreate ? _submit : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
