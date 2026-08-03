/// Phase 0 · Foundation gate.
///
/// Kept as a living token sheet: it proves the ground, both type families, the
/// Design Kit assets and the sky-blue ink rule all still render. Phase 7 folds
/// it into the Field Catalog.
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../design/ground.dart';
import '../design/tokens.dart';
import '../design/typography.dart';

class FoundationGate extends StatelessWidget {
  const FoundationGate({super.key});

  @override
  Widget build(BuildContext context) {
    // The Field ground establishes the local ground for every descendant, so
    // sky-blue Actions take their ink from it.
    return KidunaGround(
      ground: Enamel.deepField,
      child: Container(
        color: Enamel.deepField,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(48, 44, 48, 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Masthead(),
                const SizedBox(height: 40),
                const _Section('Colour · eleven tokens'),
                const _Swatches(),
                const SizedBox(height: 36),
                const _Section('Clusters · six accents'),
                const _ClusterRow(),
                const SizedBox(height: 36),
                const _Section('Realm emblems · Design Kit v1.7'),
                const _EmblemRow(),
                const SizedBox(height: 36),
                const _Section('Icons · vector'),
                const _IconRow(),
                const SizedBox(height: 36),
                const _Section('Sky-blue Action · contextual ink'),
                const _ActionRow(),
                const SizedBox(height: 48),
                const _GateReport(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GateReport extends StatelessWidget {
  const _GateReport();

  static const _checks = [
    'Runs on Flutter web',
    'Field ground #0A0604',
    'Goudy Heavyface renders',
    'Avenir renders at three weights',
    'Design Kit raster assets resolve',
    'Vector icons resolve',
    'Sky-blue ink inherited from local ground',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Enamel.warmSurface,
        border: Border.all(color: Enamel.raisedUmber),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PHASE 0 GATE', style: Type.eyebrow),
          const SizedBox(height: 14),
          for (final check in _checks)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  Text('✦  ', style: Type.body.copyWith(color: Enamel.mint)),
                  Text(check, style: Type.body),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Masthead extends StatelessWidget {
  const _Masthead();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('KIDUNA STUDIO · ADVANCED ECOSYSTEM VIEW', style: Type.eyebrow),
        const SizedBox(height: 12),
        Text('Kinship Duna', style: Type.display),
        const SizedBox(height: 10),
        SizedBox(
          width: 560,
          child: Text(
            'Deep. Warm. Alive. The Field is not a graph — distance carries '
            'meaning, selection is inspection, and no curve is drawn without a '
            'relationship behind it.',
            style: Type.bodyQuiet,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(label.toUpperCase(), style: Type.eyebrow),
      );
}

class _Swatches extends StatelessWidget {
  const _Swatches();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final (name, color) in Enamel.all)
          SizedBox(
            width: 132,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(color: Enamel.raisedUmber),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 7),
                Text(name, style: Type.operational.copyWith(color: Enamel.text)),
                Text(
                  '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
                  style: Type.operational,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ClusterRow extends StatelessWidget {
  const _ClusterRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        for (final cluster in Cluster.values)
          Container(
            width: 210,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              // Cluster atmospheres are restrained halos, never hard
              // containers or ranking boundaries.
              gradient: RadialGradient(
                colors: [
                  cluster.accent.withValues(alpha: 0.20),
                  cluster.accent.withValues(alpha: 0.0),
                ],
              ),
              border: Border.all(color: cluster.accent.withValues(alpha: 0.35)),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cluster.name, style: Type.realmName),
                const SizedBox(height: 3),
                Text(
                  cluster.label.isEmpty
                      ? 'nested children · unlabelled'
                      : cluster.label,
                  style: Type.operational,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EmblemRow extends StatelessWidget {
  const _EmblemRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        for (final type in RealmType.values)
          SizedBox(
            width: 108,
            child: Column(
              children: [
                Image.asset(type.emblemAsset, width: 76, height: 76),
                const SizedBox(height: 8),
                Text(type.label, style: Type.realmName),
                Text(
                  type.geometry,
                  style: Type.operational,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _IconRow extends StatelessWidget {
  const _IconRow();

  static const _icons = [
    'agent',
    'alliance',
    'build',
    'discover',
    'enact',
    'govern',
    'kinship',
    'ledger',
    'magic',
    'member',
    'treasury',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 22,
      runSpacing: 18,
      children: [
        for (final name in _icons)
          SizedBox(
            width: 64,
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/icons/$name.svg',
                  width: 26,
                  height: 26,
                  colorFilter:
                      const ColorFilter.mode(Enamel.camel, BlendMode.srcIn),
                ),
                const SizedBox(height: 8),
                Text(name, style: Type.operational),
              ],
            ),
          ),
      ],
    );
  }
}

/// Demonstrates that sky-blue ink follows the local ground, not a fixed colour.
class _ActionRow extends StatelessWidget {
  const _ActionRow();

  static const _grounds = <(String, Color)>[
    ('Deep Field', Enamel.deepField),
    ('Warm surface', Enamel.warmSurface),
    ('Raised umber', Enamel.raisedUmber),
    ('Raised warm', Enamel.raisedWarmSurface),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        for (final (name, ground) in _grounds)
          KidunaGround(
            ground: ground,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: ground,
              child: Column(
                children: [
                  const SkyAction(label: 'Form a Realm'),
                  const SizedBox(height: 9),
                  Text(name, style: Type.operational),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
