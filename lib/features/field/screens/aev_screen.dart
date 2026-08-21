import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/responsive.dart';
import '../../../shared/widgets/app_header.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/field_controller.dart';
import '../data/gravity_field_source.dart';
import '../data/placement.dart';
import '../game/field_game.dart';
import '../widgets/compute_card.dart';
import '../widgets/enamel_icon.dart';
import '../widgets/field_panel.dart';
import '../widgets/field_working_panels.dart';
import '../widgets/inspect_panel.dart';
import '../widgets/nav_mode.dart';
import '../widgets/navigation_panel.dart';
import '../widgets/possible_actions.dart';
import '../widgets/realm_context_pill.dart';
import '../widgets/realm_detail_popup.dart';

// One-off Ki-rail ground values from the prototype `.kiRegion`.
const Color _kiGround = Color(0xFF100B08);

/// The Advanced Ecosystem View (AEV) — recreation of the prototype's
/// `T1 · S1 · 1.1`.
///
/// Desktop-first, mirroring the prototype: the full view needs at least
/// [Breakpoints.desktop] px of width; below that a "reopen wider" notice is
/// shown. On desktop the Field (constellation + overlaid panels) and Ki sit
/// side by side.
///
/// First pass: the constellation, overlaid panels, and Ki rail render with the
/// prototype's fixture content. Panel dragging works; pan/zoom, node selection,
/// and the gravity slider are wired in a following pass.
class AevScreen extends StatelessWidget {
  const AevScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.kiduna.field,
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < Breakpoints.desktop) {
                  return const _NarrowWarning();
                }
                return const _AevWorkspace();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The Field / boundary / Ki split.
class _AevWorkspace extends StatelessWidget {
  const _AevWorkspace();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(flex: 70, child: _AevField()),
        _Boundary(),
        Expanded(flex: 30, child: _AevKi()),
      ],
    );
  }
}

class _AevField extends ConsumerStatefulWidget {
  const _AevField();

  @override
  ConsumerState<_AevField> createState() => _AevFieldState();
}

class _AevFieldState extends ConsumerState<_AevField> {
  FieldGame? _game;
  Key _gameKey = UniqueKey();
  Placement? _selectedPlacement;
  String? _starLabel;
  Color? _starAccent;
  int _starRealmCount = 0;
  String? _currentRealmId;
  String? _currentRealmName;
  bool _showEmptyState = false;

