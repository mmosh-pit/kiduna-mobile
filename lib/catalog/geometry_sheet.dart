/// Catalog · the geometry primitives and the Talismans, drawn to spec.
///
/// Every specimen here is painted by `Geometry`, the same library the Field
/// uses. That is the point of the sheet: a reference drawn by different code
/// than the product would drift, and then the reference would be wrong in a
/// way nobody notices until a developer builds from it.
library;

import 'package:flutter/material.dart';

import '../design/tokens.dart';
import '../design/typography.dart';
import '../field/render/geometry_primitives.dart';
import '../field/talisman.dart';

/// The eight primitives, with the meaning and construction the spec fixes.
const _primitives = <(String, String, String)>[
  ('Orbit arc', 'belonging · context · gravity',
      'elliptical; object-centred; continuous, dashed, or doubled'),
  ('Journey path', 'movement · sequence · passage',
      'open curved path with an origin and a destination'),
  ('Anchor stud', 'attachment · commitment · endpoint',
      'radial warm-metal bead with a dark collar'),
  ('Constellation', 'distributed affinity · peers',
      '3–6 nodes joined by selective hairlines; nodes clearer than lines'),
  ('Crossing glint', 'exchange · encounter · transfer',
      'four- or eight-point cream star; hidden unless the crossing matters'),
  ('Horizon ring', 'approach · threshold · nesting',
      'expanding arc becoming viewport edge; cream only near entry'),
  ('Phase node', 'position in a cycle',
      'bead on an orbit; one active node maximum per orbit'),
  ('Cardinal tick', 'stable orientation',
      'short radial mark at N/E/S/W; engraved, not glowing'),
];

