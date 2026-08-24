import 'dart:math' show max;

import 'package:flame/game.dart';
import 'package:flutter/gestures.dart'
    show
        PointerPanZoomStartEvent,
        PointerPanZoomUpdateEvent,
        PointerScrollEvent,
        PointerSignalEvent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HardwareKeyboard;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/field_realm.dart';
import '../../../shared/layouts/responsive_layout.dart';
import '../../../shared/models/section_item.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/section_bar.dart';
import '../../../shared/widgets/section_placeholder.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../exchange/screens/exchange_screen.dart';
import '../controllers/ecosystem_controller.dart';
import '../controllers/field_controller.dart';
import '../data/field_composition.dart';
import '../data/gravity_field_source.dart';
import '../data/placement.dart' show Placement;
import '../data/realm_atlas.dart';
import '../game/enamel_tokens.dart' show DistanceBand, Gravity;
import '../game/field_game.dart';
import '../widgets/realm_detail_popup.dart';
import '../widgets/field_chrome_panels.dart';
import '../widgets/field_working_panels.dart';
import '../widgets/ki_region.dart';
import '../widgets/nav_mode.dart';
import '../widgets/realm_context_pill.dart';

/// The main app screen. The header and section bar sit at the top; the active
/// section's content fills the remaining space with Ki alongside.
///
/// * Exchange (index 0, default) — presale exchange UI.
/// * Studio  (index 3) — the original NCEV field with panels and Ki.
/// * Others  — "Coming Soon" placeholder with Ki.
///
/// Existing widgets (_FieldKiWide, _FieldKiNarrow, _RealmIdentity, _Boundary)
/// are untouched below. FieldStack uses FieldGame (Flame) with gravity-based
/// placement via GravityFieldSource.
class FieldScreen extends StatefulWidget {
  const FieldScreen({super.key});

  @override
  State<FieldScreen> createState() => _FieldScreenState();
}

class _FieldScreenState extends State<FieldScreen> {
  /// Active section index. Exchange (0) is the default.
  int _activeSection = SectionIndex.exchange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.kiduna.field,
      body: Column(
        children: [
          const AppHeader(),
          SectionBar(
            sections: kSections,
            activeIndex: _activeSection,
            onChanged: (i) => setState(() => _activeSection = i),
          ),
          Expanded(child: _buildSectionContent()),
        ],
      ),
    );
  }

  Widget _buildSectionContent() {
    switch (_activeSection) {
      case SectionIndex.studio:
        // Original NCEV — existing layout, untouched.
        return ResponsiveLayout(
          desktop: (_) => const _FieldKiWide(),
          mobile: (_) => const _FieldKiNarrow(),
        );
      case SectionIndex.exchange:
        // Presale exchange UI with Ki chat.
        return ResponsiveLayout(
          desktop: (_) => const _ContentKiWide(content: ExchangeScreen()),
          mobile: (_) => const _ContentKiNarrow(content: ExchangeScreen()),
        );
      default:
        // Other sections: placeholder with Ki chat.
        final placeholder = SectionPlaceholder(
          sectionName: kSections[_activeSection].label,
        );
        return ResponsiveLayout(
          desktop: (_) => _ContentKiWide(content: placeholder),
          mobile: (_) => _ContentKiNarrow(content: placeholder),
        );
    }
  }
}

/// Desktop layout for non-Studio sections: content + boundary + Ki side by side.
/// Mirrors _FieldKiWide but accepts any content widget instead of _FieldStack.
class _ContentKiWide extends ConsumerWidget {
  const _ContentKiWide({required this.content});

  final Widget content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kiFraction = ref.watch(
      fieldControllerProvider.select((s) => s.kiFraction),
    );
    final boundaryW = context.metrics.boundaryWidth;
    return LayoutBuilder(
      builder: (context, constraints) {
        final total = constraints.maxWidth;
        final kiWidth = max(280.0, kiFraction * total);
        final contentWidth = max(0.0, total - boundaryW - kiWidth);
        return Row(
          children: [
            SizedBox(width: contentWidth, child: content),
            SizedBox(
              width: boundaryW,
              child: _Boundary(totalWidth: total),
            ),
            SizedBox(width: kiWidth, child: const KiRegion()),
          ],
        );
      },
    );
  }
}

/// Mobile layout for non-Studio sections: content on top, Ki below.
/// Mirrors _FieldKiNarrow but accepts any content widget.
class _ContentKiNarrow extends StatelessWidget {
  const _ContentKiNarrow({required this.content});

  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(flex: 3, child: content),
        const Expanded(flex: 2, child: KiRegion()),
      ],
    );
  }
}

class _FieldKiWide extends ConsumerWidget {
  const _FieldKiWide();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kiFraction = ref.watch(
      fieldControllerProvider.select((s) => s.kiFraction),
    );
    final boundaryW = context.metrics.boundaryWidth;
    return LayoutBuilder(
      key: const ValueKey('field-wide'),
      builder: (context, constraints) {
        final total = constraints.maxWidth;
        final kiWidth = max(280.0, kiFraction * total);
        final fieldWidth = max(0.0, total - boundaryW - kiWidth);
        return Row(
          children: [
            SizedBox(width: fieldWidth, child: const FieldStack()),
            SizedBox(
              width: boundaryW,
              child: _Boundary(totalWidth: total),
            ),
            SizedBox(width: kiWidth, child: const KiRegion()),
          ],
        );
      },
    );
  }
}

