import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import 'capacity_header.dart';
import 'field_inputs.dart';

/// Presence capacity workspace — system instructions editor with reset,
/// download, and "Develop a new Presence with Ki" action.
class PresenceCapacityPanel extends StatefulWidget {
  const PresenceCapacityPanel({super.key, required this.realmName});

  final String realmName;

  @override
  State<PresenceCapacityPanel> createState() => _PresenceCapacityPanelState();
}

class _PresenceCapacityPanelState extends State<PresenceCapacityPanel> {
  late final TextEditingController _instructions;
  late final String _defaultPresence;
  String _status = 'Inherited foundation · locally editable';

  @override
  void initState() {
    super.initState();
    _defaultPresence =
        "Act in service of ${widget.realmName}'s purpose. Preserve human "
        'direction, explain consequential choices, and never infer private '
        'intent.';
    _instructions = TextEditingController(text: _defaultPresence);
  }

  @override
  void dispose() {
    _instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CapacityHeader(
            eyebrow: l10n.presence,
            heading: l10n.howRealmBehaves(widget.realmName),
            status: _status,
          ),
          const SizedBox(height: 14),
          Text(
            l10n.currentSystemInstructions,
            style: text.micro.copyWith(color: colors.cream),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _instructions,
            maxLines: 6,
            onChanged: (_) =>
                setState(() => _status = 'Local draft · not published'),
            style: text.caption.copyWith(color: colors.text, height: 1.4),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color.fromRGBO(6, 3, 4, 0.66),
              contentPadding: const EdgeInsets.all(9),
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
          const SizedBox(height: 10),
          Text(
            l10n.presenceRequired,
            style: text.micro.copyWith(color: colors.quiet),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              CapacityActionButton(
                label: l10n.resetToDefault,
                onPressed: () => setState(() {
                  _instructions.text = _defaultPresence;
                  _status = 'Reset to default';
                }),
              ),
              CapacityActionButton(label: l10n.download, onPressed: () {}),
              CapacityActionButton(
                label: l10n.openInGoogleDocs,
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 14),
          FieldPrimaryButton(
            label: l10n.developNewPresenceWithKi,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
