import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'catalog/catalog_page.dart';
import 'demo/field_navigator.dart';
import 'demo/field_state_bar.dart';
import 'demo/level_bar.dart';
import 'demo/possible_actions_panel.dart';
import 'demo/nav_mode.dart';
import 'design/tokens.dart';
import 'design/typography.dart';
import 'field/inspect_dialog.dart';
import 'field/mock_source.dart';
import 'field/placement.dart';
import 'field/render/field_game.dart';
import 'ki/ki_panel.dart';
import 'ki/ki_voice.dart';

void main() {
  // `?clusters=3` narrows the traverse window. Prototype knob, not contract.
  final n = int.tryParse(Uri.base.queryParameters['clusters'] ?? '');
  if (n != null && n >= 1 && n <= 12) clustersPerView = n;
  runApp(const AevApp());
}

/// Kiduna Studio · Advanced Ecosystem View.
///
/// Phase 6 · Ki. The Flame world runs full bleed, edge to edge, with no chrome
/// boxing it in. Ki floats above it as a movable panel — never a Field object,
/// never scaled by the camera.
class AevApp extends StatelessWidget {
  const AevApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Material is the base only for its plumbing — Directionality, MediaQuery,
    // text scaling, and the AlertDialog inspection uses. All Studio chrome is
    // drawn from Kiduna tokens; no Material colour reaches the surface.
    return MaterialApp(
      title: 'Kiduna Studio · AEV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Enamel.deepField,
        canvasColor: Enamel.deepField,
        splashFactory: NoSplash.splashFactory,
        highlightColor: const Color(0x00000000),
      ),
      // `?view=catalog` opens the Field Catalog: every element, every state,
      // drawn by the same code that draws the Field.
      home: Uri.base.queryParameters['view'] == 'catalog'
          ? const CatalogPage()
          : const FieldScreen(),
    );
  }
}

class FieldScreen extends StatefulWidget {
  const FieldScreen({super.key});

  @override
  State<FieldScreen> createState() => _FieldScreenState();
}

class _FieldScreenState extends State<FieldScreen> {
  late final FieldGame _game = FieldGame(
    MockFieldSource(_fixtureFromUrl()),
    onInspect: _inspect,
    onReady: _redraw,
    // Panning is the navigation. `?nav=collapse` additionally merges orbits
    // into super-clusters below 0.7× — kept reachable for comparison, not the
    // default.
    nav: NavMode.fromUrl(Uri.base.queryParameters['nav']),
  )..onCameraMoved = _onCameraMoved;

  void _onCameraMoved() => _redraw();

