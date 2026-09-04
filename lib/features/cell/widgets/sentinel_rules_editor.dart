import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/sentinel_rules_model.dart';
import '../../../data/services/realm_service.dart';

const _gold = Color(0xFFC8A24B);

Future<SentinelRules?> showSentinelRulesEditor({
  required BuildContext context,
  required String realmId,
  required SentinelRules current,
}) {
  return showModalBottomSheet<SentinelRules>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SentinelRulesEditor(realmId: realmId, current: current),
  );
}

class _SentinelRulesEditor extends StatefulWidget {
  const _SentinelRulesEditor({required this.realmId, required this.current});
  final String realmId;
  final SentinelRules current;

  @override
  State<_SentinelRulesEditor> createState() => _SentinelRulesEditorState();
}

class _SentinelRulesEditorState extends State<_SentinelRulesEditor> {
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _principleCtrl;
  late List<String> _principles;

  late final TextEditingController _startingStackCtrl;
  late final TextEditingController _maxBetCtrl;
  late final TextEditingController _minBetCtrl;
  late final TextEditingController _maxRaisesCtrl;
  late final TextEditingController _turnTimeoutCtrl;
  late final TextEditingController _maxPlayersCtrl;

  late bool? _enablePowerCards;
  late bool? _enableItems;
  late bool? _enableJokers;
  late bool? _enableSuddenDeath;
  late bool? _timedLevels;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.current;
    _descriptionCtrl = TextEditingController(text: r.description ?? '');
    _principleCtrl = TextEditingController();
    _principles = List<String>.from(r.principles);

    _startingStackCtrl = TextEditingController(
      text: r.startingStack?.toString() ?? '',
    );
    _maxBetCtrl = TextEditingController(
      text: r.maxBetAmount?.toString() ?? '',
    );
    _minBetCtrl = TextEditingController(
      text: r.minBetAmount?.toString() ?? '',
    );
    _maxRaisesCtrl = TextEditingController(
      text: r.maxRaisesPerRound?.toString() ?? '',
    );
    _turnTimeoutCtrl = TextEditingController(
      text: r.turnTimeoutSeconds?.toString() ?? '',
    );
    _maxPlayersCtrl = TextEditingController(
      text: r.maxPlayersPerTable?.toString() ?? '',
    );

