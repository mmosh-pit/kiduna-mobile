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
                CapacityActionButton(
                  label: l10n.download,
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 7),
          ],
          const SizedBox(height: 7),
          _UploadSkillsButton(onPressed: () {}),
          const SizedBox(height: 14),
          FieldPrimaryButton(
            label: l10n.createNewSkillWithKi,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

/// CSS `.secondaryAction` — min-height 31, padding 0 11, sky text, sky@4% bg,
/// sky@28% border, radius 5, font-size 9.
class _UploadSkillsButton extends StatelessWidget {
  const _UploadSkillsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final l10n = context.l10n;
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 31),
          padding: const EdgeInsets.symmetric(horizontal: 11),
          foregroundColor: colors.sky,
          backgroundColor: colors.sky.withValues(alpha: 0.04),
          side: BorderSide(color: colors.sky.withValues(alpha: 0.28)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          textStyle: context.kidunaText.micro.copyWith(fontSize: 9),
        ),
        child: Text(l10n.uploadSkills),
      ),
    );
  }
}