  bool get _inStarView => _starLabel != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_game == null) {
      _game = _createGame(reduceMotion);
    } else {
      _game!.reducedMotion = reduceMotion;
    }
  }

  FieldGame _createGame(bool reduceMotion) {
    final auth = ref.read(authControllerProvider);
    final wallet = auth.user?.wallet ?? '';
    final name = auth.user?.name ?? 'You';
    AppLogger.debug(
      'Creating FieldGame — wallet="${wallet.isEmpty ? "(empty)" : "${wallet.substring(0, 8)}…"}"',
      tag: 'AevScreen',
    );
    final insideRealm = _currentRealmId != null;
    return FieldGame(
      palette: context.kiduna,
      reduceMotion: reduceMotion,
      source: GravityFieldSource(
        walletAddress: wallet,
        viewerName: name,
        currentRealmId: _currentRealmId,
      ),
      nav: NavMode.traverse,
      hideStars: true,
      onInspect: (placement) {
        setState(() {
          _selectedPlacement = placement;
        });
      },
      onDeselect: () {
        setState(() {
          _selectedPlacement = null;
        });
      },
      onStarView: (label, accent, count) {
        setState(() {
          _starLabel = label;
          _starAccent = accent;
          _starRealmCount = count;
        });
      },
      onReady: () {
        if (insideRealm) {
          final isEmpty = _game?.snapshot?.realms.isEmpty ?? true;
          if (isEmpty) {
            setState(() {
              _showEmptyState = true;
            });
          }
        }
      },
    );
  }

  void _rebuildGame() {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    _gameKey = UniqueKey();
    _game = _createGame(reduceMotion);
  }

  void _enterRealm(String realmId, String realmName) {
    ref.read(fieldControllerProvider.notifier).enterRealm(realmId, realmName);
    setState(() {
      _currentRealmId = realmId;
      _currentRealmName = realmName;
      _selectedPlacement = null;
      _showEmptyState = false;
      _rebuildGame();
    });
  }

  void _exitRealm() {
    ref.read(fieldControllerProvider.notifier).exitEnteredRealm();
    setState(() {
      _currentRealmId = null;
      _currentRealmName = null;
      _selectedPlacement = null;
      _starLabel = null;
      _showEmptyState = false;
      _rebuildGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FieldState>(fieldControllerProvider, (prev, next) {
      final hadRealm = prev?.openActions.contains('realm') ?? false;
      final hasRealm = next.openActions.contains('realm');
      if (hadRealm && !hasRealm) {
        _rebuildGame();
      }
    });

    final state = ref.watch(fieldControllerProvider);
    final controller = ref.read(fieldControllerProvider.notifier);
    final realm = state.currentRealm;
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bounds = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: GameWidget(key: _gameKey, game: _game!),
              ),
            ),
            if (_inStarView)
              _StarViewHeader(
                label: _starLabel!,
                accent: _starAccent!,
                realmCount: _starRealmCount,
                onBack: () => _game?.returnToAtlas(),
              )
            else ...[
              Positioned(
                top: 22,
                left: 22,
                child: RealmContextPill(
                  realm: realm,
                  inspectOpen: state.inspectOpen,
                  onInspect: controller.toggleInspect,
                  width: 620,
                  viewToggle: const _AtlasSceneToggle(),
                ),
              ),
              FieldPanel(
                label: l10n.navigation,
                bounds: bounds,
                width: 360,
                initialOffset: Offset(
                  (constraints.maxWidth > 1020)
                      ? 644
                      : constraints.maxWidth - 382,
                  16,
                ),
                child: NavigationPanel(
                  realmPath: state.realmPath,
                  onBreadcrumbTap: controller.navigateToBreadcrumb,
                ),
              ),
              FieldPanel(
                label: l10n.compute,
                bounds: bounds,
                width: 256,
                initialOffset: Offset(
                  constraints.maxWidth - 256 - 22,
                  22,
                ),
                child: const ComputeCard(),
              ),
              FieldPanel(
                label: l10n.possibleActions,
                bounds: bounds,
                width: 260,
                accent: true,
                initialMode: FieldPanelMode.collapsed,
                initialOffset: const Offset(22, 100),
                onClose: () {},
                child: const PossibleActions(),
              ),
            ],
            if (!_inStarView)
              FieldWorkingPanels(
                state: state,
                controller: controller,
                bounds: bounds,
                opacity: 1.0,
              ),
            if (!_inStarView && _currentRealmId != null)
              Positioned(
                top: 76,
                left: 22,
                child: _InsideRealmChip(
                  name: _currentRealmName!,
                  onExit: _exitRealm,
                ),
              ),
            if (!_inStarView && _showEmptyState)
              const Center(child: _EmptyRealmState()),
            if (!_inStarView && state.inspectOpen)
              FieldPanel(
                key: const ValueKey('panel-inspect'),
                label: '${l10n.inspect} ${realm.name}',
                bounds: bounds,
                width: 430,
                initialOffset: const Offset(22, 96),
                onClose: controller.toggleInspect,
                child: InspectPanel(realm: realm),
              ),
            if (_selectedPlacement != null) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    _game?.clearSelection();
                    setState(() {
                      _selectedPlacement = null;
                    });
                  },
                  child: const ColoredBox(
                    color: Color(0x00000000),
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                right: 24,
                child: RealmDetailPopup(
                  placement: _selectedPlacement!,
                  onClose: () {
                    _game?.clearSelection();
                    setState(() {
                      _selectedPlacement = null;
                    });
                  },
                  onEnter: () {
                    final p = _selectedPlacement!;
                    _game?.clearSelection();
                    _enterRealm(p.realm.id, p.realm.name);
                  },
                  onAtlasReload: _rebuildGame,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _StarViewHeader extends StatelessWidget {
  const _StarViewHeader({
    required this.label,
    required this.accent,
    required this.realmCount,
    required this.onBack,
  });

  final String label;
  final Color accent;
  final int realmCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Positioned(
      top: 22,
      left: 22,
      child: GestureDetector(
        onTap: onBack,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: colors.deep.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: accent.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '←  ${context.l10n.backToAtlas}',
                  style: context.kidunaText.eyebrow.copyWith(
                    color: accent,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label.toUpperCase(),
                  style: context.kidunaText.heading.copyWith(
                    color: colors.cream,
                    fontSize: 22,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$realmCount Realms',
                  style: context.kidunaText.bodySmall.copyWith(
                    color: colors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 2,
                  color: accent.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InsideRealmChip extends StatelessWidget {
  const _InsideRealmChip({required this.name, required this.onExit});

  final String name;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return GestureDetector(
      onTap: onExit,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: colors.deep.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.sky.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back, size: 14, color: colors.sky),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.cream,
                ),
              ),
            ],
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

/// The Atlas / Scene segmented toggle. Atlas is selected; Scene is present but
/// disabled at this View (matching the prototype).
class _AtlasSceneToggle extends StatelessWidget {
  const _AtlasSceneToggle();

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.deep.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.camel.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: colors.sky,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              context.l10n.atlas,
              style: text.labelStrong.copyWith(color: colors.skyButtonInk),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              context.l10n.scene,
              style: text.labelStrong.copyWith(color: colors.quiet),
            ),
          ),
        ],
      ),
    );
  }
}

