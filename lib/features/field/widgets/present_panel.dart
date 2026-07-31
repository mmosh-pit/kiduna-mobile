import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../controllers/field_controller.dart';
import '../data/field_fixtures.dart';
import 'field_inputs.dart';

/// The Present working panel: edit the current Realm's name, type, purpose,
/// and portrait presentation — matching the prototype's PresentationPanel.
class PresentPanel extends ConsumerStatefulWidget {
  const PresentPanel({super.key});

  @override
  ConsumerState<PresentPanel> createState() => _PresentPanelState();
}

class _PresentPanelState extends ConsumerState<PresentPanel> {
  late TextEditingController _name;
  late TextEditingController _purpose;
  late String _type;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final realm = ref.read(fieldControllerProvider).currentRealm;
      _name = TextEditingController(text: realm.name);
      _purpose = TextEditingController(text: _realmPurpose());
      _type = realm.type;
      _initialized = true;
    }
  }

  String _realmPurpose() {
    final purpose = FieldFixtures.facts
        .where((f) => f.label == 'Purpose')
        .map((f) => f.value)
        .firstOrNull;
    return purpose ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _purpose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FieldTextInput(
                  label: l10n.presentName,
                  controller: _name,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FieldDropdown(
                  label: l10n.typeLabel,
                  value: _type,
                  options: _presentTypes,
                  onChanged: (value) => setState(() => _type = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FieldTextInput(
            label: l10n.purpose,
            controller: _purpose,
            hint: l10n.presentPurposeHint(_name.text),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.gold.withValues(alpha: 0.05),
                  colors.sky.withValues(alpha: 0.035),
                ],
              ),
              border: Border.all(color: colors.gold.withValues(alpha: 0.24)),
              borderRadius: BorderRadius.circular(context.metrics.radiusPanel),
            ),
            child: Row(
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.gold.withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.gold.withValues(alpha: 0.1),
                        blurRadius: 24,
                      ),
                    ],
                    image: DecorationImage(
                      image: ResizeImage(
                        AssetImage(
                          ref
                              .read(fieldControllerProvider)
                              .currentRealm
                              .emblemAsset,
                        ),
                        width: (74 * MediaQuery.devicePixelRatioOf(context))
                            .round(),
                        height: (74 * MediaQuery.devicePixelRatioOf(context))
                            .round(),
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.realmPortrait,
                        style: text.h5.copyWith(
                          color: colors.cream,
                          fontSize: 17,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        l10n.presentPortraitDescription(_type),
                        style: text.micro.copyWith(
                          color: colors.muted,
                          fontSize: 9,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    foregroundColor: colors.skyButtonInk,
                    backgroundColor: colors.sky,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: Text(
                    l10n.change,
                    style: text.label.copyWith(
                      color: colors.skyButtonInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: FieldPrimaryButton(
              label: l10n.savePresentation,
              onPressed: () {
                ref
                    .read(fieldControllerProvider.notifier)
                    .savePresentation(name: _name.text.trim(), type: _type);
              },
            ),
          ),
        ],
      ),
    );
  }

  static const List<String> _presentTypes = [
    'Ecosystem',
    'Organization',
    'Alliance',
    'Community',
    'Program',
    'Project',
    'Relationship',
    'Institution',
    'Concept',
  ];
}
