import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/enums/skill_trigger_type.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/available_tool_model.dart';
import '../../../data/models/saved_tool_model.dart';
import '../../../data/services/skill_service.dart';
import '../../../data/services/tool_connection_service.dart';
import '../../auth/controllers/auth_controller.dart';
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
  bool _requiresApproval = false;
  bool _actionsExpanded = true;
  bool _previewExpanded = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final editing = ref.read(fieldControllerProvider).editingSkill;
      final uploaded = ref.read(fieldControllerProvider).uploadedSkillData;
      _nameCtrl = TextEditingController(
        text: editing?.name ?? uploaded?['name'] as String? ?? '',
      );
      _whenCtrl = TextEditingController(
        text: editing?.whenText ?? uploaded?['whenText'] as String? ?? '',
      );
      _thenCtrl = TextEditingController(
        text: editing?.thenText ?? uploaded?['thenText'] as String? ?? '',
      );
      if (editing != null && editing.tools.isNotEmpty) {
        final tool = editing.tools.first;
        if (tool != 'chat') _selectedTool = tool;
      } else if (uploaded != null) {
        final tool = (uploaded['tool'] as String? ?? '').toLowerCase();
        if (tool.isNotEmpty) _selectedTool = tool;
      }
      _requiresApproval = editing?.requiresApproval ?? false;
      _initialized = true;
      // Ensure available tools are loaded when form opens.
      Future.microtask(() {
        ref.read(fieldControllerProvider.notifier).fetchAvailableTools(
              force: true,
            );
      });
    }

    // Update form when uploaded skill data arrives (async).
    final uploaded = ref.read(fieldControllerProvider).uploadedSkillData;
    if (uploaded != null && _nameCtrl.text.isEmpty) {
      _nameCtrl.text = uploaded['name'] as String? ?? '';
      _whenCtrl.text = uploaded['whenText'] as String? ?? '';
      _thenCtrl.text = uploaded['thenText'] as String? ?? '';
      final tool = (uploaded['tool'] as String? ?? '').toLowerCase();
      if (tool.isNotEmpty && _selectedTool != tool) {
        _selectedTool = tool;
      }
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

  bool _canCreate(List<AvailableToolModel> actions) {
    final hasName = _nameCtrl.text.trim().isNotEmpty;
    if (!hasName) return false;

    // Tool must be selected.
    if (_selectedTool == null) return false;

    // Tool must be connected.
    final savedTools = ref.read(
      fieldControllerProvider.select((s) => s.savedTools),
    );
    final connected = _connectedTools(savedTools);

    // For registered tools (local source) — must be connected in Empower.
    // For LLM-discovered tools — must be connected via auth fields.
    final registry = ref.read(fieldControllerProvider).uploadedToolRegistry;
    final isLocal = registry?['source'] == 'local' ||
        (registry?['configured'] == true);

    if (!connected.contains(_selectedTool)) {
      // Not connected — but check if no auth needed.
      final authType = registry?['auth_type'] as String? ?? '';
      if (authType != 'none') return false;
    }

    // For uploads, When/Then are inside the MD content — no field validation.
    final uploaded = ref.read(fieldControllerProvider).uploadedSkillData;
    if (uploaded != null) {
      return true;
    }

    // Manual mode — need when + then.
    final hasWhen = _whenCtrl.text.trim().isNotEmpty;
    final hasThen = _thenCtrl.text.trim().isNotEmpty;
    return hasWhen && hasThen;
  }

  void _submit() {
    final controller = ref.read(fieldControllerProvider.notifier);
    final editing = ref.read(fieldControllerProvider).editingSkill;
    final uploaded = ref.read(fieldControllerProvider).uploadedSkillData;

    final tools = <String>[];
    if (_selectedTool != null) {
      tools.add(_selectedTool!);
    } else {
      tools.add('chat');
    }

    // For uploads, use when/then from parsed MD data.
    final whenText = uploaded != null
        ? (uploaded['whenText'] as String? ?? _whenCtrl.text.trim())
        : _whenCtrl.text.trim();
    final thenText = uploaded != null
        ? (uploaded['thenText'] as String? ?? _thenCtrl.text.trim())
        : _thenCtrl.text.trim();

    if (editing != null) {
      controller.updateSkill(
        skillId: editing.id,
        name: _nameCtrl.text.trim(),
        triggerType: _inferredTriggerType,
        whenText: whenText,
        thenText: thenText,
        tools: tools,
        requiresApproval: _requiresApproval,
      );
    } else {
      controller.createSkill(
        name: _nameCtrl.text.trim(),
        triggerType: _inferredTriggerType,
        whenText: whenText,
        thenText: thenText,
        tools: tools,
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
    final availableTools = ref.watch(
      fieldControllerProvider.select((s) => s.availableTools),
    );
    final connected = _connectedTools(savedTools);
    final actions = _actionsForTool(availableTools);
    final toolColor = Color(
      FieldFixtures.toolColors[_selectedTool] ?? 0xFF888888,
    );
    final uploaded = ref.watch(
      fieldControllerProvider.select((s) => s.uploadedSkillData),
    );
    final isUpload = uploaded != null;
    final uploadedContent = uploaded?['skillContent'] as String? ?? '';

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
          // ══════════════════════════════════════════════════
          // FIXED HEADER — always visible
          // ══════════════════════════════════════════════════
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
            ],
          ),
          const SizedBox(height: 10),

          // ── Skill Name (fixed at top) ──
          FieldTextInput(
            label: l10n.skillName,
            controller: _nameCtrl,
            hint: l10n.nameThisSkill,
            maxLength: 20,
          ),
          const SizedBox(height: 10),

          // ══════════════════════════════════════════════════
          // SCROLLABLE MIDDLE — tools, auth fields, preview
          // ══════════════════════════════════════════════════
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
            Text(
              'Select tool',
              style: text.label.copyWith(color: colors.cream),
            ),
            const SizedBox(height: 6),
            Builder(builder: (context) {
              // Upload mode: only show detected tool.
              // Manual mode: show connected tools + selected tool.
              final allTools = <String>{};
              if (isUpload) {
                if (_selectedTool != null) allTools.add(_selectedTool!);
              } else {
                allTools.addAll(connected);
                if (_selectedTool != null) allTools.add(_selectedTool!);
              }

              if (allTools.isEmpty) {
                return Container(
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
                );
              }

              return Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final tool in allTools)
                    _ToolChip(
                      tool: tool,
                      selected: _selectedTool == tool,
                      isConnected: connected.contains(tool),
                      locked: isUpload,
                      onTap: isUpload
                          ? () {} // Upload mode: cannot unselect.
                          : () {
                              setState(() {
                                _selectedTool =
                                    _selectedTool == tool ? null : tool;
                                _actionsExpanded = true;
                              });
                              // Fetch available tools when connected.
                              if (_selectedTool != null &&
                                  connected.contains(tool)) {
                                ref
                                    .read(fieldControllerProvider
                                        .notifier)
                                    .fetchAvailableTools(force: true);
                              }
                            },
                    ),
                ],
              );
            }),
            const SizedBox(height: 10),

            // ── Tool connection status ──
            if (_selectedTool != null)
              Builder(builder: (context) {
                final registry = ref.watch(
                  fieldControllerProvider
                      .select((s) => s.uploadedToolRegistry),
                );
                final found = registry?['found'] == true;
                final source = registry?['source'] as String? ?? '';
                final toolName =
                    registry?['name'] as String? ?? _selectedTool!;
                final authType =
                    registry?['auth_type'] as String? ?? 'token';
                final authFields =
                    (registry?['auth_fields'] as List<dynamic>?) ?? [];

                // Registered tools — these are in config.yaml.
                const registeredTools = {
                  'bluesky',
                  'telegram',
                  'telegram_bot_tool',
                  'google',
                  'gmail',
                  'google_gmail_tool',
                  'calendar',
                  'google_calendar_tool',
                  'meet',
                  'google_meet_tool',
                  'solana',
                };
                final isLocal = registeredTools
                        .contains(_selectedTool) ||
                    source == 'local' ||
                    (registry?['configured'] == true);

                // Find connected account for this tool.
                final savedTool = savedTools
                    .where((t) =>
                        t.toolName == _selectedTool && t.isActive)
                    .toList();
                final isConnected = savedTool.isNotEmpty;
                final accountHandle = isConnected
                    ? (savedTool.first.externalHandle ?? '')
                    : '';

                // ── STATE 1a: Local tool + connected — show nothing ──
                if (isLocal && isConnected) {
                  return const SizedBox.shrink();
                }

                // ── STATE 1b: LLM tool + connected — show account + disconnect ──
                if (!isLocal && isConnected) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF34D399)
                            .withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(6),
                      color: const Color(0xFF34D399)
                          .withValues(alpha: 0.06),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            size: 14, color: Color(0xFF34D399)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$toolName connected',
                                style: text.micro.copyWith(
                                  color: const Color(0xFF34D399),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (accountHandle.isNotEmpty)
                                Text(
                                  accountHandle,
                                  style: text.micro.copyWith(
                                    color: const Color(0xFF34D399)
                                        .withValues(alpha: 0.7),
                                    fontSize: 9,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final id = savedTool.first.id;
                            final w = ref
                                    .read(authControllerProvider)
                                    .user
                                    ?.wallet ??
                                '';
                            if (id.isNotEmpty && w.isNotEmpty) {
                              await ToolConnectionService.instance
                                  .remove(wallet: w, id: id);
                              ref
                                  .read(fieldControllerProvider
                                      .notifier)
                                  .fetchSavedTools();
                            }
                          },
                          child: Text(
                            'Disconnect',
                            style: text.micro.copyWith(
                              color: const Color(0xFFEF4444),
                              fontSize: 9,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // ── STATE 2: Local (config.yaml) + not connected ──
                if (isLocal && !isConnected) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFF59E0B)
                            .withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(6),
                      color: const Color(0xFFF59E0B)
                          .withValues(alpha: 0.06),
                    ),
                    child: Text(
                      'Connect $toolName in Empower first',
                      style: text.micro.copyWith(
                        color: const Color(0xFFF59E0B),
                        fontSize: 10,
                      ),
                    ),
                  );
                }

                // ── STATE 3: Not found in registry ──
                if (!found) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFEF4444)
                            .withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(6),
                      color: const Color(0xFFEF4444)
                          .withValues(alpha: 0.06),
                    ),
                    child: Text(
                      '$toolName integration is not available yet',
                      style: text.micro.copyWith(
                        color: const Color(0xFFEF4444),
                        fontSize: 10,
                      ),
                    ),
                  );
                }

                // ── STATE 4: OAuth tool — not supported in-form ──
                if (authType == 'oauth' && authFields.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFF59E0B)
                            .withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(6),
                      color: const Color(0xFFF59E0B)
                          .withValues(alpha: 0.06),
                    ),
                    child: Text(
                      '$toolName uses OAuth — connect it from Empower first',
                      style: text.micro.copyWith(
                        color: const Color(0xFFF59E0B),
                        fontSize: 10,
                      ),
                    ),
                  );
                }

                // ── STATE 5: No auth fields — unsupported ──
                if (authFields.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFF59E0B)
                            .withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(6),
                      color: const Color(0xFFF59E0B)
                          .withValues(alpha: 0.06),
                    ),
                    child: Text(
                      '$toolName setup is not available yet',
                      style: text.micro.copyWith(
                        color: const Color(0xFFF59E0B),
                        fontSize: 10,
                      ),
                    ),
                  );
                }

                // ── STATE 6: LLM discovered + not connected — show auth fields ──
                return _AuthFieldsConnect(
                  toolName: toolName,
                  selectedTool: _selectedTool!,
                  authFields: authFields
                      .whereType<Map<String, dynamic>>()
                      .toList(),
                  onConnected: () {
                    ref.read(fieldControllerProvider.notifier)
                        .fetchSavedTools();
                    setState(() {});
                  },
                );
              }),
            const SizedBox(height: 10),

            // ── Preview (for uploaded MD only) ──
            if (isUpload && uploadedContent.isNotEmpty) ...[
              GestureDetector(
                onTap: () => setState(() {
                  _previewExpanded = !_previewExpanded;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.raised,
                    border: Border.all(
                      color: colors.camel.withValues(alpha: 0.14),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 13,
                        color: colors.sky,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Preview skill content',
                          style: text.caption.copyWith(
                            color: colors.cream,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Icon(
                        _previewExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 16,
                        color: colors.muted,
                      ),
                    ],
                  ),
                ),
              ),
              if (_previewExpanded) ...[
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 180),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.raised,
                    border: Border.all(
                      color: colors.camel.withValues(alpha: 0.14),
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      child: Text(
                        uploadedContent,
                        style: text.caption.copyWith(
                          color: colors.muted,
                          fontSize: 10,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
            ],

            // ── When (manual create only) ──
            if (!isUpload) ...[
              FieldTextInput(
              label: l10n.whenLabel,
              controller: _whenCtrl,
              hint: l10n.whenHint,
              maxLength: 200,
            ),
            const SizedBox(height: 4),
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
                    ...FieldFixtures.toolWhenSuggestions[tool] ?? [],
                ],
                color: colors.sky,
                onTap: (v) => setState(() => _whenCtrl.text = v),
              ),
            const SizedBox(height: 10),

            // ── Then ──
            FieldTextInput(
              label: l10n.thenLabel,
              controller: _thenCtrl,
              hint: l10n.thenHint,
              maxLength: 200,
            ),
            const SizedBox(height: 4),
            if (_selectedTool != null)
              _QuickChips(
                suggestions:
                    FieldFixtures.toolThenSuggestions[_selectedTool] ??
                        (FieldFixtures.toolDefaultThen
                                .containsKey(_selectedTool)
                            ? [FieldFixtures.toolDefaultThen[_selectedTool]!]
                            : []),
                color: toolColor,
                onTap: (v) => setState(() => _thenCtrl.text = v),
              )
            else if (connected.isNotEmpty)
              _QuickChips(
                suggestions: [
                  for (final tool in connected)
                    ...FieldFixtures.toolThenSuggestions[tool] ??
                        (FieldFixtures.toolDefaultThen.containsKey(tool)
                            ? [FieldFixtures.toolDefaultThen[tool]!]
                            : []),
                ],
                color: colors.sky,
                onTap: (v) => setState(() => _thenCtrl.text = v),
              ),

            // ── Action mismatch warning (only for connected tools) ──
            if (_selectedTool != null && connected.contains(_selectedTool))
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
            const SizedBox(height: 10),
            ], // end if (!isUpload)
                ],
              ),
            ),
          ),

          // ══════════════════════════════════════════════════
          // FIXED FOOTER — approval toggle + create button
          // ══════════════════════════════════════════════════
          const SizedBox(height: 10),
          // Divider.
          Container(
            height: 1,
            color: colors.camel.withValues(alpha: 0.12),
          ),
          const SizedBox(height: 10),

          // ── Approval toggle ──
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Requires approval',
                      style: text.caption.copyWith(
                        color: colors.cream,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      'Ask before executing',
                      style: text.micro.copyWith(
                        color: colors.muted,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _requiresApproval,
                onChanged: (v) => setState(() => _requiresApproval = v),
                activeTrackColor: colors.sky.withValues(alpha: 0.5),
                thumbColor: WidgetStatePropertyAll(colors.sky),
              ),
            ],
          ),
          const SizedBox(height: 10),

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
    );
  }
}