    _enablePowerCards = r.enablePowerCards;
    _enableItems = r.enableItems;
    _enableJokers = r.enableJokers;
    _enableSuddenDeath = r.enableSuddenDeath;
    _timedLevels = r.timedLevels;
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _principleCtrl.dispose();
    _startingStackCtrl.dispose();
    _maxBetCtrl.dispose();
    _minBetCtrl.dispose();
    _maxRaisesCtrl.dispose();
    _turnTimeoutCtrl.dispose();
    _maxPlayersCtrl.dispose();
    super.dispose();
  }

  int? _parseInt(TextEditingController ctrl) {
    final text = ctrl.text.trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  SentinelRules _buildRules() {
    return SentinelRules(
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      principles: _principles,
      startingStack: _parseInt(_startingStackCtrl),
      maxBetAmount: _parseInt(_maxBetCtrl),
      minBetAmount: _parseInt(_minBetCtrl),
      maxRaisesPerRound: _parseInt(_maxRaisesCtrl),
      turnTimeoutSeconds: _parseInt(_turnTimeoutCtrl),
      maxPlayersPerTable: _parseInt(_maxPlayersCtrl),
      enablePowerCards: _enablePowerCards,
      enableItems: _enableItems,
      enableJokers: _enableJokers,
      enableSuddenDeath: _enableSuddenDeath,
      timedLevels: _timedLevels,
      bannedPowerCards: widget.current.bannedPowerCards,
      bannedCourtMembers: widget.current.bannedCourtMembers,
      bannedItems: widget.current.bannedItems,
      allowedClasses: widget.current.allowedClasses,
      maxHoleCards: widget.current.maxHoleCards,
      compChipsPerPlayer: widget.current.compChipsPerPlayer,
      powerDeckSize: widget.current.powerDeckSize,
      customChipSellValue: widget.current.customChipSellValue,
      levelDurationSeconds: widget.current.levelDurationSeconds,
      customAnteLevels: widget.current.customAnteLevels,
      enableHeatingUp: widget.current.enableHeatingUp,
      enableTilt: widget.current.enableTilt,
      enableStealth: widget.current.enableStealth,
      allowFoldOnly: widget.current.allowFoldOnly,
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final rules = _buildRules();
      await RealmService.instance.updateSentinelRules(
        id: widget.realmId,
        rules: rules,
      );
      if (!mounted) return;
      Navigator.of(context).pop(rules);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Failed to save rules')),
      );
    } catch (e) {
      AppLogger.error('Failed to save sentinel rules', tag: 'SentinelEditor', error: e);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save rules. Please try again.')),
      );
    }
  }

  void _addPrinciple() {
    final text = _principleCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _principles.add(text);
      _principleCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: colors.deep,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHandle(colors: colors),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label(text: 'Description', colors: colors),
                  const SizedBox(height: 4),
                  _Field(
                    controller: _descriptionCtrl,
                    hint: 'Describe the rules for this cell',
                    colors: colors,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _Label(text: 'Principles', colors: colors),
                  const SizedBox(height: 4),
                  for (int i = 0; i < _principles.length; i++) ...[
                    _PrincipleItem(
                      text: _principles[i],
                      colors: colors,
                      onRemove: () => setState(() => _principles.removeAt(i)),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _Field(
                          controller: _principleCtrl,
                          hint: 'Add a principle',
                          colors: colors,
                          onSubmitted: (_) => _addPrinciple(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _addPrinciple,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add, color: _gold, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _Label(text: 'Constraints', colors: colors),
                  const SizedBox(height: 8),
                  _NumberRow(
                    label: 'Starting Stack',
                    controller: _startingStackCtrl,
                    colors: colors,
                  ),
                  const SizedBox(height: 8),
                  _NumberRow(
                    label: 'Max Bet',
                    controller: _maxBetCtrl,
                    colors: colors,
                  ),
                  const SizedBox(height: 8),
                  _NumberRow(
                    label: 'Min Bet',
                    controller: _minBetCtrl,
                    colors: colors,
                  ),
                  const SizedBox(height: 8),
                  _NumberRow(
                    label: 'Max Raises / Round',
                    controller: _maxRaisesCtrl,
                    colors: colors,
                  ),
                  const SizedBox(height: 8),
                  _NumberRow(
                    label: 'Turn Timeout (s)',
                    controller: _turnTimeoutCtrl,
                    colors: colors,
                  ),
                  const SizedBox(height: 8),
                  _NumberRow(
                    label: 'Max Players',
                    controller: _maxPlayersCtrl,
                    colors: colors,
                  ),
                  const SizedBox(height: 20),
                  _Label(text: 'Guardrails', colors: colors),
                  const SizedBox(height: 8),
                  _ToggleRow(
                    label: 'Power Cards',
                    value: _enablePowerCards,
                    colors: colors,
                    onChanged: (v) => setState(() => _enablePowerCards = v),
                  ),
                  _ToggleRow(
                    label: 'Items',
                    value: _enableItems,
                    colors: colors,
                    onChanged: (v) => setState(() => _enableItems = v),
                  ),
                  _ToggleRow(
                    label: 'Jokers',
                    value: _enableJokers,
                    colors: colors,
                    onChanged: (v) => setState(() => _enableJokers = v),
                  ),
                  _ToggleRow(
                    label: 'Sudden Death',
                    value: _enableSuddenDeath,
                    colors: colors,
                    onChanged: (v) => setState(() => _enableSuddenDeath = v),
                  ),
                  _ToggleRow(
                    label: 'Timed Levels',
                    value: _timedLevels,
                    colors: colors,
                    onChanged: (v) => setState(() => _timedLevels = v),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          _SaveBar(colors: colors, saving: _saving, onSave: _save),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.colors});
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: (colors.muted as Color).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text, required this.colors});
  final String text;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _gold.withValues(alpha: 0.8),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.colors,
    this.maxLines = 1,
    this.onSubmitted,
    this.keyboardType,
    this.inputFormatters,
  });
  final TextEditingController controller;
  final String hint;
  final dynamic colors;
  final int maxLines;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(fontSize: 13, color: colors.cream as Color),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: (colors.muted as Color).withValues(alpha: 0.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: (colors.camel as Color).withValues(alpha: 0.25),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: (colors.camel as Color).withValues(alpha: 0.25),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _gold),
        ),
        filled: true,
        fillColor: colors.surface as Color,
      ),
    );
  }
}

class _PrincipleItem extends StatelessWidget {
  const _PrincipleItem({
    required this.text,
    required this.colors,
    required this.onRemove,
  });
  final String text;
  final dynamic colors;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface as Color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: (colors.camel as Color).withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 13, color: _gold.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: colors.cream as Color),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14,
              color: (colors.muted as Color).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberRow extends StatelessWidget {
  const _NumberRow({
    required this.label,
    required this.controller,
    required this.colors,
  });
  final String label;
  final TextEditingController controller;
  final dynamic colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: colors.cream as Color),
          ),
        ),
        Expanded(
          child: _Field(
            controller: controller,
            hint: 'Default',
            colors: colors,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.colors,
    required this.onChanged,
  });
  final String label;
  final bool? value;
  final dynamic colors;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: colors.cream as Color),
            ),
          ),
          _TriStateToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _TriStateToggle extends StatelessWidget {
  const _TriStateToggle({required this.value, required this.onChanged});
  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToggleOption(
          label: 'Default',
          isActive: value == null,
          onTap: () => onChanged(null),
        ),
        const SizedBox(width: 4),
        _ToggleOption(
          label: 'On',
          isActive: value == true,
          onTap: () => onChanged(true),
          activeColor: const Color(0xFF22C55E),
        ),
        const SizedBox(width: 4),
        _ToggleOption(
          label: 'Off',
          isActive: value == false,
          onTap: () => onChanged(false),
          activeColor: const Color(0xFFE57373),
        ),
      ],
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.activeColor = _gold,
  });
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.20) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? activeColor : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color: isActive ? activeColor : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.colors,
    required this.saving,
    required this.onSave,
  });
  final dynamic colors;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: (colors.camel as Color).withValues(alpha: 0.16),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: saving ? null : onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: _gold,
            foregroundColor: const Color(0xFF1A1A16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF1A1A16),
                  ),
                )
              : const Text(
                  'Save Rules',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
        ),
      ),
    );
  }
}
