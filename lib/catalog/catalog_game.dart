/// The specimen board.
///
/// Every Field element, drawn by the **same code that draws the Field** — not a
/// mock-up of it. A catalogue that reimplements its subject documents a fiction;
/// this one shares `RealmNode`, `ConnectorLayer` and `ClusterLayer`, so if a
/// specimen looks wrong here it is wrong in the Field too.
library;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import '../design/tokens.dart';
import '../design/typography.dart';
import '../field/models.dart';
import '../field/placement.dart';
import '../field/render/ground_layer.dart';
import '../field/render/motion.dart';
import '../field/render/realm_node.dart';

/// A synthetic Realm, so a specimen can exercise a state the fixtures happen
/// not to contain.
Realm _realm(
  String name,
  RealmType? type, {
  String typeName = '',
  String motif = '✦',
  bool fixture = false,
  int mass = 2,
  List<String> children = const [],
}) =>
    Realm(
      id: name.toLowerCase().replaceAll(' ', '-'),
      name: name,
      typeName: typeName.isEmpty ? (type?.label ?? 'Unknown') : typeName,
      type: type,
      clusterId: 'formation',
      mass: mass,
      fixture: fixture,
      motif: motif,
      childIds: children,
      purpose: 'A specimen, drawn by the same code that draws the Field.',
    );

const _specimenCluster = ClusterDef(
  id: 'formation',
  label: '',
  accent: Color(0xFF03CCD9),
  left: 50,
  top: 50,
  radiusX: 30,
  radiusY: 20,
);

Placement _specimen(
  Realm realm, {
  required Gravity gravity,
  ClusterDef cluster = _specimenCluster,
  Role role = Role.catalyst,
  Ally? ally,
}) =>
    Placement(
      realm: realm,
      cluster: cluster,
      gravity: gravity,
      band: gravity.band,
      seed: const FieldPoint(50, 50),
      position: const FieldPoint(50, 50),
      role: role,
      ally: ally,
    );

class _Section {
  const _Section(this.title, this.note);

  final String title;
  final String note;
}

class CatalogGame extends FlameGame {
  CatalogGame();

  final Motion motion = Motion();

  final List<RealmNode> _nodes = [];
  final List<(String, Vector2)> _captions = [];
  final List<(_Section, double)> _sections = [];

  /// Total height the board needs, derived from the layout rather than
  /// guessed — an eyeballed value let section E overflow into the Flutter
  /// content below it.
  ///
  ///   74 start
  /// + 96 + 3×196   section A · types × distance
  /// + 22 + 96 + 200 section B · gravity
  /// + 96 + 210      section C · states
  /// + 46 + 250      section D · connectors
  /// + 46 + 190      section E · clusters
  static const boardHeight =
      74 + 96 + 3 * 196 + 22 + 96 + 200 + 96 + 210 + 46 + 250 + 46 + 190.0;

  static const _colGap = 168.0;
  static const _left = 120.0;

  late final TextPaint _caption = TextPaint(
    style: TextStyle(
      fontFamily: Type.operational.fontFamily,
      fontWeight: FontWeight.w300,
      fontSize: 10.5,
      letterSpacing: 0.5,
      color: Enamel.camel,
    ),
  );

  late final TextPaint _sectionTitle = TextPaint(
    style: TextStyle(
      fontFamily: Type.body.fontFamily,
      fontWeight: FontWeight.w800,
      fontSize: 11,
      letterSpacing: 1.8,
      color: Enamel.skyBlue,
    ),
  );

  late final TextPaint _sectionNote = TextPaint(
    style: TextStyle(
      fontFamily: Type.body.fontFamily,
      fontWeight: FontWeight.w300,
      fontSize: 12,
      color: Enamel.camel,
    ),
  );

  @override
  Color backgroundColor() => Enamel.deepField;

