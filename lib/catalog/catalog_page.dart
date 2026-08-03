/// The Field Catalog — `?view=catalog`.
///
/// Its gate: **a developer who has never seen Kiduna can open this page and
/// correctly name every element.** A visual system is learned by scrubbing it,
/// not by reading about it, so every specimen is live and labelled.
///
/// The specimens are drawn by the same code that draws the Field. A catalogue
/// that reimplements its subject documents a fiction.
library;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../design/ground.dart';
import '../design/tokens.dart';
import 'geometry_sheet.dart';
import '../design/typography.dart';
import '../field/render/motion.dart';
import 'catalog_game.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final CatalogGame _game = CatalogGame();
  bool _reduced = false;

  @override
  Widget build(BuildContext context) {
    _game.motion.reduced = _reduced;

    return KidunaGround(
      ground: Enamel.deepField,
      child: Scaffold(
        backgroundColor: Enamel.deepField,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Masthead(
                  reduced: _reduced,
                  onReduced: (v) => setState(() => _reduced = v),
                  onReplay: _game.replayEntry,
                ),
                SizedBox(
                  height: CatalogGame.boardHeight,
                  child: GameWidget(game: _game),
                ),
                const _Divider(),
                const _Tokens(),
                const _Divider(),
                const _Materials(),
                const _Divider(),
                const _MotionTable(),
                const _Divider(),
                const GeometrySheet(),
                const _Divider(),
                const _Deferred(),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Masthead extends StatelessWidget {
  const _Masthead({
    required this.reduced,
    required this.onReduced,
    required this.onReplay,
  });

  final bool reduced;
  final ValueChanged<bool> onReduced;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(60, 44, 60, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('KIDUNA STUDIO · ADVANCED ECOSYSTEM VIEW', style: Type.eyebrow),
            const SizedBox(height: 10),
            Text('The Field Catalog', style: Type.display),
            const SizedBox(height: 12),
            SizedBox(
              width: 720,
              child: Text(
                'Every element of the Field, in every state, drawn by the same '
                'code that draws the Field itself. If a specimen looks wrong '
                'here, it is wrong there too.',
                style: Type.bodyQuiet,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                _Toggle(
                  label: 'REDUCED MOTION',
                  value: reduced,
                  onChanged: onReduced,
                ),
                const SizedBox(width: 18),
                GestureDetector(
                  onTap: onReplay,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Enamel.skyBlue.withValues(alpha: 0.55)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'REPLAY GATHER',
                      style: Type.eyebrow.copyWith(color: Enamel.skyBlue),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    reduced
                        ? 'Motion stopped. Every object, label and state sigil '
                            'is still present — nothing is removed because '
                            'animation is off.'
                        : 'Breathe, Drift and Orbit are running. Nothing is in '
                            'phase with anything else.',
                    style: Type.operational,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: value ? Enamel.skyBlue : null,
            border: Border.all(color: Enamel.skyBlue.withValues(alpha: 0.55)),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            label,
            style: Type.eyebrow.copyWith(
              color: value ? Enamel.deepField : Enamel.skyBlue,
            ),
          ),
        ),
      );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 60, vertical: 34),
        color: Enamel.raisedUmber,
      );
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, this.note);

  final String title;
  final String note;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(60, 0, 60, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Type.eyebrow.copyWith(color: Enamel.skyBlue)),
            const SizedBox(height: 6),
            SizedBox(width: 720, child: Text(note, style: Type.bodyQuiet)),
          ],
        ),
      );
}

