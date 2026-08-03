/// The inspection alert.
///
/// This stands in for the Inspect Realm panel, which this build does not
/// implement. It is **inspection, not entry**: it reports what a Realm is and
/// where the viewer stands in it, and offers exactly one control — Gravity,
/// which changes presentation and nothing else.
///
/// There is deliberately no "Enter" action. Entry is a consequential Action
/// with its own authority, confirmation and recovery boundaries.
library;

import 'package:flutter/material.dart';

import '../design/ground.dart';
import '../design/tokens.dart';
import '../design/typography.dart';
import 'placement.dart';

Future<void> showInspectAlert(
  BuildContext context, {
  required Placement placement,
  required Gravity gravity,
  required ValueChanged<Gravity> onGravity,
  VoidCallback? onDismissed,
}) async {
  await showDialog<void>(
    context: context,
    // A light scrim: the Field stays legible behind, so a Gravity change can
    // be watched as it Gathers.
    barrierColor: Enamel.deepEspresso.withValues(alpha: 0.42),
    builder: (context) => _InspectAlert(
      placement: placement,
      gravity: gravity,
      onGravity: onGravity,
    ),
  );
  onDismissed?.call();
}

class _InspectAlert extends StatefulWidget {
  const _InspectAlert({
    required this.placement,
    required this.gravity,
    required this.onGravity,
  });

  final Placement placement;
  final Gravity gravity;
  final ValueChanged<Gravity> onGravity;

  @override
  State<_InspectAlert> createState() => _InspectAlertState();
}

class _InspectAlertState extends State<_InspectAlert> {
  late Gravity _gravity = widget.gravity;

  @override
  Widget build(BuildContext context) {
    final realm = widget.placement.realm;
    final accent = widget.placement.cluster.accent;

    return KidunaGround(
      ground: Enamel.warmSurface,
      child: Dialog(
        backgroundColor: Enamel.warmSurface,
        surfaceTintColor: Enamel.warmSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
          side: BorderSide(color: accent.withValues(alpha: 0.42)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  realm.typeName.toUpperCase(),
                  style: Type.eyebrow.copyWith(color: accent),
                ),
                const SizedBox(height: 8),
                Text(realm.name, style: Type.heading),

                if (realm.fixture) ...[
                  const SizedBox(height: 12),
                  _ProposedNotice(accent: accent),
                ],

                if (realm.purpose.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(realm.purpose, style: Type.body),
                ],

                const SizedBox(height: 20),
                _Fact('Your role', widget.placement.role.label),
                _Fact(
                  'Ally',
                  widget.placement.ally?.name ?? 'None stationed',
                ),
                _Fact('Cluster', _clusterLabel(widget.placement)),
                _Fact('Distance', widget.placement.band.name),
                if (realm.childIds.isNotEmpty)
                  _Fact('Contains', '${realm.childIds.length} nested Realms'),

                const SizedBox(height: 22),
                _GravityControl(
                  value: _gravity,
                  accent: accent,
                  onChanged: (g) {
                    setState(() => _gravity = g);
                    widget.onGravity(g);
                  },
                ),

                if (realm.reason != null) ...[
                  const SizedBox(height: 18),
                  Text(realm.reason!, style: Type.bodyQuiet),
                ],

                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Selection is inspection. Nothing here enters, joins, '
                        'or grants anything.',
                        style: Type.operational,
                      ),
                    ),
                    const SizedBox(width: 14),
                    SkyAction(
                      label: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _clusterLabel(Placement p) =>
      p.cluster.label.isEmpty ? p.cluster.id : p.cluster.label;
}

/// A `fixture: true` Realm is a *proposed* entity that does not yet exist. It
/// must never be presented as real.
class _ProposedNotice extends StatelessWidget {
  const _ProposedNotice({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(color: Enamel.sunGold.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          'PROPOSED · this entity does not yet exist',
          style: Type.eyebrow.copyWith(color: Enamel.sunGold),
        ),
      );
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 108,
              child: Text(label.toUpperCase(), style: Type.eyebrow),
            ),
            Expanded(child: Text(value, style: Type.body)),
          ],
        ),
      );
}

/// Gravity is a Source-controlled 1–5 relevance setting.
///
/// > Gravity changes presentation, not authority or truth.
///
/// It is both draggable and directly clickable, per the interaction spec.
class _GravityControl extends StatelessWidget {
  const _GravityControl({
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  final Gravity value;
  final Color accent;
  final ValueChanged<Gravity> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('GRAVITY', style: Type.eyebrow),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final level in Gravity.values)
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(level),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: level.level <= value.level
                            ? accent
                            : Enamel.raisedUmber,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: accent,
            inactiveTrackColor: Enamel.raisedUmber,
            thumbColor: Enamel.cream,
            overlayColor: accent.withValues(alpha: 0.14),
            trackHeight: 2,
          ),
          child: Slider(
            value: value.level.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (v) => onChanged(Gravity.of(v.round())),
          ),
        ),
        Text('${value.level} · ${value.label}', style: Type.realmName),
        const SizedBox(height: 3),
        Text(value.meaning, style: Type.operational),
      ],
    );
  }
}