/// The resizable boundary between Field and Ki (static in this pass).
class _Boundary extends StatelessWidget {
  const _Boundary();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      color: const Color(0xFF100A06),
      alignment: Alignment.center,
      child: Container(
        width: 2,
        height: 34,
        decoration: BoxDecoration(
          color: context.kiduna.sky.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// The Ki rail — static content matching the AEV prototype.
class _AevKi extends StatelessWidget {
  const _AevKi();

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _kiGround,
        border: Border(
          left: BorderSide(color: colors.sky.withValues(alpha: 0.12)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _KiHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.aevKiWelcome,
                      style: text.bodyLarge.copyWith(color: colors.text),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.aevKiWelcomeDetail,
                      style: text.body.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _KiChip(label: context.l10n.whatShouldIDoFirst),
                _KiChip(label: context.l10n.tellMeMoreAboutKinshipDuna),
              ],
            ),
            const SizedBox(height: 14),
            const _KiComposer(),
          ],
        ),
      ),
    );
  }
}

class _KiHeader extends StatelessWidget {
  const _KiHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Column(
      children: [
        Row(
          children: [
            const EnamelIcon(kind: EnamelKind.ki, size: 52),
            const SizedBox(width: 12),
            Text(
              context.l10n.ki,
              style: text.display.copyWith(color: colors.cream),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.sky.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: colors.sky.withValues(alpha: 0.4)),
              ),
              child: Text(
                '${context.l10n.yourAllies}  2',
                style: text.bodySmall.copyWith(color: colors.sky),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${context.l10n.fieldFocus.toUpperCase()}  100%',
              style: text.eyebrowSmall.copyWith(color: colors.quiet),
            ),
            const SizedBox(width: 10),
            Container(
              width: 96,
              height: 3,
              decoration: BoxDecoration(
                color: colors.sky,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KiChip extends StatelessWidget {
  const _KiChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: colors.raised.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.line),
      ),
      child: Text(
        label,
        style: context.kidunaText.bodySmall.copyWith(color: colors.cream),
      ),
    );
  }
}

class _KiComposer extends StatelessWidget {
  const _KiComposer();

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.messageKi,
              style: context.kidunaText.body.copyWith(color: colors.quiet),
            ),
          ),
          Icon(Icons.mic_none, size: 20, color: colors.quiet),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.sky,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_upward,
              size: 18,
              color: colors.skyButtonInk,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown below the desktop breakpoint — the prototype's "needs more room"
/// message over the deep-field ground.
class _NarrowWarning extends StatelessWidget {
  const _NarrowWarning();

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return ColoredBox(
      color: colors.field,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.studioNeedsMoreRoom,
                textAlign: TextAlign.center,
                style: context.kidunaText.heading.copyWith(color: colors.cream),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.reopenAtWiderWidth,
                textAlign: TextAlign.center,
                style: context.kidunaText.body.copyWith(color: colors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