class _FieldKiNarrow extends StatelessWidget {
  const _FieldKiNarrow();

  @override
  Widget build(BuildContext context) {
    return const Column(
      key: ValueKey('field-narrow'),
      children: [
        Expanded(flex: 3, child: FieldStack()),
        Expanded(flex: 2, child: KiRegion()),
      ],
    );
  }
}

/// The Field canvas rendered via Flame with gravity-based realm placement.
class FieldStack extends ConsumerStatefulWidget {
  const FieldStack({super.key});

  @override
  ConsumerState<FieldStack> createState() => _FieldStackState();
}

class _FieldStackState extends ConsumerState<FieldStack> {
  FieldGame? _game;
  Key _gameKey = UniqueKey();
  bool _showEmptyState = false;
  bool _gameReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _game ??= _createGame();
  }

  FieldGame _createGame() {
    final auth = ref.read(authControllerProvider);
    final wallet = auth.user?.wallet ?? '';
    final name = auth.user?.name ?? 'You';
    final currentRealmId = ref.read(fieldControllerProvider).currentRealmId;
    return FieldGame(
      palette: context.kiduna,
      reduceMotion: MediaQuery.maybeOf(context)?.disableAnimations ?? false,
      source: GravityFieldSource(
        walletAddress: wallet,
        viewerName: name,
        currentRealmId: currentRealmId == 'kinship-duna'
            ? null
            : currentRealmId,
      ),
      nav: NavMode.traverse,
      hideStars: true,
      mousePanEnabled: false,
      scrollPanEnabled: false,
      onInspect: _onRealmSelected,
      onDeselect: () {
        ref.read(fieldControllerProvider.notifier).clearSelection();
      },
      onReady: () {
        final insideRealm = currentRealmId.isNotEmpty &&
            currentRealmId != 'kinship-duna';
        final isEmpty = insideRealm &&
            (_game?.snapshot?.realms.isEmpty ?? true);
        if (isEmpty != _showEmptyState || !_gameReady) {
          setState(() {
            _showEmptyState = isEmpty;
            _gameReady = true;
          });
        }
      },
    );
  }

  void _rebuildGame() {
    setState(() {
      _game = _createGame();
      _gameKey = UniqueKey();
      _showEmptyState = false;
      _gameReady = false;
    });
  }

  void _onRealmSelected(Placement p) {
    final atlasType = AtlasRealmType.values.firstWhere(
      (t) => t.name == p.realm.typeName,
      orElse: () => AtlasRealmType.organization,
    );
    final fieldPlacement = FieldPlacement(
      realm: AtlasRealm(
        id: p.realm.id,
        name: p.realm.name,
        type: atlasType,
        parent: p.realm.parentId,
        purpose: p.realm.purpose,
        motif: p.realm.motif,
      ),
      left: p.position.left,
      top: p.position.top,
      band: p.band == DistanceBand.near
          ? FieldBand.near
          : p.band == DistanceBand.middle
          ? FieldBand.middle
          : FieldBand.far,
      cluster: FieldClusterId.workWealth,
      mass: p.realm.mass,
      reason: p.realm.reason ?? '',
      rolePull: p.band == DistanceBand.near,
    );
    ref.read(fieldControllerProvider.notifier).selectAtlasRealm(fieldPlacement);
  }

  // ── Trackpad two-finger pan/zoom state ──
  double _trackpadBaseZoom = 1.0;

  void _onPointerPanZoomStart(PointerPanZoomStartEvent event) {
    final game = _game;
    if (game == null || !game.isLoaded) return;
    _trackpadBaseZoom = game.camera.viewfinder.zoom;
  }

  void _onPointerPanZoomUpdate(PointerPanZoomUpdateEvent event) {
    final game = _game;
    if (game == null || !game.isLoaded) return;

    // Two-finger pan — event.panDelta gives the translation delta.
    final pan = event.panDelta;
    if (pan.dx != 0 || pan.dy != 0) {
      game.panBy(Vector2(pan.dx, pan.dy));
    }

    // Pinch zoom — event.scale is 1.0 at rest, grows/shrinks with pinch.
    if (event.scale != 1.0) {
      final target = _trackpadBaseZoom * event.scale;
      final pointer = Vector2(event.localPosition.dx, event.localPosition.dy);
      game.zoomAt(
        pointer,
        target > game.camera.viewfinder.zoom ? 1 : -1,
        times: ((target - game.camera.viewfinder.zoom).abs() / 0.05).clamp(
          0.2,
          2.0,
        ),
      );
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    final game = _game;
    if (game == null || !game.isLoaded || event is! PointerScrollEvent) {
      return;
    }
    final d = event.scrollDelta;
    final k = HardwareKeyboard.instance;
    if (!k.isShiftPressed) {
      if (d.dy == 0) return;
      game.zoomAt(
        Vector2(event.localPosition.dx, event.localPosition.dy),
        d.dy < 0 ? 1 : -1,
        times: (d.dy.abs() / 40).clamp(0.4, 3),
      );
      return;
    }
    game.panBy(Vector2(-d.dx, -d.dy));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fieldControllerProvider);
    final controller = ref.read(fieldControllerProvider.notifier);
    final ecoState = ref.watch(ecosystemControllerProvider);
    final realmNames = ecoState.knownNames;

    ref.listen<String>(
      fieldControllerProvider.select((s) => s.currentRealmId),
      (previous, next) {
        if (previous != null && previous != next) {
          final eco = ref.read(ecosystemControllerProvider.notifier);
          if (next == 'kinship-duna') {
            eco.load();
          } else {
            eco.loadChildren(next);
          }
          _rebuildGame();
        }
      },
    );

    final realm = state.currentRealm;
    final opacity = (state.fieldFocus / 100).clamp(0.0, 1.0);

    return ClipRect(
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerPanZoomStart: _onPointerPanZoomStart,
        onPointerPanZoomUpdate: _onPointerPanZoomUpdate,
        onPointerSignal: _onPointerSignal,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bounds = Size(constraints.maxWidth, constraints.maxHeight);

            return Stack(
              children: [
                if (_game != null)
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: GameWidget(key: _gameKey, game: _game!),
                    ),
                  ),
                if (!_gameReady || ecoState.isLoading)
                  Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.kiduna.sky,
                    ),
                  ),
                if (_showEmptyState)
                  const Center(child: _EmptyRealmState()),
                _RealmIdentity(
                  realm: realm,
                  inspectOpen: state.inspectOpen,
                  onInspect: controller.toggleInspect,
                  bounds: bounds,
                  opacity: opacity,
                ),
                FieldChromePanels(
                  state: state,
                  controller: controller,
                  bounds: bounds,
                  opacity: opacity,
                  realmNames: realmNames,
                ),
                FieldWorkingPanels(
                  state: state,
                  controller: controller,
                  bounds: bounds,
                  opacity: opacity,
                ),
                if (state.selectedPlacement != null)
                  Positioned(
                    key: ValueKey('popup-${state.selectedRealmId}'),
                    right: 8,
                    bottom: 8,
                    child: Opacity(
                      opacity: opacity,
                      child: RealmDetailPopup(
                        placement: state.selectedPlacement!,
                        onClose: () {
                          _game?.clearSelection();
                        },
                        onEnter: (enterRealm) {
                          _game?.clearSelection();
                          controller.enterAtlasRealm(enterRealm);
                        },
                        onGravityChanged: (level) {
                          _game?.setGravity(
                            state.selectedRealmId!,
                            Gravity.of(level),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RealmIdentity extends StatelessWidget {
  const _RealmIdentity({
    required this.realm,
    required this.inspectOpen,
    required this.onInspect,
    required this.bounds,
    required this.opacity,
  });

  final FieldRealm realm;
  final bool inspectOpen;
  final VoidCallback onInspect;
  final Size bounds;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 22,
      left: 22,
      child: Opacity(
        opacity: opacity,
        child: RealmContextPill(
          realm: realm,
          inspectOpen: inspectOpen,
          onInspect: onInspect,
          width: (bounds.width * 0.4).clamp(320.0, 500.0),
        ),
      ),
    );
  }
}

/// The 7px resizable boundary between the Field region and Ki.
///
/// CSS: `.boundaryControl` — bg #100a06, camel left border, sky right border,
/// centered 2px×34px sky handle with glow.
class _Boundary extends ConsumerStatefulWidget {
  const _Boundary({required this.totalWidth});

  final double totalWidth;

  @override
  ConsumerState<_Boundary> createState() => _BoundaryState();
}

class _BoundaryState extends ConsumerState<_Boundary> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final skyHandle = _hovered
        ? colors.sky
        : colors.sky.withValues(alpha: 0.32);
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          final delta = -details.delta.dx / widget.totalWidth;
          final current = ref.read(fieldControllerProvider).kiFraction;
          ref
              .read(fieldControllerProvider.notifier)
              .setKiFraction(current + delta);
        },
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF100A06),
            border: Border(
              left: BorderSide(color: colors.camel.withValues(alpha: 0.18)),
              right: BorderSide(color: colors.sky.withValues(alpha: 0.12)),
            ),
          ),
          child: Center(
            child: Container(
              width: 2,
              height: 34,
              decoration: BoxDecoration(
                color: skyHandle,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 12,
                    color: colors.sky.withValues(alpha: 0.18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyRealmState extends StatelessWidget {
  const _EmptyRealmState();

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: colors.deep.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.sky.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bubble_chart_outlined, size: 40, color: colors.quiet),
          const SizedBox(height: 12),
          Text(
            context.l10n.noRealmsYet,
            style: context.kidunaText.heading.copyWith(
              color: colors.cream,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.noRealmsYetDetail,
            textAlign: TextAlign.center,
            style: context.kidunaText.bodySmall.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}
