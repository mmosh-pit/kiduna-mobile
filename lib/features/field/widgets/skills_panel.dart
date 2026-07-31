import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import 'capacity_header.dart';
import 'field_inputs.dart';

/// Skills capacity workspace — file list of skill markdown files, upload, and
/// "Create a new Skill with Ki" action.
class SkillsPanel extends StatefulWidget {
  const SkillsPanel({super.key, required this.realmName});

  final String realmName;

  @override
  State<SkillsPanel> createState() => _SkillsPanelState();
}

class _SkillsPanelState extends State<SkillsPanel> {
  final List<String> _skills = [
    'welcome-a-member.md',
    'form-a-realm.md',
    'inspect-authority.md',
  ];

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
            eyebrow: l10n.skills,
            heading: l10n.whatRealmKnowsHowToDo(widget.realmName),
            status: l10n.nSkillsAvailable(_skills.length),
          ),
          const SizedBox(height: 14),
          for (final skill in _skills) ...[
            AssetRow(
              name: skill,
              detail: 'Markdown · Realm scope · Version 1.0',
              actions: [
                CapacityActionButton(label: l10n.edit, onPressed: () {}),
                CapacityActionButton(
                  label: l10n.remove,
                  onPressed: () => setState(() => _skills.remove(skill)),
                ),
              ],
            ),
            const SizedBox(height: 7),
          ],
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerLeft,
            child: CapacityActionButton(
              label: l10n.uploadSkills,
              onPressed: () {},
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: FieldPrimaryButton(
              label: l10n.createNewSkillWithKi,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
