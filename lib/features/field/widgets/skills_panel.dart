import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/file_download.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../controllers/field_controller.dart';
import 'capacity_header.dart';
import 'field_inputs.dart';

/// Skills capacity workspace — skill list with edit, remove, download,
/// pause/resume. The creation form opens as a separate [FieldPanel] — see
/// [FieldWorkingPanels].
class SkillsPanel extends ConsumerStatefulWidget {
  const SkillsPanel({super.key, required this.realmName});

  final String realmName;

  @override
  ConsumerState<SkillsPanel> createState() => _SkillsPanelState();
}

class _SkillsPanelState extends ConsumerState<SkillsPanel> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(fieldControllerProvider.notifier).fetchSkills();
      ref.read(fieldControllerProvider.notifier).fetchSavedTools();
      ref.read(fieldControllerProvider.notifier).fetchAvailableTools(
            force: true,
          );
    });
  }

  Future<void> _downloadSkill(
    BuildContext context,
    String name,
    String? content,
  ) async {
    if (content == null || content.isEmpty) {
      AppLogger.warning(
        'No content to download for skill: $name',
        tag: 'SkillsPanel',
      );
      return;
    }
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final message = await FileDownload.downloadMarkdown(
      fileName: '$slug.md',
      content: content,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }
  }

  Future<void> _confirmRemove(
    BuildContext context,
    String skillId,
    String skillName,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Remove Skill',
      message:
          'This will permanently delete "$skillName". This action cannot be undone.',
      confirmLabel: 'Remove',
      isDestructive: true,
    );
    if (confirmed == true && context.mounted) {
      ref.read(fieldControllerProvider.notifier).removeSkill(skillId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = ref.read(fieldControllerProvider.notifier);
    final state = ref.watch(fieldControllerProvider);
    final skills = state.skills;
    final loading = state.skillsLoading;

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
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF03CCD9),
                  ),
                ),
              ),
            )
          else if (skills.isEmpty)
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
                name: skill.name,
                detail: '${skill.triggerType.name} · ${skill.status}',
                actions: [
                  CapacityActionButton(
                    label: l10n.edit,
                    onPressed: () => controller.editSkill(skill.id),
                  ),
                  CapacityActionButton(
                    label: l10n.remove,
                    onPressed: () =>
                        _confirmRemove(context, skill.id, skill.name),
                  ),
                  CapacityActionButton(
                    label: l10n.download,
                    onPressed: () =>
                        _downloadSkill(context, skill.name, skill.skillContent),
                  ),
                  CapacityActionButton(
                    label: skill.status == 'active' ? 'Pause' : 'Resume',
                    onPressed: () {
                      if (skill.status == 'active') {
                        controller.pauseSkill(skill.id);
                      } else {
                        controller.resumeSkill(skill.id);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 7),
            ],
          const SizedBox(height: 14),
          FieldPrimaryButton(
            label: l10n.createNewSkillWithKi,
            onPressed: controller.openSkillForm,
          ),
        ],
      ),
    );
  }
}