  @override
  Future<void> onLoad() async {
    Flame.images.prefix = '';
    camera.viewfinder.anchor = Anchor.topLeft;
    camera.backdrop.add(GroundLayer(motion)..size = Vector2(1600, boardHeight));

    final emblems = <String, Sprite>{};
    Future<Sprite> sprite(String path) async =>
        emblems[path] ??= Sprite(await Flame.images.load(path));

    var y = 74.0;

    // ── A · Realm type × distance band ────────────────────────────────
    _sections.add((
      const _Section(
        'A · REALM TYPES × DISTANCE',
        'Distance is not level-of-detail. Near carries a unique Portrait; far a '
            'generic type glyph. Reading distance is reading relevance.',
      ),
      y,
    ));
    y += 96;

    for (final band in DistanceBand.values) {
      var x = _left;
      for (final type in RealmType.values) {
        final placement = _specimen(
          _realm(type.label, type, motif: '✦'),
          gravity: switch (band) {
            DistanceBand.near => Gravity.central,
            DistanceBand.middle => Gravity.relevant,
            DistanceBand.far => Gravity.quiet,
          },
        );
        _nodes.add(
          RealmNode(
            placement: placement,
            emblem: await sprite(placement.realm.emblemAsset),
            motion: motion,
            index: _nodes.length,
            entryIndex: 0,
            onSelect: (_) {},
            onActivate: (_) {},
          )..position = Vector2(x, y),
        );
        x += _colGap;
      }
      // Above the row, not beside it: at x = 24 the caption ran straight into
      // the first specimen.
      _captions.add((
        '${band.name.toUpperCase()}  ·  ${band.size.width.toInt()}×'
            '${band.size.height.toInt()}  ·  opacity ${band.opacity}',
        Vector2(60, y - 92),
      ));
      y += 196;
    }

    // ── B · Gravity ───────────────────────────────────────────────────
    y += 22;
    _sections.add((
      const _Section(
        'B · GRAVITY 1–5',
        'One number drives position, distance band and art fidelity together. '
            'Presentation only — never authority, membership or truth.',
      ),
      y,
    ));
    y += 96;

    var gx = _left;
    for (final gravity in Gravity.values) {
      final placement = _specimen(
        _realm('${gravity.level} · ${gravity.label}', RealmType.organization,
            motif: '⌑'),
        gravity: gravity,
      );
      _nodes.add(
        RealmNode(
          placement: placement,
          emblem: await sprite(placement.realm.emblemAsset),
          motion: motion,
          index: _nodes.length,
          entryIndex: 0,
          onSelect: (_) {},
          onActivate: (_) {},
        )..position = Vector2(gx, y),
      );
      _captions.add((
        'pull ${gravity.pull}  ·  ${gravity.band.name}',
        Vector2(gx - 52, y + 78),
      ));
      gx += _colGap;
    }
    y += 200;

    // ── C · States that must remain legible ───────────────────────────
    _sections.add((
      const _Section(
        'C · STATES',
        'Every case the contract says must degrade rather than throw.',
      ),
      y,
    ));
    y += 96;

    final states = <(String, Placement)>[
      (
        'PROPOSED · fixture: true',
        _specimen(
          _realm('Proposed Cooperative, Inc.', RealmType.institution,
              motif: '⬡', fixture: true),
          gravity: Gravity.central,
        ),
      ),
      (
        'UNKNOWN TYPE',
        _specimen(
          _realm('Unrecognised', null, typeName: 'Constellation', motif: '◌'),
          gravity: Gravity.central,
        ),
      ),
      (
        'OVERLONG NAME',
        _specimen(
          _realm(
            'A Realm Whose Name Runs Far Longer Than Any Label Was Designed To Hold',
            RealmType.community,
            motif: '≋',
          ),
          gravity: Gravity.central,
        ),
      ),
      (
        'NO MOTIF',
        _specimen(
          _realm('No Motif', RealmType.project, motif: ''),
          gravity: Gravity.central,
        ),
      ),
      (
        'GUEST · no ring',
        _specimen(
          _realm('Guest Standing', RealmType.community, motif: '◯'),
          gravity: Gravity.central,
          role: Role.guest,
        ),
      ),
      (
        'ALLY STATIONED',
        _specimen(
          _realm('With an Ally', RealmType.alliance, motif: '✥'),
          gravity: Gravity.central,
          ally: const Ally(id: 'a', name: 'Luna', state: AllyState.open),
        ),
      ),
    ];

    var sx = _left;
    for (final (caption, placement) in states) {
      _nodes.add(
        RealmNode(
          placement: placement,
          emblem: await sprite(placement.realm.emblemAsset),
          motion: motion,
          index: _nodes.length,
          entryIndex: 0,
          onSelect: (_) {},
          onActivate: (_) {},
        )..position = Vector2(sx, y),
      );
      _captions.add((caption, Vector2(sx - 56, y + 86)));
      sx += _colGap + 30;
    }
    y += 210;

    // ── D · Connectors ────────────────────────────────────────────────
    _sections.add((
      const _Section(
        'D · CONNECTORS',
        'Lines are never decorative. Selection brightens a path that already '
            'exists; it never invents one.',
      ),
      y,
    ));
    y += 46;

    world.add(_ConnectorSpecimens(motion)
      ..position = Vector2(_left - 60, y)
      ..size = Vector2(1400, 210));
    y += 250;

    // ── E · Cluster accents ───────────────────────────────────────────
    _sections.add((
      const _Section(
        'E · CLUSTERS',
        'Restrained halos — never hard containers, never ranking boundaries.',
      ),
      y,
    ));
    y += 46;

    world.add(_ClusterSpecimens()
      ..position = Vector2(_left - 60, y)
      ..size = Vector2(1400, 190));

    // Specimens live in the world, not the game root: with the viewfinder
    // anchored top-left at zoom 1, world coordinates are screen coordinates,
    // and this is the same path the Field itself uses.
    for (final node in _nodes) {
      node.worldSize = Vector2(100, 100);
      world.add(node);
    }
  }

