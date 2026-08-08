import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/skill_trigger_type.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/available_tool_model.dart';
import '../../../data/models/saved_tool_model.dart';
import '../controllers/field_controller.dart';
import '../data/field_fixtures.dart';
import 'field_inputs.dart';

/// Skill creation form with tool → action selection flow.
///
/// Step 1: Skill name
/// Step 2: Select a connected tool (only Empower-connected tools shown)
/// Step 3: Pick an action (from MCP server via availableTools API)
/// Step 4: When + Then (user fills or action auto-fills Then)
/// Step 5: Create
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
  String? _selectedTool;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final editing = ref.read(fieldControllerProvider).editingSkill;
      _nameCtrl = TextEditingController(text: editing?.name ?? '');
      _whenCtrl = TextEditingController(text: editing?.whenText ?? '');
      _thenCtrl = TextEditingController(text: editing?.thenText ?? '');
      if (editing != null && editing.tools.isNotEmpty) {
        final tool = editing.tools.first;
        if (tool != 'chat') _selectedTool = tool;
      }
      _initialized = true;
      // Ensure available tools are loaded when form opens.
      Future.microtask(() {
        ref.read(fieldControllerProvider.notifier).fetchAvailableTools(
              force: true,
            );
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _whenCtrl.dispose();
    _thenCtrl.dispose();
    super.dispose();
  }

  Set<String> _connectedTools(List<SavedToolModel> savedTools) {
    return savedTools
        .where((t) => t.isActive)
        .map((t) => t.toolName)
        .toSet();
  }

  /// Filter availableTools by the selected connected tool.
  List<AvailableToolModel> _actionsForTool(
    List<AvailableToolModel> availableTools,
  ) {
    if (_selectedTool == null) return [];
    final services =
        FieldFixtures.toolServiceMap[_selectedTool] ?? [_selectedTool!];
    return availableTools
        .where((t) => t.isExternal && services.contains(t.id))
        .toList();
  }

  SkillTriggerType get _inferredTriggerType {
    final type = FieldFixtures.detectTriggerType(_whenCtrl.text);
    return SkillTriggerType.values.firstWhere(
      (t) => t.name == type,
      orElse: () => SkillTriggerType.command,
    );
  }

  /// Check if the Then text matches any available action for the selected tool.
  bool _matchesAvailableAction(List<AvailableToolModel> actions) {
    if (_selectedTool == null) return true; // no tool = chat-only, always ok
    if (actions.isEmpty) return false; // tool selected but no actions loaded
    final thenText = _thenCtrl.text.trim().toLowerCase();
    if (thenText.isEmpty) return true; // empty = not validated yet
    for (final action in actions) {
      // Extract keywords from action name: "Reply To Post" → ["reply", "post"]
      final keywords = action.name.toLowerCase().split(' ');
      // Match if any keyword appears in the then text
      for (final keyword in keywords) {
        if (keyword.length > 2 && thenText.contains(keyword)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _canCreate(List<AvailableToolModel> actions) =>
      _nameCtrl.text.trim().isNotEmpty &&
      _whenCtrl.text.trim().isNotEmpty &&
      _thenCtrl.text.trim().isNotEmpty &&
      _matchesAvailableAction(actions);

  void _submit() {
    final controller = ref.read(fieldControllerProvider.notifier);
    final editing = ref.read(fieldControllerProvider).editingSkill;

    final tools = <String>[];
    if (_selectedTool != null) {
      tools.add(_selectedTool!);
    } else {
      tools.add('chat');
    }

    if (editing != null) {
      controller.updateSkill(
        skillId: editing.id,
        name: _nameCtrl.text.trim(),
        triggerType: _inferredTriggerType,
        whenText: _whenCtrl.text.trim(),
        thenText: _thenCtrl.text.trim(),
        tools: tools,
      );
    } else {
      controller.createSkill(
        name: _nameCtrl.text.trim(),
        triggerType: _inferredTriggerType,
        whenText: _whenCtrl.text.trim(),
        thenText: _thenCtrl.text.trim(),
        tools: tools,
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
    final availableTools = ref.watch(
      fieldControllerProvider.select((s) => s.availableTools),
    );
    final connected = _connectedTools(savedTools);
    final actions = _actionsForTool(availableTools);
    final toolColor = Color(
      FieldFixtures.toolColors[_selectedTool] ?? 0xFF888888,
    );

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

            // ── Select Tool ──
            Text(
              'Select tool',
              style: text.label.copyWith(color: colors.cream),
            ),
            const SizedBox(height: 6),
            if (connected.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(6),
                  color: const Color(0xFFEF4444).withValues(alpha: 0.06),
                ),
                child: Text(
                  'Connect a tool in Empower section first',
                  style: text.micro.copyWith(
                    color: const Color(0xFFEF4444),
                    fontSize: 10,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final tool in connected)
                    _ToolChip(
                      tool: tool,
                      selected: _selectedTool == tool,
                      onTap: () => setState(() {
                        _selectedTool = _selectedTool == tool ? null : tool;
                      }),
                    ),
                ],
              ),
            const SizedBox(height: 14),

            // ── Available Actions (from MCP API) ──
            if (_selectedTool != null) ...[
              Text(
                'Available ${FieldFixtures.toolDisplayNames[_selectedTool] ?? _selectedTool} actions',
                style: text.label.copyWith(
                  color: toolColor,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              if (actions.isEmpty)
                Text(
                  'No actions available — MCP server may be offline',
                  style: text.micro.copyWith(
                    color: colors.muted,
                    fontSize: 9,
                  ),
                )
              else
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    for (final action in actions)
                      GestureDetector(
                        onTap: () => setState(() {
                          _thenCtrl.text = action.name;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: toolColor.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(10),
                            color: toolColor.withValues(alpha: 0.06),
                          ),
                          child: Text(
                            action.name,
                            style: text.micro.copyWith(
                              color: toolColor,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 14),
            ],

            // ── When ──
            FieldTextInput(
              label: l10n.whenLabel,
              controller: _whenCtrl,
              hint: l10n.whenHint,
              maxLength: 200,
            ),
            const SizedBox(height: 4),
            // When suggestions: tool selected → 3 per tool. No tool → 1 per connected tool.
            if (_selectedTool != null)
              _QuickChips(
                suggestions:
                    FieldFixtures.toolWhenSuggestions[_selectedTool] ?? [],
                color: toolColor,
                onTap: (v) => setState(() => _whenCtrl.text = v),
              )
            else if (connected.isNotEmpty)
              _QuickChips(
                suggestions: [
                  for (final tool in connected)
                    if (FieldFixtures.toolDefaultWhen.containsKey(tool))
                      FieldFixtures.toolDefaultWhen[tool]!,
                ],
                color: colors.sky,
                onTap: (v) => setState(() => _whenCtrl.text = v),
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
            // Then suggestions: tool selected → actions from API. No tool → 1 default per connected tool.
            if (_selectedTool != null && actions.isNotEmpty)
              const SizedBox.shrink() // Actions already shown above as chips
            else if (_selectedTool == null && connected.isNotEmpty)
              _QuickChips(
                suggestions: [
                  for (final tool in connected)
                    if (FieldFixtures.toolDefaultThen.containsKey(tool))
                      FieldFixtures.toolDefaultThen[tool]!,
                ],
                color: colors.sky,
                onTap: (v) => setState(() => _thenCtrl.text = v),
              ),

            // ── Action mismatch warning ──
            if (_selectedTool != null)
              ListenableBuilder(
                listenable: _thenCtrl,
                builder: (context, _) {
                  final thenText = _thenCtrl.text.trim();
                  if (thenText.isEmpty || _matchesAvailableAction(actions)) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'This action may not be available for '
                      '${FieldFixtures.toolDisplayNames[_selectedTool] ?? _selectedTool}',
                      style: text.micro.copyWith(
                        color: const Color(0xFFEF4444),
                        fontSize: 9,
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 14),

            // ── Submit ──
            ListenableBuilder(
              listenable: Listenable.merge([_nameCtrl, _whenCtrl, _thenCtrl]),
              builder: (context, _) {
                final canCreate = _canCreate(actions);
                return Align(
                  alignment: Alignment.centerRight,
                  child: FieldPrimaryButton(
                    label: isEditing ? 'Save changes' : l10n.createSkill,
                    onPressed: canCreate ? _submit : null,
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

/// A single tool selection chip with color from FieldFixtures.
class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.tool,
    required this.selected,
    required this.onTap,
  });

  final String tool;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final chipColor = Color(
      FieldFixtures.toolColors[tool] ?? 0xFF888888,
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? chipColor.withValues(alpha: 0.15)
              : Colors.transparent,
          border: Border.all(
            color: selected
                ? chipColor
                : colors.camel.withValues(alpha: 0.22),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          FieldFixtures.toolDisplayNames[tool] ?? tool,
          style: text.caption.copyWith(
            color: selected ? chipColor : colors.muted,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

/// Tappable quick-pick suggestion chips.
class _QuickChips extends StatelessWidget {
  const _QuickChips({
    required this.suggestions,
    required this.color,
    required this.onTap,
  });

  final List<String> suggestions;
  final Color color;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final text = context.kidunaText;
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: [
        for (final s in suggestions)
          GestureDetector(
            onTap: () => onTap(s),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: color.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(10),
                color: color.withValues(alpha: 0.06),
              ),
              child: Text(
                s,
                style: text.micro.copyWith(
                  color: color,
                  fontSize: 9,
                ),
              ),
            ),
          ),
      ],
    );
  }
}