/// A single tool selection chip with color from FieldFixtures.
class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.tool,
    required this.selected,
    required this.onTap,
    this.isConnected = true,
    this.locked = false,
  });

  final String tool;
  final bool selected;
  final bool isConnected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final chipColor = isConnected
        ? Color(FieldFixtures.toolColors[tool] ?? 0xFF888888)
        : const Color(0xFFF59E0B); // amber for disconnected
    final displayName = FieldFixtures.toolDisplayNames[tool] ?? tool;
    return GestureDetector(
      onTap: locked ? null : onTap,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayName,
              style: text.caption.copyWith(
                color: selected ? chipColor : colors.muted,
                fontSize: 11,
              ),
            ),
            if (locked) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.lock_outline,
                size: 10,
                color: chipColor.withValues(alpha: 0.6),
              ),
            ] else if (!isConnected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.link_off,
                size: 10,
                color: selected ? chipColor : colors.muted,
              ),
            ],
          ],
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

/// Dynamic auth fields for registry tools.
///
/// Renders fields based on what the backend/MCP server declares.
/// Each tool gets its own correct fields — no hardcoded single token.
class _AuthFieldsConnect extends ConsumerStatefulWidget {
  const _AuthFieldsConnect({
    required this.toolName,
    required this.selectedTool,
    required this.authFields,
    required this.onConnected,
  });

