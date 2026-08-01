import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../controllers/field_controller.dart';
import 'capacity_header.dart';
import 'field_inputs.dart';
import 'skill_create_form.dart';

/// Skills capacity workspace — file list of skill markdown files, upload, and
/// "Create a new Skill with Ki" action.
class SkillsPanel extends ConsumerStatefulWidget {
  const SkillsPanel({super.key, required this.realmName});

  final String realmName;

  @override
  ConsumerState<SkillsPanel> createState() => _SkillsPanelState();
}

class _SkillsPanelState extends ConsumerState<SkillsPanel> {
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(fieldControllerProvider.notifier).fetchSkills(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final skills = ref.watch(fieldControllerProvider.select((s) => s.skills));
    return Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          CapacityHeader(
            eyebrow: l10n.skills,
            heading: l10n.whatRealmKnowsHowToDo(widget.realmName),
            status: l10n.nSkillsAvailable(skills.length),
          ),
          const SizedBox(height: 14),
          if (skills.isEmpty && !_showForm)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                l10n.noSkillsCreated,
                style: context.kidunaText.caption.copyWith(
                  color: context.kiduna.muted,
                ),
              ),
            )
          else
            for (final skill in skills) ...[
              AssetRow(
                name: skill.skillFilePath ?? '${skill.name}.md',
                detail: l10n.skillDetail,
                actions: [
                  CapacityActionButton(label: l10n.edit, onPressed: () {}),
                  CapacityActionButton(
                    label: l10n.remove,
                    onPressed: () => ref
                        .read(fieldControllerProvider.notifier)
                        .removeSkill(skill.id),
                  ),
                  CapacityActionButton(label: l10n.download, onPressed: () {}),
                ],
              ),
              const SizedBox(height: 7),
            ],
          if (_showForm) ...[
            SkillCreateForm(onClose: () => setState(() => _showForm = false)),
            const SizedBox(height: 14),
          ],
          if (!_showForm) ...[
            const SizedBox(height: 7),
            _UploadSkillsButton(onPressed: () {}),
            const SizedBox(height: 14),
            FieldPrimaryButton(
              label: l10n.createNewSkillWithKi,
              onPressed: () => setState(() => _showForm = true),
            ),
          ],
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          textStyle: context.kidunaText.micro.copyWith(fontSize: 9),
        ),
        child: Text(l10n.uploadSkills),
      ),
    );
  }
}