  /// Nodes resolve their own position from percent, which the catalogue does
  /// not use — specimens are placed absolutely. Restoring the position after
  /// the shared update keeps every other behaviour identical to the Field.
  @override
  void update(double dt) {
    final held = [for (final n in _nodes) n.position.clone()];
    super.update(dt);
    motion.tick(dt);
    for (var i = 0; i < _nodes.length; i++) {
      _nodes[i].position = held[i];
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (final (section, y) in _sections) {
      _sectionTitle.render(canvas, section.title, Vector2(60, y - 34));
      _sectionNote.render(canvas, section.note, Vector2(60, y - 16));
    }
    for (final (text, at) in _captions) {
      _caption.render(canvas, text, at);
    }
  }

  /// Replays the staggered arrival so Gather can be watched on demand.
  void replayEntry() => motion.restart();
}

/// The three connector species, side by side and labelled.
class _ConnectorSpecimens extends PositionComponent {
  _ConnectorSpecimens(this.motion);

  final Motion motion;

  late final TextPaint _label = TextPaint(
    style: TextStyle(
      fontFamily: Type.operational.fontFamily,
      fontWeight: FontWeight.w300,
      fontSize: 10.5,
      letterSpacing: 0.5,
      color: Enamel.camel,
    ),
  );

  Path _curve(Offset a, Offset b, double bend) => Path()
    ..moveTo(a.dx, a.dy)
    ..quadraticBezierTo((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 + bend, b.dx, b.dy);

  @override
  void render(Canvas canvas) {
    const y = 60.0;
    var x = 60.0;
    const span = 260.0;

    void specimen(String name, String note, void Function(Offset, Offset) draw) {
      final a = Offset(x, y);
      final b = Offset(x + span - 90, y + 34);
      draw(a, b);
      canvas.drawCircle(a, 3, Paint()..color = Enamel.cream.withValues(alpha: .5));
      canvas.drawCircle(b, 3, Paint()..color = Enamel.cream.withValues(alpha: .5));
      _label.render(canvas, name, Vector2(x, y + 66));
      _label.render(canvas, note, Vector2(x, y + 82));
      x += span + 40;
    }

    specimen('WITHIN CLUSTER', 'chained · bend 3.5 · cluster accent', (a, b) {
      final p = _curve(a, b, 20);
      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..color = Cluster.formation.accent.withValues(alpha: .14)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Cluster.formation.accent.withValues(alpha: .5),
      );
    });

    specimen('CROSS-CLUSTER BRIDGE', 'quieter · bend 7.0 · camel', (a, b) {
      canvas.drawPath(
        _curve(a, b, 40),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = Enamel.camel.withValues(alpha: .20),
      );
    });

    specimen('CURRENT PATH', 'gold · subordinate to identity', (a, b) {
      canvas.drawPath(
        _curve(a, b, 26),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = Enamel.sunGold.withValues(alpha: .34)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
      );
    });

    specimen('SELECTED · RELATE', 'brightens what exists · 3–5s cycle', (a, b) {
      final pulse = Verb.lerp(
        .55,
        1,
        Verb.easeInOut(Verb.pingPong(motion.elapsed, Verb.relatePeriodMax)),
      );
      final p = _curve(a, b, 20);
      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4
          ..color = Cluster.formation.accent.withValues(alpha: .30 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Cluster.formation.accent.withValues(alpha: .92 * pulse),
      );
    });
  }
}

/// The six cluster accents as the halos they actually draw.
class _ClusterSpecimens extends PositionComponent {
  late final TextPaint _label = TextPaint(
    style: TextStyle(
      fontFamily: Type.operational.fontFamily,
      fontWeight: FontWeight.w300,
      fontSize: 10.5,
      letterSpacing: 0.5,
      color: Enamel.camel,
    ),
  );

  @override
  void render(Canvas canvas) {
    var x = 120.0;
    const y = 70.0;
    for (final cluster in Cluster.values) {
      final rect = Rect.fromCenter(center: Offset(x, y), width: 190, height: 96);
      canvas.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              cluster.accent.withValues(alpha: .085),
              cluster.accent.withValues(alpha: .028),
              const Color(0x00000000),
            ],
            stops: const [0, .58, 1],
          ).createShader(rect),
      );
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .6
          ..color = cluster.accent.withValues(alpha: .10),
      );
      _label.render(canvas, cluster.name.toUpperCase(), Vector2(x - 70, y - 6));
      _label.render(
        canvas,
        cluster.label.isEmpty ? 'nested · unlabelled' : cluster.label,
        Vector2(x - 70, y + 10),
      );
      x += 224;
    }
  }
}
