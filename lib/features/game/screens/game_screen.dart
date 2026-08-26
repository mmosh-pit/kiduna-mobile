import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/injection.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../games/medieval_poker/flame/medieval_poker_game.dart';
import '../../../games/medieval_poker/flame/poker_hud.dart';
import '../../../games/medieval_poker/medieval_poker_lobby_screen.dart';
import '../../../games/medieval_poker/standings/medieval_poker_standings_screen.dart';
import '../../../games/medieval_poker/tournament/medieval_poker_tournament_detail_screen.dart';
import '../../../games/medieval_poker/tournament/medieval_poker_tournament_list_screen.dart';
import '../../../l10n/app_localizations.dart';

/// Game feature entry — shows mode selection or active poker game.
///
/// Designed to sit inside the [DashboardScreen] left panel.
/// Ki chat stays visible on the right for all states.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

enum _GameView {
  modeSelector,
  singlePlayer,
  lobby,
  standings,
  tournaments,
  tournamentDetail,
}

class _GameScreenState extends ConsumerState<GameScreen> {
  _GameView _view = _GameView.modeSelector;

  /// Set when a tournament is opened from the list.
  String? _tournamentId;

  /// Where "back" from Standings should land — it is reachable from both the
  /// lobby and the mode selector, and should return to whichever was used.
  _GameView _standingsOrigin = _GameView.lobby;

  void _goToModeSelector() {
    setState(() => _view = _GameView.modeSelector);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;

    return switch (_view) {
      _GameView.modeSelector => _ModeSelector(
        onSinglePlayer: () => setState(() => _view = _GameView.singlePlayer),
        onPlayOnline: () => setState(() => _view = _GameView.lobby),
        onTournaments: () => setState(() => _view = _GameView.tournaments),
        onStandings: () => setState(() {
          _standingsOrigin = _GameView.modeSelector;
          _view = _GameView.standings;
        }),
      ),
      _GameView.singlePlayer => _PokerTableView(onExit: _goToModeSelector),
      _GameView.lobby => _LobbyView(
        onBack: _goToModeSelector,
        onLeaderboard: () => setState(() {
          _standingsOrigin = _GameView.lobby;
          _view = _GameView.standings;
        }),
      ),
      _GameView.standings => _StandingsView(
        viewerUserId: user?.id,
        onBack: () => setState(() => _view = _standingsOrigin),
      ),
      _GameView.tournaments => MedievalPokerTournamentListScreen(
        onOpen: (id) => setState(() {
          _tournamentId = id;
          _view = _GameView.tournamentDetail;
        }),
      ),
      _GameView.tournamentDetail => MedievalPokerTournamentDetailScreen(
        tournamentId: _tournamentId!,
        viewerUserId: user?.id,
        viewerName: user?.username ?? user?.name,
        onBack: () => setState(() => _view = _GameView.tournaments),
      ),
    };
  }
}

/// Lobby wrapper — shows the lobby inside the left panel.
class _LobbyView extends StatelessWidget {
  const _LobbyView({required this.onBack, required this.onLeaderboard});

  final VoidCallback onBack;
  final VoidCallback onLeaderboard;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
            child: IconButton(
              onPressed: onBack,
              icon: Icon(
                Icons.arrow_back_rounded,
                color: context.kiduna.cream.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
        Expanded(child: MedievalPokerLobbyScreen(onLeaderboard: onLeaderboard)),
      ],
    );
  }
}

/// Leaderboard wrapper — shows inside left panel with back button.
class _StandingsView extends StatelessWidget {
  const _StandingsView({required this.onBack, this.viewerUserId});

  final VoidCallback onBack;
  final String? viewerUserId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
            child: IconButton(
              onPressed: onBack,
              icon: Icon(
                Icons.arrow_back_rounded,
                color: context.kiduna.cream.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
        Expanded(
          child: MedievalPokerStandingsScreen(viewerUserId: viewerUserId),
        ),
      ],
    );
  }
}

/// Mode selection — Single Player, Play Online, Tournaments, Standings.
class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.onSinglePlayer,
    required this.onPlayOnline,
    required this.onTournaments,
    required this.onStandings,
  });

  final VoidCallback onSinglePlayer;
  final VoidCallback onPlayOnline;
  final VoidCallback onTournaments;
  final VoidCallback onStandings;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: colors.field,
      padding: const EdgeInsets.all(32),
      // Four modes no longer fit a short panel, so the column scrolls rather
      // than overflowing when the dashboard pane is dragged narrow.
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.gameTitle, style: text.h4.copyWith(color: colors.gold)),
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
                subtitle: l10n.playOnlineSubtitle,
                onTap: onPlayOnline,
              ),
              const SizedBox(height: 16),
              _ModeButton(
                icon: Icons.emoji_events_rounded,
                label: l10n.tournamentsLabel,
                subtitle: l10n.tournamentsSubtitle,
                onTap: onTournaments,
              ),
              const SizedBox(height: 16),
              _ModeButton(
                key: const Key('mode-standings'),
                icon: Icons.leaderboard_rounded,
                label: l10n.standingsLabel,
                subtitle: l10n.standingsSubtitle,
                onTap: onStandings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  /// A mode with no handler is shown dimmed rather than hidden, so an
  /// unavailable option still reads as something that exists.
  bool get enabled => onTap != null;

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

/// Active poker game — uses the LEGACY [MedievalPokerGame] + [PokerHud]
/// for proper animations and pacing (AI thinking delays, card dealing
/// animations, "X is thinking..." banners). Same engine as kinship-app.
class _PokerTableView extends StatefulWidget {
  const _PokerTableView({required this.onExit});

  final VoidCallback onExit;

  @override
  State<_PokerTableView> createState() => _PokerTableViewState();
}

class _PokerTableViewState extends State<_PokerTableView> {
  MedievalPokerGame? _game;

  @override
  void initState() {
    super.initState();
    _game = MedievalPokerGame(opponentCount: 3);
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    if (game == null) {
      return const SizedBox.shrink();
    }
    return ClipRect(
      child: GameWidget<MedievalPokerGame>(
        game: game,
        overlayBuilderMap: {
          'hud': (context, g) => PokerHud(game: game, onExit: widget.onExit),
        },
        initialActiveOverlays: const ['hud'],
      ),
    );
  }
}
