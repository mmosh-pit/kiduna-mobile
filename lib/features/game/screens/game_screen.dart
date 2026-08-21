import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../games/medieval_poker/flame/table_renderer.dart';
import '../../../games/medieval_poker/session/card_zoom.dart';
import '../../../games/medieval_poker/session/game_session.dart';
import '../../../games/medieval_poker/session/local_session.dart';
import '../../../games/medieval_poker/session/paced_session.dart';
import '../../../games/medieval_poker/session/session_hud.dart';
import '../../../l10n/app_localizations.dart';

/// Game feature entry — shows mode selection or active poker game.
///
/// Designed to sit inside the [DashboardScreen] left panel.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _isPlaying = false;

  void _startSinglePlayer() {
    setState(() => _isPlaying = true);
  }

  void _exitGame() {
    setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isPlaying) {
      return _PokerTableView(onExit: _exitGame);
    }
    return _ModeSelector(onSinglePlayer: _startSinglePlayer);
  }
}

/// Mode selection — Single Player vs Online.
class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.onSinglePlayer});

  final VoidCallback onSinglePlayer;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: colors.deep,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.gameTitle,
            style: text.h4.copyWith(color: colors.gold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.gameSubtitle,
            style: text.caption.copyWith(
              color: colors.gold.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 48),
          _ModeButton(
            icon: Icons.person,
            label: l10n.singlePlayerLabel,
            subtitle: l10n.singlePlayerSubtitle,
            onTap: onSinglePlayer,
          ),
          const SizedBox(height: 16),
          _ModeButton(
            icon: Icons.public,
            label: l10n.playOnlineLabel,
            subtitle: l10n.comingSoon,
            onTap: null,
            enabled: false,
          ),
          const SizedBox(height: 16),
          _ModeButton(
            icon: Icons.emoji_events,
            label: l10n.leaderboardLabel,
            subtitle: l10n.comingSoon,
            onTap: null,
            enabled: false,
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: enabled ? colors.deep : colors.deep.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled
                  ? colors.camel.withValues(alpha: 0.5)
                  : colors.camel.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: enabled
                    ? colors.gold
                    : colors.gold.withValues(alpha: 0.3),
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: text.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: enabled
                            ? colors.cream
                            : colors.cream.withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: text.caption.copyWith(
                        color: enabled
                            ? colors.muted
                            : colors.muted.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                Icon(
                  Icons.chevron_right,
                  color: colors.gold.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Active poker game — wraps Elias's LocalSession + TableRenderer.
///
/// Uses [LayoutBuilder] + scoped [MediaQuery] so the game's HUD overlays
/// (dialogs, panels, prompts) respect the container size instead of the
/// full window size. A [Navigator] overlay scope ensures [showDialog]
/// renders within the game panel, not full-screen.
class _PokerTableView extends StatefulWidget {
  const _PokerTableView({required this.onExit});

  final VoidCallback onExit;

  @override
  State<_PokerTableView> createState() => _PokerTableViewState();
}

class _PokerTableViewState extends State<_PokerTableView> {
  late LocalSession _local;
  late GameSession _session;
  late TableRenderer _renderer;
  final CardZoomController _cardZoom = CardZoomController();
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _create();
  }

  void _create() {
    _local = LocalSession(opponentCount: 3);
    _session = PacedSession(_local);
    _renderer = TableRenderer(session: _session, cardZoom: _cardZoom);
    _local.start();
  }

  void _playAgain() {
    setState(() {
      _session.dispose();
      _generation++;
      _create();
    });
  }

  @override
  void dispose() {
    _session.dispose();
    _cardZoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Scope MediaQuery so game overlays use container size, not window.
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            padding: EdgeInsets.zero,
          ),
          child: ClipRect(
            // Nested Navigator so showDialog renders within this panel,
            // not across the full window.
            child: Navigator(
              key: _navKey,
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  backgroundColor: Colors.black,
                  resizeToAvoidBottomInset: false,
                  body: GameWidget<TableRenderer>(
                    key: ValueKey(_generation),
                    game: _renderer,
                    overlayBuilderMap: {
                      'hud': (context, game) => SessionHud(
                            session: _session,
                            onExit: widget.onExit,
                            onPlayAgain: _playAgain,
                            cardZoom: _cardZoom,
                          ),
                    },
                    initialActiveOverlays: const ['hud'],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}