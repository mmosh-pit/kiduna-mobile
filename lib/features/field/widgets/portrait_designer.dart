import 'package:flutter/material.dart';

import '../../../config/assets.dart';
import '../../../core/extensions/context_extensions.dart';
import 'field_inputs.dart';

/// Which portrait is being designed.
enum PortraitKind { ally, realm }

typedef _Option = ({String id, String label});

/// Describe-and-choose flow for an Ally or Realm Portrait. Compact: describe,
/// generate possibilities, choose one; an Ally preview shows the four States.
class PortraitDesigner extends StatefulWidget {
  const PortraitDesigner({super.key, required this.kind});

  final PortraitKind kind;

  @override
  State<PortraitDesigner> createState() => _PortraitDesignerState();
}

class _PortraitDesignerState extends State<PortraitDesigner> {
  final TextEditingController _prompt = TextEditingController();
  bool _generated = false;
  String? _selected;

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  List<_Option> _options(BuildContext context) {
    final l10n = context.l10n;
    if (widget.kind == PortraitKind.ally) {
      return [
        (id: '01', label: l10n.warmConstellation),
        (id: '04', label: l10n.celestialGuide),
        (id: '05', label: l10n.deepFieldCompanion),
      ];
    }
    return [
      (id: 'grove', label: l10n.livingGrove),
      (id: 'bridge', label: l10n.radiantBridge),
      (id: 'beacon', label: l10n.celestialBeacon),
    ];
  }

  String _image(String id) => widget.kind == PortraitKind.ally
      ? AppAssets.allyPortrait(id, 'open')
      : AppAssets.organizationCrest(id);

  @override
  Widget build(BuildContext context) {
    final options = _options(context);
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          FieldTextInput(
            label: context.l10n.portraitDirection,
            controller: _prompt,
            hint: context.l10n.ancientWarmAlertCelestialEnamelHint,
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          FieldPrimaryButton(
            label: context.l10n.createPossiblePortraits,
            onPressed: () => setState(() => _generated = true),
          ),
          if (_generated) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final option in options)
                  _PortraitOption(
                    label: option.label,
                    image: _image(option.id),
                    selected: _selected == option.id,
                    onTap: () => setState(() => _selected = option.id),
                  ),
              ],
            ),
          ],
          if (widget.kind == PortraitKind.ally && _selected != null) ...[
            const SizedBox(height: 16),
            _AllyStates(persona: _selected!),
          ],
        ],
      ),
    );
  }
}

class _PortraitOption extends StatelessWidget {
  const _PortraitOption({
    required this.label,
    required this.image,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String image;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Semantics(
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.metrics.radiusMd),
                border: Border.all(
                  color: selected
                      ? colors.sky
                      : colors.camel.withValues(alpha: 0.3),
                  width: selected ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(context.metrics.radiusMd),
                child: Image.asset(
                  image,
                  width: 92,
                  height: 92,
                  fit: BoxFit.cover,
                  semanticLabel: label,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: context.kidunaText.micro.copyWith(color: colors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllyStates extends StatelessWidget {
  const _AllyStates({required this.persona});

  final String persona;

  static const List<String> _states = [
    'focused',
    'dreaming',
    'engaged',
    'open',
  ];

  static String _stateLabel(String state, BuildContext context) {
    final l10n = context.l10n;
    switch (state) {
      case 'focused':
        return l10n.focused;
      case 'dreaming':
        return l10n.dreaming;
      case 'engaged':
        return l10n.engaged;
      case 'open':
        return l10n.openState;
      default:
        return state;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final state in _states)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(context.metrics.radiusMd),
                child: Image.asset(
                  AppAssets.allyPortrait(persona, state),
                  width: 66,
                  height: 66,
                  fit: BoxFit.cover,
                  semanticLabel: state,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _stateLabel(state, context),
                style: context.kidunaText.micro.copyWith(
                  color: context.kiduna.quiet,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