  /// Flame drives `onGameResize` from inside its own `LayoutBuilder`, so the
  /// first camera application of every resize lands *during* the build phase —
  /// where `setState` is illegal and takes the whole `GameWidget` subtree down
  /// with it. The chrome that reads the camera (the navigator, Ki) only needs
  /// to be correct by the next frame, so deferring costs nothing and the
  /// direct path stays synchronous for ordinary pans.
  void _redraw() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return;
    }
    setState(() {});
  }

  /// The Realm whose Possible Actions are on offer. Selection seeds it; the
  /// live AEV seeds it with the current Realm and re-seeds on every select.
  Placement? _offering;

  /// Field opacity. This is the **entire** effect of Field focus.
  double _fieldFocus = 1;

  KiLine? _kiOverride;

  KiLine get _kiLine {
    final override = _kiOverride;
    if (override != null) return override;
    final snapshot = _game.snapshot;
    if (snapshot == null) return KiVoice.field('This Ecosystem', 'Source');
    if (snapshot.realms.isEmpty) return KiVoice.empty;
    return KiVoice.field(snapshot.ecosystem.name, snapshot.viewer.displayName);
  }

  /// Selection opens the alert and gives Ki its context. Ki reports standing;
  /// it never claims the Source's authority, and it never speaks as "I".
  Future<void> _inspect(Placement placement) async {
    setState(() {
      _kiOverride = KiVoice.realm(placement);
      _offering = placement;
    });
    await showInspectAlert(
      context,
      placement: placement,
      gravity: _game.gravityOf(placement.realm.id),
      onGravity: (g) => _game.setGravity(placement.realm.id, g),
      onDismissed: () {
        _game.clearSelection();
        setState(() => _kiOverride = null);
      },
    );
  }

  /// `?fixture=edge` swaps the fixture without a rebuild. Handy for reviewing
  /// the empty and degradation cases, and the seed of the Phase 7 catalog.
  static Fixture _fixtureFromUrl() {
    final name = Uri.base.queryParameters['fixture'];
    return Fixture.values.firstWhere(
      (f) => f.name == name,
      orElse: () => Fixture.alice,
    );
  }

  /// `?motion=off` forces reduced motion so it can be reviewed without
  /// changing an OS setting.
  static bool get _motionForcedOff =>
      Uri.base.queryParameters['motion'] == 'off';

  /// Ki is **hidden by default for now** — the Field is being reviewed on its
  /// own. `?ki=on` brings the panel back. Nothing about Ki was removed: the
  /// panel, its voice rules and its tests are all still here, and flipping
  /// this default is the whole change.
  static bool get _kiHidden => Uri.base.queryParameters['ki'] != 'on';

  @override
  Widget build(BuildContext context) {
    // The OS accessibility setting is authoritative; the query parameter only
    // adds a way to force it on for review.
    _game.reducedMotion =
        MediaQuery.disableAnimationsOf(context) || _motionForcedOff;

    return Scaffold(
      backgroundColor: Enamel.deepField,
      body: Stack(
        children: [
          // Field focus is applied here and nowhere else. Wrapping the Field in
          // an Opacity makes the rule true by construction: this control is
          // structurally incapable of changing visibility, authority,
          // relationship truth, or any underlying data — only how brightly the
          // Field is drawn.
          Positioned.fill(
            child: Opacity(
              // Field focus and the traverse dissolve are the only two things
              // allowed to touch this, and they multiply rather than fight.
              opacity: _fieldFocus * _game.travelFade,
              child: GameWidget(game: _game),
            ),
          ),
          // The Field is larger than the viewport whenever it holds more
          // orbits than fit. This shows which part you are looking at and
          // moves you — it is not paging: every orbit is always present, and
          // keeps its place.
          // The navigator promises "drag the map, or pan the Field", which is
          // exactly what traverse takes away — there, a star is the only way
          // across, so offering a map would misdescribe the mode.
          if ((_game.snapshot?.clusters.length ?? 0) > 6 &&
              _game.nav != NavMode.traverse)
            FieldNavigator(
              clusters: _game.snapshot!.clusters,
              viewport: _game.viewportFraction,
              visibleFraction: _game.visibleFraction,
              onJump: _game.jumpTo,
              onStep: _game.stepView,
            ),
          // Traverse hides most of the Field, so the member is told plainly
          // how many windows exist and which one they are in.
          if (_game.nav == NavMode.traverse && _game.levelCount > 1)
            LevelBar(
              count: _game.levelCount,
              current: _game.currentLevel,
              onSelect: _game.travelToLevel,
            ),
          // `?state=on` brings up the Field-state control. Off by default:
          // in the product the state follows context, and a switch would
          // misdescribe that.
          if (Uri.base.queryParameters['state'] == 'on')
            FieldStateBar(
              current: _game.fieldState,
              onSelect: (s) => setState(() => _game.fieldState = s),
            ),
          // `?actions=on` shows Possible Actions for the selected Realm.
          if (Uri.base.queryParameters['actions'] == 'on' && _offering != null)
            PossibleActionsPanel(
              realmName: _offering!.realm.name,
              realmType: _offering!.realm.type?.label ?? 'Realm',
              role: _game.snapshot?.viewer.roles[_offering!.realm.id],
              onAction: (a) => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Enamel.raisedUmber,
                  content: Text(
                    // Offers only. Nothing here executes — the command
                    // boundary owns that, and a panel that appeared to act
                    // would misplace where authority lives.
                    '${a.label} — offered, not performed. '
                    'Actions execute behind the command boundary.',
                    style: Type.body,
                  ),
                ),
              ),
              onClose: () => setState(() => _offering = null),
            ),
          if (!_kiHidden)
            KiPanel(
              line: _kiLine,
              focus: _fieldFocus,
              allies: _game.snapshot?.allies.length ?? 0,
              onFocus: (value) {
                setState(() => _fieldFocus = value);
                _game.setFieldFocus(dimmed: value < 1);
              },
            ),
        ],
      ),
    );
  }
}
