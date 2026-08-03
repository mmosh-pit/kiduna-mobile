/// The Flame world that draws the Field.
///
/// Phase 2 rendered it, Phase 3 made it navigable, Phase 4 brought it alive.
/// Phase 5 makes it answer: hover reports standing, selection brightens the
/// paths that already exist, and Gravity re-seats the Field with a Gather.
library;

import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import '../../design/tokens.dart';
import '../events.dart';
import '../field_source.dart';
import '../models.dart';
import '../placement.dart';
import '../../demo/nav_mode.dart';
import 'camera_control.dart';
import 'cluster_layer.dart';
import 'connector_layer.dart';
import 'ground_layer.dart';
import 'motion.dart';
import 'realm_node.dart';
import 'star_layer.dart';

class FieldGame extends FlameGame
    with DragCallbacks, ScrollDetector, KeyboardEvents {
  FieldGame(
    this.source, {
    required this.onInspect,
    this.onReady,
    this.nav = NavMode.none,
  });

  final FieldSource source;

  /// Opens the inspection alert. The Field hands over a Placement and knows
  /// nothing about how it is presented.
  final void Function(Placement) onInspect;

  /// Fires once the snapshot has resolved, so Flutter chrome can read the
  /// Ecosystem name and Ally roster.
  final VoidCallback? onReady;

  /// Fires whenever the camera moves, so the navigator can follow it.
  VoidCallback? onCameraMoved;

  /// How much of the Field the viewport covers, 0–1 on each axis.
  Size get visibleFraction {
    final visible = size / camera.viewfinder.zoom;
    return Size(
      (visible.x / _worldSize.x).clamp(0.05, 1.0),
      (visible.y / _worldSize.y).clamp(0.05, 1.0),
    );
  }

  /// Prototype navigation, for judging the twenty-cluster question. Never
  /// reaches the contract.
  final NavMode nav;

  /// Current page in [NavMode.page].
  int page = 0;

  // ── Traverse: a bounded window of clusters, the rest as stars ──────────

  /// Index of the first cluster in the reachable window, in traverse mode.
  int _focus = 0;

  StarLayer? _stars;

  /// The travel currently in flight, and how far through it we are.
  int? _travelToFocus;
  double _travelT = 0;

  /// The clusters reachable right now. Everything else is a star.
  List<ClusterDef> get activeClusters {
    final all =
        _snapshot?.clusters.where((c) => !c.isBranch).toList() ?? const [];
    if (nav != NavMode.traverse || all.length <= clustersPerView) return all;
    final start = _focus.clamp(0, math.max(0, all.length - clustersPerView)).toInt();
    return all.skip(start).take(clustersPerView).toList();
  }

  List<ClusterDef> get _distantClusters {
    if (nav != NavMode.traverse) return const [];
    final active = activeClusters.map((c) => c.id).toSet();
    return (_snapshot?.clusters ?? const <ClusterDef>[])
        .where((c) => !c.isBranch && !active.contains(c.id))
        .toList();
  }

  Vector2 _worldCentreOf(ClusterDef c) => Vector2(
        c.left / 100 * _worldSize.x,
        c.top / 100 * _worldSize.y,
      );

  /// The rectangle the camera may not leave in traverse mode.
  ///
  /// This is what makes the brief literal: the other clusters are **not**
  /// reachable by panning. Scrolling left or right runs out of Field at the
  /// edge of the active window, and a star is the only way across.
  Rect? get _activeBounds {
    if (nav != NavMode.traverse) return null;
    final active = activeClusters;
    if (active.isEmpty) return null;
    var rect = Rect.fromCenter(
      center: Offset(_worldCentreOf(active.first).x,
          _worldCentreOf(active.first).y),
      width: active.first.radiusX * 2 / 100 * _worldSize.x,
      height: active.first.radiusY * 2 / 100 * _worldSize.y,
    );
    for (final c in active.skip(1)) {
      final centre = _worldCentreOf(c);
      rect = rect.expandToInclude(
        Rect.fromCenter(
          center: Offset(centre.x, centre.y),
          width: c.radiusX * 2 / 100 * _worldSize.x,
          height: c.radiusY * 2 / 100 * _worldSize.y,
        ),
      );
    }
    return rect.inflate(70);
  }

  /// Levels the Field is divided into, and which one is current.
  int get levelCount {
    final total =
        _snapshot?.clusters.where((c) => !c.isBranch).length ?? 0;
    if (total == 0) return 1;
    return ((total - 1) ~/ clustersPerView) + 1;
  }

  int get currentLevel => _focus ~/ clustersPerView;

  /// Travels to a cluster, or straight to a level.
  ///
  /// One dissolve, not a lurch. An earlier version dived the camera to 1.75×
  /// and back, which read as a lunge: the eye tracked the zoom rather than the
  /// arrival. Light carries the change instead, and the scale barely moves —
  /// nearer the canon's own Gather, which settles rather than announces.
  void travelTo(ClusterDef cluster) {
    final all =
        _snapshot?.clusters.where((c) => !c.isBranch).toList() ?? const [];
    final index = all.indexWhere((c) => c.id == cluster.id);
    if (index >= 0) _beginTravel(index);
  }

  void travelToLevel(int level) => _beginTravel(level * clustersPerView);

  void _beginTravel(int focus) {
    if (_travelToFocus != null) return;
    final all =
        _snapshot?.clusters.where((c) => !c.isBranch).length ?? 0;
    final target = focus.clamp(0, math.max(0, all - clustersPerView)).toInt();
    if (target == _focus) return;
    _travelToFocus = target;
    _travelT = 0;
  }

  /// How brightly the Field is drawn mid-travel. Flutter reads this and folds
  /// it into the Opacity that already wraps the game, so the dissolve costs no
  /// per-layer plumbing.
  double get travelFade => _travelFade;
  double _travelFade = 1;

  void _tickTravel(double dt) {
    final destination = _travelToFocus;
    if (destination == null) return;

    final was = _travelT;
    _travelT += dt / (motion.reduced ? 0.0001 : traverseTravelSeconds);

    // The window changes at the darkest point, so nothing is seen to swap.
    if (was < 0.5 && _travelT >= 0.5) {
      _focus = destination;
      _centreOnActive();
    }

    if (_travelT >= 1) {
      _travelToFocus = null;
      _travelT = 0;
      _travelFade = 1;
      _stars?.opacity = 1;
      _applyCamera(camera.viewfinder.position, traverseEnterZoom);
      return;
    }

    final t = _travelT;
    // Out, then in. Squared so the middle is genuinely dark and the ends are
    // unhurried, which is what keeps it from reading as a blink of its own.
    final half = t < 0.5 ? t * 2 : (1 - t) * 2;
    final fade = Verb.easeInOut(half.clamp(0.0, 1.0));
    _travelFade = 0.06 + 0.94 * (1 - (1 - fade) * (1 - fade));

    // A whisper of scale, in the direction of travel: out on the way, back on
    // arrival. Small enough to feel like depth rather than a zoom.
    final zoom = t < 0.5
        ? Verb.lerp(traverseEnterZoom, traverseDriftZoom, Verb.easeInOut(t * 2))
        : Verb.lerp(traverseArriveZoom, traverseEnterZoom,
            Verb.easeInOut((t - 0.5) * 2));
    _stars?.opacity = _travelFade;
    _applyCamera(camera.viewfinder.position, zoom);
  }

  /// Centres the camera on the active window.
  void _centreOnActive() {
    final bounds = _activeBounds;
    if (bounds == null) return;
    final visible = size / camera.viewfinder.zoom;
    camera.viewfinder.position = Vector2(
      bounds.center.dx - visible.x / 2,
      bounds.center.dy - visible.y / 2,
    );
  }

  int get pageCount {
    final total = _snapshot?.clusters.length ?? 0;
    return total == 0 ? 1 : ((total - 1) ~/ clustersPerPage) + 1;
  }

  /// True when zoomed out past the canon's floor, in collapse mode.
  bool get isCollapsed =>
      nav == NavMode.collapse && camera.viewfinder.zoom < collapseBelowZoom;

  /// Traverse never shows the whole Field: the window is always a handful of
  /// clusters, whatever the zoom.
  bool get isStarField => false;

  FieldSnapshot? get snapshot => _snapshot;

  /// The Field's clock. Freezing it is how reduced motion is honoured: every
  /// phase function returns its resting value, and nothing branches at the
  /// drawing site, so no information can be lost along the way.
  final Motion motion = Motion();

  ResolvedField? field;

  late GroundLayer _ground;
  ClusterLayer? _clusters;
  ConnectorLayer? _connectors;
  final List<RealmNode> _nodes = [];

  /// The Field's own extent in world units. Percent-of-Field resolves against
  /// this, so it is **not** the viewport: a Field with more orbits than fit
  /// comfortably on one screen is simply bigger, and the member pans across
  /// it. Making it viewport-sized was the mistake that forced twenty orbits to
  /// cram into one screen and made them illegible.
  Vector2 _worldSize = Vector2.all(1);

  /// How many orbits sit comfortably in one viewport. Above this the Field
  /// grows rather than compressing.
  static const _orbitsPerScreen = 5;

  /// Field extent as a multiple of the viewport, derived from orbit count.
  ///
  /// Derived, not sent: the source says how many clusters exist, and the
  /// client decides how much room they need — the same rule that keeps
  /// positions off the wire.
  double get worldScale {
    final orbits =
        _snapshot?.clusters.where((c) => !c.isBranch).length ?? _orbitsPerScreen;
    if (orbits <= _orbitsPerScreen) return 1;
    return math.sqrt(orbits / _orbitsPerScreen);
  }

  /// Where the viewport sits in the Field, 0–1 on each axis. Drives the
  /// navigator at the bottom.
  Vector2 get viewportFraction {
    final v = camera.viewfinder;
    final visible = size / v.zoom;
    final span = Vector2(
      math.max(1, _worldSize.x - visible.x),
      math.max(1, _worldSize.y - visible.y),
    );
    return Vector2(
      (v.position.x / span.x).clamp(0.0, 1.0),
      (v.position.y / span.y).clamp(0.0, 1.0),
    );
  }

  /// Moves the viewport to a fraction of the Field. Used by the navigator.
  void jumpTo(Vector2 fraction) {
    final visible = size / camera.viewfinder.zoom;
    _applyCamera(
      Vector2(
        fraction.x * math.max(0, _worldSize.x - visible.x),
        fraction.y * math.max(0, _worldSize.y - visible.y),
      ),
      camera.viewfinder.zoom,
    );
  }

  /// Steps one viewport-width across the Field — the "next orbits" move.
  void stepView(int dx, int dy) {
    final visible = size / camera.viewfinder.zoom;
    panBy(Vector2(-dx * visible.x * 0.85, -dy * visible.y * 0.85));
  }

  final Set<LogicalKeyboardKey> _held = {};
  Vector2 _pointer = Vector2.zero();

  FieldSnapshot? _snapshot;
  RealmNode? _selected;

  /// Viewer-set Gravity overrides, layered over what the snapshot supplied.
  final Map<String, Gravity> _gravity = {};

  /// CameraChanged is emitted on a trailing edge rather than per frame — a
  /// pan produces hundreds of intermediate positions nobody needs.
  double _cameraDirtyFor = 0;

  @override
  Color backgroundColor() => Enamel.deepField;

  @override
  Future<void> onLoad() async {
    // Our assets live under assets/, not Flame's default assets/images/.
    Flame.images.prefix = '';

    // The Field is laid out in viewport pixels from the top-left, the way the
    // reference positions percent-based elements inside its container. Flame
    // centres the viewfinder on world origin by default, which would push the
    // whole composition off the bottom-right.
    camera.viewfinder.anchor = Anchor.topLeft;

    // Ground is the lacquer of the display, not an object in the Field. Put it
    // in the backdrop so it stays viewport-fixed: it never reveals an edge on
    // zoom-out, and it cannot drift on its own — which the canon prohibits.
    _ground = GroundLayer(motion);
    camera.backdrop.add(_ground);

    final snapshot = await source.load();
    _snapshot = snapshot;
    _gravity.addAll(snapshot.viewer.gravity);
    final resolved = resolveField(snapshot);
    field = resolved;

    // One sprite per Realm type, shared by every node of that type.
    final emblems = <String, Sprite>{};
    for (final placement in resolved.placements) {
      final path = placement.realm.emblemAsset;
      emblems[path] ??= Sprite(await Flame.images.load(path));
    }

    _clusters = ClusterLayer(resolved.clusters, motion);
    // What each star holds. Counted from placements rather than sent, like
    // every other derived quantity.
    final counts = <String, int>{};
    for (final placement in resolved.placements) {
      counts.update(placement.cluster.id, (n) => n + 1, ifAbsent: () => 1);
    }
    _clusters!.realmCounts = counts;

    // The star border lives on the viewport, so it never pans or scales with
    // the Field it is offering to leave.
    if (nav == NavMode.traverse) {
      _stars = StarLayer(motion);
      camera.viewport.add(_stars!);
      _centreOnActive();
    }
    _connectors = ConnectorLayer(resolved, motion);
    world
      ..add(_clusters!)
      ..add(_connectors!);

    // Draw far first so near Realms sit above their quieter context.
    const order = [DistanceBand.far, DistanceBand.middle, DistanceBand.near];
    final withinCluster = <String, int>{};
    for (final band in order) {
      for (final placement in resolved.placements) {
        if (placement.band != band) continue;
        final clusterId = placement.cluster.id;
        final entryIndex = withinCluster[clusterId] ?? 0;
        withinCluster[clusterId] = entryIndex + 1;
        final node = RealmNode(
          placement: placement,
          emblem: emblems[placement.realm.emblemAsset]!,
          motion: motion,
          index: _nodes.length,
          entryIndex: entryIndex,
          onSelect: _select,
          onActivate: _activate,
        );
        _nodes.add(node);
        world.add(node);
      }
    }

    _layout();
    onReady?.call();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _layout();
  }

  /// Percent-of-Field is resolved against the current viewport, so the
  /// composition reflows on resize rather than letterboxing.
  ///
  /// Zoom and pan are a transform *on top* of this base layout, exactly as the
  /// reference applies `translate() scale()` to a percent-positioned container.
  void _layout() {
    _worldSize = size * worldScale;
    _ground.size = size;
    _clusters?.size = _worldSize;
    // The star border is viewport-space, so it takes the screen's size, not
    // the Field's.
    _stars?.size = size.clone();
    _connectors?.size = _worldSize;
    for (final node in _nodes) {
      node.worldSize = _worldSize;
    }
    _applyCamera(camera.viewfinder.position, camera.viewfinder.zoom);
  }

  // ── Camera ────────────────────────────────────────────────────────────

  void _applyCamera(Vector2 position, double zoom) {
    final clampedZoom = switch (nav) {
      NavMode.collapse => zoom.clamp(demoMinZoom, Cam.maxZoom).toDouble(),
      // The dissolve dips just under the canon's floor for a moment, so
      // traverse takes a slightly wider clamp while a travel is in flight.
      NavMode.traverse => zoom
          .clamp(math.min(Cam.minZoom, traverseDriftZoom), Cam.maxZoom)
          .toDouble(),
      _ => Cam.clampZoom(zoom),
    };
    // In traverse the camera is confined to the active window. This is the
    // whole point of the mode: scrolling left or right cannot reach a cluster
    // that is currently a star.
    final bounds = _activeBounds;
    camera.viewfinder.zoom = clampedZoom;
    if (bounds != null) {
      final visible = size / clampedZoom;
      double axis(double value, double lo, double hi, double extent) {
        if (extent >= hi - lo) return lo + (hi - lo - extent) / 2;
        return value.clamp(lo, hi - extent);
      }

      camera.viewfinder.position = Vector2(
        axis(position.x, bounds.left, bounds.right, visible.x),
        axis(position.y, bounds.top, bounds.bottom, visible.y),
      );
    } else {
      camera.viewfinder.position = Cam.clampPosition(
        position: position,
        world: _worldSize,
        viewport: size,
        zoom: clampedZoom,
      );
    }
    // Labels resolve by distance: zooming in lets the far band earn its type.
    final collapsed = isCollapsed;
    final stars = isStarField;
    for (final node in _nodes) {
      node.zoom = clampedZoom;
      node.hidden =
          collapsed || stars || !_onCurrentPage(node.placement.cluster.id);
    }
    _clusters?.collapsed = collapsed;
    _clusters?.starField = stars;
    _clusters?.visibleIds = _visibleClusterIds();
    if (_stars != null) {
      final distant = _distantClusters;
      _stars!
        ..distant = distant
        ..worldCentres = {
          for (final c in distant) c.id: _worldCentreOf(c),
        }
        ..origin = Vector2(
          (_activeBounds?.center.dx ?? _worldSize.x / 2),
          (_activeBounds?.center.dy ?? _worldSize.y / 2),
        );
    }
    _cameraDirtyFor = 0.25;
    onCameraMoved?.call();
  }

  void panBy(Vector2 screenDelta) => _applyCamera(
        Cam.panned(
          position: camera.viewfinder.position,
          screenDelta: screenDelta,
          zoom: camera.viewfinder.zoom,
        ),
        camera.viewfinder.zoom,
      );

  /// Zoom anchored on a screen point, so the world under the cursor stays put.
  void zoomAt(Vector2 pointer, double direction, {double times = 1}) {
    final from = camera.viewfinder.zoom;
    final to = Cam.stepZoom(from, direction, times: times);
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

  void resetCamera() => _applyCamera(Vector2.zero(), 1);

  bool _onCurrentPage(String clusterId) {
    if (nav == NavMode.traverse) {
      return activeClusters.any((c) => c.id == clusterId);
    }
    if (nav != NavMode.page) return true;
    final ids = _snapshot?.clusters.map((c) => c.id).toList() ?? const [];
    final start = page * clustersPerPage;
    return ids.indexOf(clusterId) >= start &&
        ids.indexOf(clusterId) < start + clustersPerPage;
  }

  Set<String>? _visibleClusterIds() {
    if (nav == NavMode.traverse) {
      return activeClusters.map((c) => c.id).toSet();
    }
    if (nav != NavMode.page) return null;
    final ids = _snapshot?.clusters.map((c) => c.id).toList() ?? const [];
    final start = page * clustersPerPage;
    return ids.skip(start).take(clustersPerPage).toSet();
  }

  /// Steps the page in [NavMode.page]. The comparison exists to show what this
  /// costs: nothing on another page is present, and its position tells you
  /// nothing once you return.
  void turnPage(int delta) {
    page = (page + delta) % pageCount;
    if (page < 0) page += pageCount;
    _applyCamera(camera.viewfinder.position, camera.viewfinder.zoom);
  }

  // ── Input ─────────────────────────────────────────────────────────────

  // A click is a zero-distance drag. Because the game itself owns
  // DragCallbacks, the gesture never reaches a child's TapCallbacks — hover
  // arrives but tap does not. Recognising the tap inside the drag lifecycle is
  // reliable precisely because these are the events that do fire.
  Vector2? _pressAt;
  double _pressTravel = 0;

  /// Below this, the pointer did not really move and the gesture was a tap.
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
    // 1:1 with the pointer, no easing lag.
    panBy(event.localDelta);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    final at = _pressAt;
    _pressAt = null;
    if (at == null || _pressTravel > _tapSlop) return;

    // A star sits on the viewport, not in the world, so it is hit-tested in
    // screen space and takes priority over anything behind it.
    if (nav == NavMode.traverse) {
      final star = _stars?.starAt(at);
      if (star != null) {
        travelTo(star);
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


  /// The topmost Realm under a canvas point. Nodes are added far-first so the
  /// near band draws on top; searching in reverse honours that.
  RealmNode? _realmAt(Vector2 canvasPoint) {
    final v = camera.viewfinder;
    final world = v.position + canvasPoint / v.zoom;
    for (final node in _nodes.reversed) {
      final half = node.size / 2;
      final d = world - node.position;
      if (d.x.abs() <= half.x && d.y.abs() <= half.y) return node;
    }
    return null;
  }

  @override
  void onScroll(PointerScrollInfo info) {
    _pointer = info.eventPosition.widget;
    final delta = info.scrollDelta.global;

    // Ctrl or Cmd plus scroll is zoom — and browsers report trackpad pinch as
    // exactly that, so pinch-to-zoom arrives here too.
    final keys = HardwareKeyboard.instance;
    if (keys.isControlPressed || keys.isMetaPressed) {
      if (delta.y == 0) return;
      zoomAt(_pointer, delta.y < 0 ? 1 : -1, times: (delta.y.abs() / 40).clamp(0.4, 3));
      return;
    }
    // Otherwise two-finger scroll pans the Field directly.
    panBy(-delta);
  }

  @override
  void onMount() {
    super.onMount();
    // Track the pointer so keyboard zoom can anchor sensibly when it has never
    // moved: default to the viewport centre.
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
        resetCamera();
      case LogicalKeyboardKey.equal:
      case LogicalKeyboardKey.add:
      case LogicalKeyboardKey.numpadAdd:
        zoomAt(size / 2, 1);
      case LogicalKeyboardKey.minus:
      case LogicalKeyboardKey.numpadSubtract:
        zoomAt(size / 2, -1);
      case LogicalKeyboardKey.escape:
        // Escape clears Focus without destroying the underlying Realm context.
        clearSelection();
      default:
        break;
    }
    return KeyEventResult.handled;
  }

  static final _panLeft = {LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA};
  static final _panRight = {LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD};
  static final _panUp = {LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyW};
  static final _panDown = {LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyS};

  // ── Selection ─────────────────────────────────────────────────────────

  /// Selection is **inspection, never entry**. It brightens paths that already
  /// exist and updates context. Nothing is joined, granted, or entered.
  void _select(RealmNode node) {
    if (_selected == node) return;
    _selected?.selected = false;
    _selected = node..selected = true;
    _connectors?.select(node.placement.realm.id);
    source.emit(RealmSelected(node.placement.realm.id, DateTime.now()));
  }

  /// Explicit intent on a Realm: opens inspection. Still **not entry** — there
  /// is no RealmEntered event, deliberately.
  void _activate(RealmNode node) {
    source.emit(RealmActivated(node.placement.realm.id, DateTime.now()));
    onInspect(node.placement);
  }

  void clearSelection() {
    if (_selected == null) return;
    _selected!.selected = false;
    _selected = null;
    _connectors?.select(null);
    source.emit(RealmDeselected(DateTime.now()));
  }

  Placement? get selection => _selected?.placement;

  // ── Gravity ───────────────────────────────────────────────────────────

  /// Gravity changes **presentation only** — never authority, membership, or
  /// truth. It re-runs the pull, and every Realm affected travels to its new
  /// place over 900ms, crossing distance bands as it goes.
  void setGravity(String realmId, Gravity next) {
    final snapshot = _snapshot;
    if (snapshot == null) return;
    final previous = _gravity[realmId] ?? Gravity.quiet;
    if (previous == next) return;
    _gravity[realmId] = next;

    final reseated = resolveField(
      FieldSnapshot(
        schemaVersion: snapshot.schemaVersion,
        viewer: Viewer(
          id: snapshot.viewer.id,
          displayName: snapshot.viewer.displayName,
          allyId: snapshot.viewer.allyId,
          relationship: snapshot.viewer.relationship,
          roles: snapshot.viewer.roles,
          gravity: Map.of(_gravity),
        ),
        ecosystem: snapshot.ecosystem,
        realms: snapshot.realms,
        clusters: snapshot.clusters,
        allies: snapshot.allies,
        bridges: snapshot.bridges,
        currentPathTargetId: snapshot.currentPathTargetId,
      ),
    );
    field = reseated;

    for (final node in _nodes) {
      final next = reseated.byId(node.placement.realm.id);
      if (next != null) node.reseat(next);
    }
    _connectors?.reseat(reseated);
    if (_selected != null) {
      _connectors?.select(_selected!.placement.realm.id);
    }

    source.emit(GravityChanged(realmId, previous, next, DateTime.now()));
  }

  Gravity gravityOf(String realmId) => _gravity[realmId] ?? Gravity.quiet;

  /// The Ki focus dimmer. **Opacity only** — never Ki context, visibility,
  /// authority, relationship truth, or underlying data.
  void setFieldFocus({required bool dimmed}) =>
      source.emit(FieldFocusChanged(dimmed, DateTime.now()));

  // ── Field state ───────────────────────────────────────────────────────

  /// The Field's current state, and the motion verb it selects.
  ///
  /// | State | Verb | What changes |
  /// |---|---|---|
  /// | **Open** | Breathe | resting; a Realm remains available |
  /// | **Engaged** | Relate | existing paths brighten — no new path appears |
  /// | **Focused** | Gather | everything re-settles over 900ms, 135ms stagger |
  /// | **Dreaming** | Drift | possibility wanders; nothing is asked of anyone |
  ///
  /// State is **context, not identity** — the same rule the Ally system runs
  /// on. It may change how brightly a relationship is drawn and how the Field
  /// moves. It may never change what exists, who may do what, or what any
  /// object *is*. That is why nothing below touches the snapshot, the roles,
  /// the Gravity map, or the connector set.
  AllyState get fieldState => _fieldState;
  AllyState _fieldState = AllyState.open;

  set fieldState(AllyState next) {
    if (_fieldState == next) return;
    _fieldState = next;

    // Relate brightens what is already lit. It cannot invent a path, so it is
    // expressed as a luminance multiplier and nothing else.
    _connectors?.relate = next == AllyState.engaged;

    // Gather is a real re-settle: the clock rewinds and every Realm arrives
    // again, staggered. Nothing moves position — arrival is the whole event.
    if (next == AllyState.focused) {
      motion.restart();
      for (final node in _nodes) {
        node.regather();
      }
    }

    // Drift is the ground's own wander, widened. The canon's ceiling is ±8px
    // over 14–18s and the resting Field sits far under it, so Dreaming is the
    // one state allowed to approach the ceiling.
    _ground.driftScale = next == AllyState.dreaming ? 1 : 0.42;

    source.emit(FieldStateChanged(next.name, DateTime.now()));
    onCameraMoved?.call();
  }

  /// Requested by the OS, or forced with `?motion=off` for review.
  set reducedMotion(bool value) => motion.reduced = value;

  bool get reducedMotion => motion.reduced;

  @override
  void update(double dt) {
    super.update(dt);
    motion.tick(dt);
    _tickTravel(dt);

    if (_cameraDirtyFor > 0) {
      _cameraDirtyFor -= dt;
      if (_cameraDirtyFor <= 0) {
        final v = camera.viewfinder;
        source.emit(
          CameraChanged(v.position.x, v.position.y, v.zoom, DateTime.now()),
        );
      }
    }

    if (_held.isEmpty) return;

    final step = Cam.keyPanPerSecond * dt;
    var dx = 0.0;
    var dy = 0.0;
    if (_held.any(_panLeft.contains)) dx += step;
    if (_held.any(_panRight.contains)) dx -= step;
    if (_held.any(_panUp.contains)) dy += step;
    if (_held.any(_panDown.contains)) dy -= step;
    if (dx != 0 || dy != 0) panBy(Vector2(dx, dy));
  }

  @override
  void onRemove() {
    source.dispose();
    super.onRemove();
  }
}