  final String toolName;
  final String selectedTool;

  /// List of field specs from backend: [{key, label, type, hint, help_url}].
  final List<Map<String, dynamic>> authFields;
  final VoidCallback onConnected;

  @override
  ConsumerState<_AuthFieldsConnect> createState() =>
      _AuthFieldsConnectState();
}

class _AuthFieldsConnectState extends ConsumerState<_AuthFieldsConnect> {
  final Map<String, TextEditingController> _controllers = {};
  bool _saving = false;
  bool _connected = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final field in widget.authFields) {
      final key = field['key'] as String? ?? '';
      if (key.isNotEmpty) {
        _controllers[key] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _allFilled {
    for (final field in widget.authFields) {
      final key = field['key'] as String? ?? '';
      final ctrl = _controllers[key];
      if (ctrl == null || ctrl.text.trim().isEmpty) return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_allFilled) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    // Build credentials map from all fields.
    final credentials = <String, String>{};
    for (final entry in _controllers.entries) {
      credentials[entry.key] = entry.value.text.trim();
    }

    final wallet =
        ref.read(authControllerProvider).user?.wallet ?? '';
    final success = await SkillService.instance.connectRegistryTool(
      toolName: widget.selectedTool,
      wallet: wallet,
      credentials: credentials,
      authType: 'multi_field',
    );

    if (mounted) {
      setState(() {
        _saving = false;
        if (success) {
          _connected = true;
          _error = null;
        } else {
          _error = 'Connection failed. Check your credentials.';
        }
      });
      if (success) {
        widget.onConnected();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    // ── Connected state — green banner ──
    if (_connected) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF34D399).withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(6),
          color: const Color(0xFF34D399).withValues(alpha: 0.06),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, size: 14,
                color: Color(0xFF34D399)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${widget.toolName} connected ✅',
                style: text.micro.copyWith(
                  color: const Color(0xFF34D399),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() {
                _connected = false;
                for (final c in _controllers.values) {
                  c.clear();
                }
              }),
              child: Text(
                'Disconnect',
                style: text.micro.copyWith(
                  color: const Color(0xFFEF4444),
                  fontSize: 9,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── Setup state — fields + connect button ──
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(6),
        color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──
          Text(
            '${widget.toolName} requires setup',
            style: text.micro.copyWith(
              color: const Color(0xFFF59E0B),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // ── Error message ──
          if (_error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 5),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _error!,
                style: text.micro.copyWith(
                  color: const Color(0xFFEF4444),
                  fontSize: 9,
                ),
              ),
            ),
          ],

          // ── Dynamic fields with steps ──
          ...widget.authFields.map((field) {
            final key = field['key'] as String? ?? '';
            final label = field['label'] as String? ?? key;
            final fieldType = field['type'] as String? ?? 'text';
            final hint = field['hint'] as String? ?? '';
            final helpUrl = (field['help_url'] as String?) ?? '';
            final steps = (field['steps'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
            final ctrl = _controllers[key];
            if (ctrl == null) return const SizedBox.shrink();

            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0F10).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: colors.camel.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Label ──
                  Row(
                    children: [
                      Icon(
                        fieldType == 'secret'
                            ? Icons.key_rounded
                            : Icons.badge_outlined,
                        size: 12,
                        color: const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        label,
                        style: text.caption.copyWith(
                          color: colors.cream,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  // ── Steps (always visible) ──
                  if (steps.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B)
                            .withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFFF59E0B)
                              .withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < steps.length; i++)
                            Padding(
                              padding: EdgeInsets.only(
                                  bottom:
                                      i < steps.length - 1 ? 4 : 0),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    margin: const EdgeInsets.only(
                                        right: 6, top: 1),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFF59E0B)
                                          .withValues(alpha: 0.15),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${i + 1}',
                                        style: text.micro.copyWith(
                                          color:
                                              const Color(0xFFF59E0B),
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      steps[i],
                                      style: text.micro.copyWith(
                                        color: colors.muted,
                                        fontSize: 9,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          // Help URL link at bottom of steps.
                          if (helpUrl.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () async {
                                final uri = Uri.tryParse(helpUrl);
                                if (uri != null) {
                                  await launchUrl(uri,
                                      mode: LaunchMode
                                          .externalApplication);
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.open_in_new,
                                      size: 9, color: colors.sky),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Open in browser',
                                    style: text.micro.copyWith(
                                      color: colors.sky,
                                      fontSize: 9,
                                      decoration:
                                          TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ] else if (helpUrl.isNotEmpty) ...[
                    // No steps but has help URL — show link.
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.tryParse(helpUrl);
                        if (uri != null) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_in_new,
                              size: 9, color: colors.sky),
                          const SizedBox(width: 3),
                          Text(
                            'How to get this',
                            style: text.micro.copyWith(
                              color: colors.sky,
                              fontSize: 9,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // ── Input field ──
                  TextField(
                    controller: ctrl,
                    obscureText: fieldType == 'secret',
                    enabled: !_saving,
                    style: text.caption.copyWith(
                      color: colors.text,
                      fontSize: 11,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText:
                          hint.isNotEmpty ? hint : 'Paste $label here',
                      hintStyle: text.caption.copyWith(
                        color: colors.quiet,
                        fontSize: 11,
                      ),
                      filled: true,
                      fillColor: const Color.fromRGBO(6, 3, 4, 0.66),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(
                            left: 8, right: 6),
                        child: Icon(
                          fieldType == 'secret'
                              ? Icons.lock_outline
                              : Icons.edit_outlined,
                          size: 14,
                          color: colors.quiet,
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: colors.camel.withValues(alpha: 0.24),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: colors.camel.withValues(alpha: 0.24),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                            color: const Color(0xFFF59E0B)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // ── Connect button ──
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _saving || !_allFilled ? null : _save,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _saving || !_allFilled
                      ? colors.muted.withValues(alpha: 0.3)
                      : const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Color(0xFF0D0F10),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.power_settings_new,
                              size: 13,
                              color: const Color(0xFF0D0F10),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Connect ${widget.toolName}',
                              style: text.micro.copyWith(
                                color: const Color(0xFF0D0F10),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}