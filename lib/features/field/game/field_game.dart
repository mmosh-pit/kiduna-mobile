import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult, VoidCallback;

import '../../../config/kiduna_colors.dart';
import '../data/field_events.dart';
import '../data/field_models.dart';
import '../data/field_source.dart';
import '../data/placement.dart';
import '../widgets/nav_mode.dart';
import 'components/back_button_layer.dart';
import 'components/camera_control.dart';
import 'components/cluster_layer.dart';
import 'components/comet_component.dart';
import 'components/connector_layer.dart';
import 'components/galaxy_component.dart';
import 'components/ground_component.dart';
import 'components/motion.dart';
import 'components/nebula_component.dart';
import 'components/realm_node.dart';
import 'components/star_atlas_data.dart';
import 'components/star_field_component.dart';
import 'components/star_layer.dart';
import 'components/vignette_component.dart';
import 'enamel_tokens.dart';
import 'field_traverse.dart';

class FieldGame extends FlameGame
    with DragCallbacks, ScrollDetector, KeyboardEvents {
  FieldGame({
    required this._palette,
    required this._reduceMotion,
    this.source,
    this.nav = NavMode.none,
    this.hideStars = false,
    this.mousePanEnabled = true,
    this.scrollPanEnabled = true,
    this.onInspect,
    this.onDeselect,
    this.onReady,
    this.onStarView,
  });

  static const double _loopSeconds = 16;

  KidunaColors _palette;
  bool _reduceMotion;
  double _t = 0;

  final FieldSource? source;
  final NavMode nav;
  final bool hideStars;
  final bool mousePanEnabled;
  final bool scrollPanEnabled;
  final void Function(Placement)? onInspect;
  final VoidCallback? onDeselect;
  final VoidCallback? onReady;
  final void Function(String label, Color accent, int count)? onStarView;
  VoidCallback? onCameraMoved;

  KidunaColors get palette => _palette;
  bool get reduceMotion => _reduceMotion;
  double get t => _t;

  final Motion motion = Motion();
  ResolvedField? field;
  ClusterLayer? _clusters;
  ConnectorLayer? _connectors;
  final List<RealmNode> _nodes = [];
  Vector2 _worldSize = Vector2.all(1);
  bool _cameraInitialized = false;
  static const _orbitsPerScreen = 5;

  FieldTraverse? _traverse;
  StarLayer? _stars;
  BackButtonLayer? _backButton;
  final Map<String, Sprite> _emblems = {};

  FieldSnapshot? _snapshot;
  RealmNode? _selected;
  Placement? _preSelectPlacement;
  RealmNode? _hovered;
  final Map<String, Gravity> _gravity = {};
  double _cameraDirtyFor = 0;
  final Set<LogicalKeyboardKey> _held = {};
  Vector2 _pointer = Vector2.zero();

  FieldSnapshot? get snapshot => _snapshot;
  Placement? get selection => _selected?.placement;

  double get worldScale {
    final orbits =
        _snapshot?.clusters.where((c) => !c.isBranch).length ??
        _orbitsPerScreen;
    if (orbits <= _orbitsPerScreen) return 2.5;
    return 2.5 * math.sqrt(orbits / _orbitsPerScreen);
  }

  Size get visibleFraction {
    final visible = size / camera.viewfinder.zoom;
    return Size(
      (visible.x / _worldSize.x).clamp(0.05, 1.0),
      (visible.y / _worldSize.y).clamp(0.05, 1.0),
    );
  }

  bool get _backgroundOnly => source == null;

  @override
  Color backgroundColor() => Enamel.deepField;

  @override
  Future<void> onLoad() async {
    Flame.images.prefix = '';
    camera.viewfinder.anchor = Anchor.topLeft;

    await addAll([
      GroundComponent(),
      NebulaComponent.warm(),
      NebulaComponent.teal(),
      GalaxyComponent(),
      CometComponent(),
      StarFieldComponent(),
    ]);

    if (_backgroundOnly) {
      await add(VignetteComponent());
      _worldSize = size * worldScale;
      if (_reduceMotion) {
        pauseEngine();
      }
      onReady?.call();
      return;
    }

    final snap = await source!.load();
    _snapshot = snap;
    _gravity.addAll(snap.viewer.gravity);
    final resolved = resolveField(snap);
    field = resolved;

    for (final p in resolved.placements) {
      _emblems[p.realm.emblemAsset] ??= Sprite(
        await Flame.images.load(p.realm.emblemAsset),
      );
    }

    _clusters = ClusterLayer(resolved.clusters, motion);
    final counts = <String, int>{};
    for (final p in resolved.placements) {
      counts.update(p.cluster.id, (n) => n + 1, ifAbsent: () => 1);
    }
    _clusters!.realmCounts = counts;
    world.add(_clusters!);

    _connectors = ConnectorLayer(resolved, motion);
    if (resolved.bridges.isNotEmpty) {
      world.add(_connectors!);
    }

    const order = [DistanceBand.far, DistanceBand.middle, DistanceBand.near];
    final withinCluster = <String, int>{};
    for (final band in order) {
      for (final p in resolved.placements) {
        if (p.band != band) continue;
        final ei = withinCluster[p.cluster.id] ?? 0;
        withinCluster[p.cluster.id] = ei + 1;
        final node = RealmNode(
          placement: p,
          emblem: _emblems[p.realm.emblemAsset]!,
          motion: motion,
          index: _nodes.length,
          entryIndex: ei,
          onSelect: _select,
          onActivate: _activate,
          onHoverChanged: _onNodeHoverChanged,
        );
        _nodes.add(node);
        world.add(node);
      }
    }

    await add(VignetteComponent());

    if (nav != NavMode.none) {
      _traverse = FieldTraverse(nav);
      if (!hideStars) {
        _stars = StarLayer(motion);
        _traverse!.stars = _stars;
        world.add(_stars!);
      }
      _backButton = BackButtonLayer();
      await add(_backButton!);
      _clusters?.visibleIds = _traverse!.visibleClusterIds(_snapshot);
    }

    _layout();
    if (_reduceMotion) {
      motion.reduced = true;
    }
    onReady?.call();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _layout();
  }

  void _layout() {
    _worldSize = size * worldScale;
    _clusters?.size = _worldSize;
    _connectors?.size = _worldSize;
    _stars?.size = _worldSize;
    for (final node in _nodes) {
      node.worldSize = _worldSize;
    }
    if (!_cameraInitialized) {
      var minLeft = 50.0;
      var maxLeft = 50.0;
      var minTop = 50.0;
      var maxTop = 50.0;
      for (final node in _nodes) {
        final point = node.placement.position;
        minLeft = math.min(minLeft, point.left);
        maxLeft = math.max(maxLeft, point.left);
        minTop = math.min(minTop, point.top);
        maxTop = math.max(maxTop, point.top);
      }
      final zoom = 1.0;
      final visible = size / zoom;
      _applyCamera(
        Vector2(
          ((minLeft + maxLeft) / 200 * _worldSize.x) - visible.x / 2,
          ((minTop + maxTop) / 200 * _worldSize.y) - visible.y / 2,
        ),
        zoom,
      );
      _cameraInitialized = true;
    } else {
      _applyCamera(camera.viewfinder.position, camera.viewfinder.zoom);
    }
  }

  void _applyCamera(Vector2 position, double zoom) {
    final cz = Cam.clampZoom(zoom);
    camera.viewfinder.zoom = cz;
    camera.viewfinder.position = Cam.clampPosition(
      position: position,
      world: _worldSize,
      viewport: size,
      zoom: cz,
    );
    for (final node in _nodes) {
      node.zoom = cz;
    }
    _cameraDirtyFor = 0.25;
    onCameraMoved?.call();
  }

  void panBy(Vector2 delta) => _applyCamera(
    Cam.panned(
      position: camera.viewfinder.position,
      screenDelta: delta,
      zoom: camera.viewfinder.zoom,
    ),
    camera.viewfinder.zoom,
  );

  void zoomAt(Vector2 pointer, double dir, {double times = 1}) {
    final from = camera.viewfinder.zoom;
    final to = Cam.stepZoom(from, dir, times: times);
    if (to == from) return;
    _applyCamera(
      Cam.zoomAnchored(
        position: camera.viewfinder.position,
        fromZoom: from,
        toZoom: to,
        pointer: pointer,
      ),
      to,
    );
  }

  void _onNodeHoverChanged(RealmNode node, bool entered) {
    if (entered) {
      if (_hovered == node) return;
      _hovered?.activeHover = false;
      _hovered = node;
      node.activeHover = true;
    } else {
      if (_hovered != node) return;
      node.activeHover = false;
      _hovered = null;
    }
  }

  void _select(RealmNode node) {
    if (_selected == node) return;
    if (_selected != null && _preSelectPlacement != null) {
      _selected!.reseat(_preSelectPlacement!);
    }
    _selected?.selected = false;
    _selected = node..selected = true;
    _connectors?.select(node.placement.realm.id);
    source?.emit(RealmSelected(node.placement.realm.id, DateTime.now()));
    _preSelectPlacement = node.placement;
    node.reseat(_centeredPlacement(node.placement));
  }

  void _activate(RealmNode node) {
    source?.emit(RealmActivated(node.placement.realm.id, DateTime.now()));
    onInspect?.call(node.placement);
  }

  void clearSelection() {
    if (_selected == null) return;
    if (_preSelectPlacement != null) {
      _selected!.reseat(_preSelectPlacement!);
    }
    _selected!.selected = false;
    _selected = null;
    _preSelectPlacement = null;
    _connectors?.select(null);
    source?.emit(RealmDeselected(DateTime.now()));
    onDeselect?.call();
  }

  Placement _centeredPlacement(Placement original) {
    final vf = camera.viewfinder;
    final vis = size / vf.zoom;
    final cx = (vf.position.x + vis.x / 2) / _worldSize.x * 100;
    final cy = (vf.position.y + vis.y / 2) / _worldSize.y * 100;
    return Placement(
      realm: original.realm,
      cluster: original.cluster,
      gravity: original.gravity,
      band: original.band,
      seed: original.seed,
      position: FieldPoint(cx.clamp(5, 95), cy.clamp(9, 92)),
      role: original.role,
      ally: original.ally,
    );
  }

  Gravity gravityOf(String id) => _gravity[id] ?? Gravity.quiet;

  void setGravity(String realmId, Gravity next) {
    final snap = _snapshot;
    if (snap == null) return;
    final prev = _gravity[realmId] ?? Gravity.quiet;
    if (prev == next) return;
    _gravity[realmId] = next;
    final reseated = resolveField(
      FieldSnapshot(
        schemaVersion: snap.schemaVersion,
        viewer: Viewer(
          id: snap.viewer.id,
          displayName: snap.viewer.displayName,
          roles: snap.viewer.roles,
          gravity: Map.of(_gravity),
        ),
        ecosystem: snap.ecosystem,
        realms: snap.realms,
        clusters: snap.clusters,
        bridges: snap.bridges,
        currentPathTargetId: snap.currentPathTargetId,
      ),
    );
    field = reseated;
    for (final n in _nodes) {
      final p = reseated.byId(n.placement.realm.id);
      if (p != null) n.reseat(p);
    }
    _connectors?.reseat(reseated);
    if (_selected != null) {
      _connectors?.select(_selected!.placement.realm.id);
      if (_selected!.placement.realm.id == realmId && _preSelectPlacement != null) {
        _preSelectPlacement = reseated.byId(realmId);
      }
    }
    source?.emit(GravityChanged(realmId, prev, next, DateTime.now()));
  }

  Vector2? _pressAt;
  double _pressTravel = 0;
  static const _tapSlop = 6.0;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _pressAt = event.localPosition.clone();
    _pressTravel = 0;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _pressTravel += event.localDelta.length;
    if (!mousePanEnabled) return;
    panBy(event.localDelta);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    final at = _pressAt;
    _pressAt = null;
    if (at == null || _pressTravel > _tapSlop) {
      return;
    }

    if (_backButton != null && _backButton!.tapAt(at) != null) {
      returnToAtlas();
      return;
    }

    if (_stars != null && _traverse?.arrivedStar == null) {
      final star = _stars!.starAt(at);
      if (star != null) {
        _enterStarView(star);
        return;
      }
    }

    final node = _realmAt(at);
    if (node == null) {
      clearSelection();
      return;
    }
    _select(node);
    _activate(node);
  }

  RealmNode? _realmAt(Vector2 pt) {
    final v = camera.viewfinder;
    final w = v.position + pt / v.zoom;
    for (final n in _nodes.reversed) {
      if (n.hidden || n.contentFade <= 0.01) continue;
      final h = n.size / 2;
      final d = w - n.position;
      if (d.x.abs() <= h.x && d.y.abs() <= h.y) return n;
    }
    return null;
  }

  @override
  void onScroll(PointerScrollInfo info) {
    if (!scrollPanEnabled) return;
    _pointer = info.eventPosition.widget;
    final d = info.scrollDelta.global;
    final k = HardwareKeyboard.instance;
    if (!k.isShiftPressed) {
      if (d.y == 0) return;
      zoomAt(_pointer, d.y < 0 ? 1 : -1, times: (d.y.abs() / 40).clamp(0.4, 3));
      return;
    }
    panBy(-d);
  }

  @override
  void onMount() {
    super.onMount();
    _pointer = size / 2;
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _held
      ..clear()
      ..addAll(keysPressed);
    if (event is! KeyDownEvent) return KeyEventResult.handled;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.digit0:
      case LogicalKeyboardKey.numpad0:
        _applyCamera(Vector2.zero(), 1);
      case LogicalKeyboardKey.equal:
      case LogicalKeyboardKey.add:
      case LogicalKeyboardKey.numpadAdd:
        zoomAt(size / 2, 1);
      case LogicalKeyboardKey.minus:
      case LogicalKeyboardKey.numpadSubtract:
        zoomAt(size / 2, -1);
      case LogicalKeyboardKey.escape:
        clearSelection();
      default:
        break;
    }
    return KeyEventResult.handled;
  }

  static final _panL = {LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA};
  static final _panR = {LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD};
  static final _panU = {LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyW};
  static final _panD = {LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyS};

  @override
  void update(double dt) {
    super.update(dt);
    if (!_reduceMotion) {
      _t = (_t + dt / _loopSeconds) % 1.0;
    }
    motion.tick(dt);

    _traverse?.tickTravel(
      dt,
      motion,
      (newFocus) {
        _clusters?.visibleIds = _traverse!.visibleClusterIds(_snapshot);
      },
      () {
        _clusters?.visibleIds = _traverse!.visibleClusterIds(_snapshot);
      },
    );

    final tFade = _traverse?.contentFade ?? 1.0;
    final inStar = _traverse?.arrivedStar != null;
    _backButton?.opacity = inStar ? 1.0 : 0.0;

    if (_selected == null) {
      _clusters?.contentFade = tFade;
      _connectors?.contentFade = tFade;
      for (final n in _nodes) {
        n.contentFade = tFade;
      }
    } else {
      _clusters?.contentFade = 0.3 * tFade;
      _connectors?.contentFade = 0.3 * tFade;
      for (final n in _nodes) {
        if (n == _selected) {
          n.contentFade = tFade;
        } else {
          n.contentFade = (n.placement.gravity.level >= 4 ? 0.6 : 0.35) * tFade;
        }
      }
    }

    if (_traverse != null) {
      final collapsed = _traverse!.isCollapsed(camera.viewfinder.zoom);
      _clusters?.collapsed = collapsed;
      _clusters?.starField = inStar;
    }

    if (_cameraDirtyFor > 0) {
      _cameraDirtyFor -= dt;
      if (_cameraDirtyFor <= 0) {
        final v = camera.viewfinder;
        source?.emit(
          CameraChanged(v.position.x, v.position.y, v.zoom, DateTime.now()),
        );
      }
    }
    if (_held.isEmpty) {
      return;
    }
    final s = Cam.keyPanPerSecond * dt;
    var dx = 0.0, dy = 0.0;
    if (_held.any(_panL.contains)) {
      dx += s;
    }
    if (_held.any(_panR.contains)) {
      dx -= s;
    }
    if (_held.any(_panU.contains)) {
      dy += s;
    }
    if (_held.any(_panD.contains)) {
      dy -= s;
    }
    if (dx != 0 || dy != 0) {
      panBy(Vector2(dx, dy));
    }
  }

  void returnToAtlas() {
    _traverse?.beginReturnTravel();
  }

  Future<void> _enterStarView(StaticStar star) async {
    if (_traverse == null) {
      return;
    }
    _traverse!.beginStarTravel(star);
    final snap = starSnapshot(star.id, star.label, star.accent);
    final resolved = resolveField(snap);

    for (final p in resolved.placements) {
      _emblems[p.realm.emblemAsset] ??= Sprite(
        await Flame.images.load(p.realm.emblemAsset),
      );
    }

    for (final n in _nodes) {
      n.removeFromParent();
    }
    _nodes.clear();
    _connectors?.reseat(resolved);
    _clusters?.visibleIds = {star.id};

    final withinCluster = <String, int>{};
    for (final p in resolved.placements) {
      final ei = withinCluster[p.cluster.id] ?? 0;
      withinCluster[p.cluster.id] = ei + 1;
      final node = RealmNode(
        placement: p,
        emblem: _emblems[p.realm.emblemAsset]!,
        motion: motion,
        index: _nodes.length,
        entryIndex: ei,
        onSelect: _select,
        onActivate: _activate,
        onHoverChanged: _onNodeHoverChanged,
      );
      _nodes.add(node);
      world.add(node);
    }

    _backButton?.star = star;
    _backButton?.realmCount = resolved.placements.length;
    field = resolved;
    _snapshot = snap;

    onStarView?.call(star.label, star.accent, resolved.placements.length);
  }

  set reducedMotion(bool value) => updateReduceMotion(value);

  void updatePalette(KidunaColors palette) {
    _palette = palette;
  }

  void updateReduceMotion(bool reduceMotion) {
    if (reduceMotion == _reduceMotion) return;
    _reduceMotion = reduceMotion;
    motion.reduced = reduceMotion;
    if (reduceMotion) {
      _t = 0;
      pauseEngine();
    } else {
      resumeEngine();
    }
  }

  @override
  void onRemove() {
    source?.dispose();
    super.onRemove();
  }
}