class _Tokens extends StatelessWidget {
  const _Tokens();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Heading(
            'F · COLOUR',
            'Eleven tokens. Deep Field is the ground and is never a gradient '
                'or a wash.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final (name, color) in Enamel.all)
                  SizedBox(
                    width: 140,
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
                        Text(name,
                            style:
                                Type.operational.copyWith(color: Enamel.text)),
                        Text(
                          '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
                          style: Type.operational,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 360,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('THE SKY-BLUE ACTION RULE', style: Type.eyebrow),
                      const SizedBox(height: 8),
                      Text(
                        'White or cream is prohibited on a sky-blue fill. The '
                        'ink must match the exact local ground behind the '
                        'button — so it changes with the surface, and can '
                        'never be passed in.',
                        style: Type.bodyQuiet,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 30),
                for (final (name, ground) in const [
                  ('Deep Field', Enamel.deepField),
                  ('Warm surface', Enamel.warmSurface),
                  ('Raised umber', Enamel.raisedUmber),
                  ('Raised warm', Enamel.raisedWarmSurface),
                ])
                  KidunaGround(
                    ground: ground,
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(16),
                      color: ground,
                      child: Column(
                        children: [
                          const SkyAction(label: 'Form a Realm'),
                          const SizedBox(height: 8),
                          Text(name, style: Type.operational),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
}

class _Materials extends StatelessWidget {
  const _Materials();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Heading(
            'G · MATERIALS AND ALLY STATES',
            'Four materials describe how a surface reads. An Ally is a '
                'Portrait, not an avatar: State is context, never the person.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final m in Material4.values)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.label, style: Type.realmName),
                              Text(m.description, style: Type.operational),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                for (final state in const [
                  ('open', 'Available · welcoming · present'),
                  ('engaged', 'Conversing · collaborating · responding'),
                  ('focused', 'Working · reviewing · making'),
                  ('dreaming', 'Imagining · reflecting · exploring'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: SizedBox(
                      width: 150,
                      child: Column(
                        children: [
                          ClipOval(
                            child: Image.asset(
                              'assets/allies/ally-${state.$1}-sample.png',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(state.$1.toUpperCase(), style: Type.eyebrow),
                          const SizedBox(height: 3),
                          Text(
                            state.$2,
                            style: Type.operational,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
}

class _MotionTable extends StatelessWidget {
  const _MotionTable();

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String, String)>[
      (
        'Breathe',
        'Open',
        'scale 1 → ${1 + Verb.breatheScale} → 1 · '
            '${Verb.breathePeriodMin.toInt()}–${Verb.breathePeriodMax.toInt()}s · ease-in-out',
      ),
      (
        'Drift',
        'Dreaming',
        'max ±${Verb.driftMax.toInt()}px/axis · '
            '${Verb.driftPeriodMin.toInt()}–${Verb.driftPeriodMax.toInt()}s · labels never detach',
      ),
      (
        'Relate',
        'Engaged',
        'brighten an existing path · '
            '${Verb.relatePeriodMin.toInt()}–${Verb.relatePeriodMax.toInt()}s cycle',
      ),
      (
        'Gather',
        'Focused',
        '${(Verb.gatherSettle * 1000).toInt()}ms settle · '
            '${(Verb.gatherStagger * 1000).toInt()}ms sibling stagger · cubic-bezier(.2,.7,.2,1)',
      ),
      (
        'Orbit',
        '—',
        '≥${Verb.orbitMinPeriod.toInt()}s per revolution · membership, not decoration',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Heading(
          'H · MOTION',
          'Five named verbs, specified rather than invented. Nothing bounces: '
              'the Field reads as alive, not animated.',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 60),
          child: Column(
            children: [
              for (final (verb, state, spec) in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          width: 110,
                          child: Text(verb, style: Type.realmName)),
                      SizedBox(
                          width: 110,
                          child: Text(state, style: Type.operational)),
                      Expanded(child: Text(spec, style: Type.body)),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  SizedBox(
                      width: 220,
                      child: Text('REDUCED MOTION', style: Type.eyebrow)),
                  Expanded(
                    child: Text(
                      'Stops breathe, drift, orbit, path pulse, parallax and '
                      'stagger. Retains glow, scale, labels, state sigils and '
                      'hierarchy. Never removes information because animation '
                      'is disabled.',
                      style: Type.bodyQuiet,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// What was deliberately left out, so nobody mistakes a decision for an
/// oversight — or reimplements it thinking it was forgotten.
class _Deferred extends StatelessWidget {
  const _Deferred();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Heading(
            'I · DEFERRED CANON',
            'The Design Lab canon specifies a richer Field than the AEV route '
                'renders. We built to the AEV as implemented, because it has a '
                'live reference to verify against. These were decisions, not '
                'oversights.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (title, detail) in const [
                  (
                    'Five named connection forms',
                    'Orbit · Tether · Braid · Confluence · Threshold, each with '
                        'its own construction and active signal. The AEV draws '
                        'uniform Béziers instead, and never labels a shape.',
                  ),
                  (
                    'Procedural Organization crests',
                    'Enamel pairs, engravings, and a star signature of three to '
                        'six nodes generated deterministically from the '
                        'Organization ID. This is why the contract guarantees '
                        'Realm IDs are stable and never recycled — it keeps '
                        'that door open.',
                  ),
                  (
                    'Elements inside a Realm',
                    'Actor · Media · Ally · Resource · Action. The canon names '
                        'them but does not specify their shape, and the AEV '
                        'never renders them. Modelling them now would be '
                        'guessing.',
                  ),
                  (
                    'Approach and Threshold',
                    'Click → Panel and Approach → Threshold are distinct verbs '
                        'in the canon. This build implements inspection only; '
                        'entry is a consequential Action with boundaries it '
                        'does not perform.',
                  ),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 260,
                          child: Text(title, style: Type.realmName),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                            child: SizedBox(
                          width: 620,
                          child: Text(detail, style: Type.bodyQuiet),
                        )),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  'Adding any of these is a minor schema change if introduced '
                  'as optional properties. See contracts/README.md.',
                  style: Type.operational,
                ),
              ],
            ),
          ),
        ],
      );
}