class GeometrySheet extends StatelessWidget {
  const GeometrySheet({super.key});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Heading(
            'J · CELESTIAL GEOMETRY',
            'The eight background primitives, painted by the same '
                '`Geometry` library the Field uses. Layer 2 of the composition '
                'stack: scaffolding between the lacquer ground and the objects, '
                'never wallpaper.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Wrap(
              spacing: 22,
              runSpacing: 22,
              children: [
                for (var i = 0; i < _primitives.length; i++)
                  _Specimen(
                    index: i,
                    name: _primitives[i].$1,
                    meaning: _primitives[i].$2,
                    construction: _primitives[i].$3,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 34),
          _Heading(
            'K · DENSITY',
            'The spec bounds how much of this may appear at once. These are '
                'ceilings, not targets.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (rule, value) in const [
                  ('Major arcs per viewport', '2–5'),
                  ('Visible nodes', '3–9'),
                  ('Glints', '0–2'),
                  ('Ground left visually quiet', 'at least 55%'),
                  ('Concurrent line weights', 'no more than 3'),
                  ('Active enamel colours', 'no more than 2'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 300,
                          child: Text(rule, style: Type.body),
                        ),
                        Text(
                          value,
                          style: Type.operational
                              .copyWith(color: Enamel.sunGold),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 700,
                  child: Text(
                    'Constellations cluster around meaning — the Field is '
                    'never filled with evenly distributed stars.',
                    style: Type.bodyQuiet,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 34),
          _Heading(
            'L · TALISMANS',
            'Portable symbols of meaning — not Realm types and not identities. '
                'Anything may carry one; carrying one changes no permission. '
                'The six supplied are a starting set, not a closed list.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Wrap(
              spacing: 26,
              runSpacing: 22,
              children: [
                for (final talisman in Talisman.values)
                  _TalismanCard(talisman: talisman),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('COMPOSITION ORDER', style: Type.eyebrow),
                const SizedBox(height: 10),
                for (var i = 0; i < talismanCompositionOrder.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            talismanCompositionOrder[i].$1,
                            style: Type.realmName,
                          ),
                        ),
                        SizedBox(
                          width: 560,
                          child: Text(
                            talismanCompositionOrder[i].$2,
                            style: Type.bodyQuiet,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
}

class _Specimen extends StatelessWidget {
  const _Specimen({
    required this.index,
    required this.name,
    required this.meaning,
    required this.construction,
  });

  final int index;
  final String name;
  final String meaning;
  final String construction;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 132,
              decoration: BoxDecoration(
                color: Enamel.deepField,
                border: Border.all(color: Enamel.raisedUmber),
              ),
              child: CustomPaint(
                painter: _PrimitivePainter(index),
                size: Size.infinite,
              ),
            ),
            const SizedBox(height: 9),
            Text(name, style: Type.realmName),
            const SizedBox(height: 2),
            Text(meaning,
                style: Type.eyebrow.copyWith(color: Enamel.skyBlue)),
            const SizedBox(height: 5),
            Text(construction, style: Type.bodyQuiet),
          ],
        ),
      );
}

/// Draws one primitive, centred in its plate.
class _PrimitivePainter extends CustomPainter {
  const _PrimitivePainter(this.index);

  final int index;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final bounds = Rect.fromCenter(
      center: centre,
      width: size.width * 0.62,
      height: size.height * 0.46,
    );

    switch (index) {
      case 0:
        // Continuous, dashed and doubled, so all three engravings are visible.
        Geometry.orbitArc(canvas, bounds,
            state: GeometryState.relevant, rotation: -0.2);
        Geometry.orbitArc(canvas, bounds.deflate(17),
            engraving: OrbitEngraving.dashed, state: GeometryState.relevant);
      case 1:
        final from = Offset(size.width * 0.18, size.height * 0.66);
        final to = Offset(size.width * 0.82, size.height * 0.4);
        Geometry.journeyPath(canvas, from, to,
            state: GeometryState.relevant);
        Geometry.anchorStud(canvas, from);
        Geometry.anchorStud(canvas, to);
      case 2:
        Geometry.anchorStud(canvas, centre.translate(-34, 0),
            size: Geometry.anchorSmall);
        Geometry.anchorStud(canvas, centre.translate(0, 0),
            size: Geometry.anchorRegular);
        Geometry.anchorStud(canvas, centre.translate(38, 0),
            size: Geometry.anchorRegular, emphasized: true);
      case 3:
        Geometry.constellation(canvas, [
          centre.translate(-46, -22),
          centre.translate(-8, -34),
          centre.translate(30, -10),
          centre.translate(12, 26),
          centre.translate(-34, 16),
        ], state: GeometryState.relevant);
      case 4:
        Geometry.crossingGlint(canvas, centre.translate(-38, 0),
            size: Geometry.glintSmall, points: 4);
        Geometry.crossingGlint(canvas, centre, size: Geometry.glintRegular);
        Geometry.crossingGlint(canvas, centre.translate(42, 0),
            size: Geometry.glintHero);
      case 5:
        Geometry.horizonRing(canvas, centre, 22, approach: 0);
        Geometry.horizonRing(canvas, centre, 38, approach: 0.5);
        Geometry.horizonRing(canvas, centre, 54, approach: 1);
      case 6:
        Geometry.orbitArc(canvas, bounds, state: GeometryState.relevant);
        Geometry.phaseNode(canvas, bounds, 0.14);
        Geometry.phaseNode(canvas, bounds, 0.62, active: false);
      case 7:
        Geometry.cardinalTicks(canvas, centre, 34);
        Geometry.orbitArc(
          canvas,
          Rect.fromCircle(center: centre, radius: 34),
          state: GeometryState.resting,
        );
    }
  }

  @override
  bool shouldRepaint(_PrimitivePainter old) => old.index != index;
}

class _TalismanCard extends StatelessWidget {
  const _TalismanCard({required this.talisman});

  final Talisman talisman;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 168,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 168,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Enamel.deepField,
                border: Border.all(color: Enamel.raisedUmber),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Image.asset(talisman.asset, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 9),
            Text(talisman.label, style: Type.realmName),
            const SizedBox(height: 2),
            Text(
              talisman.meaning.toUpperCase(),
              style: Type.eyebrow.copyWith(color: Enamel.sunGold),
            ),
            const SizedBox(height: 4),
            Text(talisman.gloss, style: Type.bodyQuiet),
          ],
        ),
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
            const SizedBox(height: 8),
            SizedBox(width: 720, child: Text(note, style: Type.bodyQuiet)),
            const SizedBox(height: 4),
          ],
        ),
      );
}
