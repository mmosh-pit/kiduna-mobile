import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import 'capacity_header.dart';
import 'field_inputs.dart';

/// Automations capacity workspace — automation rows with checkboxes, trigger
/// inputs, and "Prepare selected Automations" action.
class AutomationsPanel extends StatefulWidget {
  const AutomationsPanel({super.key, required this.realmName});

  final String realmName;

  @override
  State<AutomationsPanel> createState() => _AutomationsPanelState();
}

class _AutomationsPanelState extends State<AutomationsPanel> {
  static const List<(String, String)> _automations = [
    ('Welcome a new member', 'When their private handshake is confirmed'),
    ('Prepare a Realm-change brief', 'When a published Realm Record changes'),
    ('Review dormant invitations', 'Every Monday at 9:00 AM'),
  ];

  final Set<String> _selected = {};
  late final Map<String, TextEditingController> _triggers;

  @override
  void initState() {
    super.initState();
    _triggers = {
      for (final (name, trigger) in _automations)
        name: TextEditingController(text: trigger),
    };
  }

  @override
  void dispose() {
    for (final c in _triggers.values) {
      c.dispose();
    }
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
            eyebrow: l10n.automations,
            heading: l10n.whatKeepsWorkingFor(widget.realmName),
            status: l10n.nSelectedDraft(_selected.length),
          ),
          const SizedBox(height: 14),
          for (final (name, _) in _automations) ...[
            _AutomationRow(
              name: name,
              selected: _selected.contains(name),
              triggerController: _triggers[name]!,
              onToggle: (checked) => setState(() {
                if (checked) {
                  _selected.add(name);
                } else {
                  _selected.remove(name);
                }
              }),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 6),
          FieldPrimaryButton(
            label: l10n.prepareSelectedAutomations,
            onPressed: _selected.isNotEmpty ? () {} : null,
          ),
        ],
      ),
    );
  }
}

class _AutomationRow extends StatelessWidget {
  const _AutomationRow({
    required this.name,
    required this.selected,
    required this.triggerController,
    required this.onToggle,
  });

  final String name;
  final bool selected;
  final TextEditingController triggerController;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(6, 3, 4, 0.36),
        border: Border.all(color: colors.camel.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: Checkbox(
                    value: selected,
                    onChanged: (v) => onToggle(v ?? false),
                    activeColor: colors.sky,
                    side: BorderSide(color: colors.sky.withValues(alpha: 0.5)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: text.label.copyWith(
                          color: colors.cream,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.stopWhenAuthorityExpires,
                        style: text.micro.copyWith(color: colors.quiet),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.trigger,
                  style: text.micro.copyWith(color: colors.muted),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: triggerController,
                  style: text.caption.copyWith(color: colors.text, height: 1.4),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: const Color.fromRGBO(6, 3, 4, 0.66),
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
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(color: colors.sky),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
