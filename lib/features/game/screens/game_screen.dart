import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../games/medieval_poker/flame/medieval_poker_game.dart';
import '../../../games/medieval_poker/flame/poker_hud.dart';
import '../../../games/medieval_poker/medieval_poker_leaderboard_screen.dart';
import '../../../games/medieval_poker/medieval_poker_lobby_screen.dart';
import '../../../games/medieval_poker/medieval_poker_online_screen.dart';
import '../../../games/medieval_poker/session/lobby_client.dart';
import '../../../features/ki_chat/controllers/ki_chat_controller.dart';
import '../../../l10n/app_localizations.dart';

// ── Tips — simple English for any player ─────────────────────────────

const _tipWelcome =
    'Welcome! You get 3 cards. If two cards have the same number, '
    'that\'s good — try betting. If nothing matches, save your coins '
    'and skip this round.';

const _tipHeatingUp =
    '🔥 You won 2 in a row! Special power cards are now available '
    'in your hand. Use them now — they disappear if you lose.';

const _tipTilted =
    'You lost a big round — your power cards are locked for now. '
    'Play safe, skip weak rounds, and wait for a good hand to '
    'unlock them again.';

const _tipPowerCard =
    'Someone used a special card against you! Look for a shield card '
    'in your hand to block it. No shield? Just tap Pass and play '
    'carefully.';

const _tipWin =
    '🏆 You won! Tip: when you\'re on a winning streak, use your '
    'power cards — they\'re strongest when you\'re winning.';

const _tipLose =
    'Don\'t worry! Tip: skip rounds when your cards are bad. Wait '
    'for matching cards, then play big.';

const _tipFirstFlop =
    '3 cards just appeared on the table! These are shared by everyone. '
    'Match them with your cards to make the best hand.';

const _tipFirstBetting =
    'Your turn! Tap Check to skip without betting. Tap Bet to put '
    'coins in. Tap Fold to quit this round and save your coins.';

const _tipSetupCard =
    'Before the round starts, you can play a setup card for an early '
    'advantage. Or tap the button to skip.';

const _tipClassSelect =
    'Pick your class! Each class gives you different power cards. '
    'Rogue is sneaky, Warrior is strong, Merchant makes money, '
    'Noble controls the game.';

const _tipDeckBuild =
    'Build your deck! Tap cards to add or remove them. Pick cards '
    'that work well together. You need the exact number shown.';

const _tipCourtSelect =
    'Choose your Court Cards! These are special cards shared by all '
    'classes. Pick the ones that match your play style.';

// ── Hand evaluation helpers ──────────────────────────────────────────

String _cardText(dynamic card) {
  try {
    return '${card.rankLabel}${card.suit.glyph}';
  } catch (_) {
    try { return card.toString(); } catch (_) { return '?'; }
  }
}

String _evaluateHand(List<String> holeRanks, List<String> boardRanks) {
  final allRanks = [...holeRanks, ...boardRanks];
  final counts = <String, int>{};
  for (final r in allRanks) counts[r] = (counts[r] ?? 0) + 1;
  final pairs = counts.values.where((c) => c == 2).length;
  final trips = counts.values.where((c) => c == 3).length;
  final quads = counts.values.where((c) => c >= 4).length;

  if (quads > 0) return 'You have 4 matching cards — amazing hand! Bet big.';
  if (trips > 0 && pairs > 0) return 'Full House — 3 matching + 2 matching. Very strong! Bet big.';
  if (trips > 0) return '3 matching cards — strong hand. Try betting or raising.';
  if (pairs >= 2) return '2 different pairs — decent hand. You can call or bet small.';
  if (pairs == 1) {
    for (final r in holeRanks) {
      if (allRanks.where((x) => x == r).length >= 2) {
        final name = const {
          'A': 'Ace', 'K': 'King', 'Q': 'Queen', 'J': 'Jack', 'T': '10',
        }[r] ?? r;
        return 'You have a pair of ${name}s. OK hand — try calling if someone bets.';
      }
    }
    return 'There\'s a pair on the table but not in your hand. Weak — consider folding.';
  }
  if (holeRanks.any(['A', 'K', 'Q', 'J'].contains)) {
    return 'No matches but you have high cards. Risky — tap Check if you can.';
  }
  return 'No matches, low cards — weak hand. Tap Fold to save your coins.';
}

// ── GameScreen ───────────────────────────────────────────────────────

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, this.startInLobby = false, this.cellRealmId, this.joinTicket});

  final bool startInLobby;
  final String? cellRealmId;
  final Object? joinTicket;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

enum _GameView { modeSelector, singlePlayer, lobby, leaderboard, onlinePlay }

class _GameScreenState extends ConsumerState<GameScreen> {
  late _GameView _view = widget.startInLobby ? _GameView.lobby : _GameView.modeSelector;
  bool _showExitConfirm = false;
  _PokerTableView? _pokerView;
  MedievalPokerOnlineScreen? _onlineScreen;

  @override
  void dispose() {
    final ki = ref.read(kiChatControllerProvider.notifier);
    ki.clearGameContext();
    ki.clearLocalTips();
    super.dispose();
  }

  void _goToModeSelector() {
    final ki = ref.read(kiChatControllerProvider.notifier);
    ki.clearGameContext();
    ki.clearLocalTips();
    setState(() {
      _showExitConfirm = false;
      _pokerView = null;
      _view = _GameView.modeSelector;
    });
  }

  void _startSinglePlayer() {
    // Show welcome tip immediately when player clicks Single Player
    ref.read(kiChatControllerProvider.notifier).addLocalTip(_tipWelcome);
    ref.read(kiChatControllerProvider.notifier)
        .setGameContext('Game in progress');

    setState(() {
      _pokerView = _PokerTableView(
        key: GlobalKey(),
        onExit: () => setState(() => _showExitConfirm = true),
      );
      _view = _GameView.singlePlayer;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_view == _GameView.modeSelector) {
      return _ModeSelector(
        onSinglePlayer: _startSinglePlayer,
        onPlayOnline: () => setState(() => _view = _GameView.lobby),
      );
    }
    if (_view == _GameView.lobby) {
      return _LobbyView(
        onBack: _goToModeSelector,
        onLeaderboard: () => setState(() => _view = _GameView.leaderboard),
        cellRealmId: widget.cellRealmId,
        joinTicket: widget.joinTicket,
        onGameLaunch: (screen) {
          setState(() {
            _onlineScreen = screen;
            _view = _GameView.onlinePlay;
          });
        },
      );
    }
    if (_view == _GameView.onlinePlay && _onlineScreen != null) {
      return _onlineScreen!;
    }
    if (_view == _GameView.leaderboard) {
      return _LeaderboardView(
        onBack: () => setState(() => _view = _GameView.lobby),
      );
    }

    return Stack(
      children: [
        if (_pokerView != null) _pokerView!,
        if (_showExitConfirm)
          _ExitOverlay(
            onKeepPlaying: () => setState(() => _showExitConfirm = false),
            onLeave: _goToModeSelector,
          ),
      ],
    );
  }
}

// ── Exit overlay ─────────────────────────────────────────────────────

class _ExitOverlay extends StatelessWidget {
  const _ExitOverlay({required this.onKeepPlaying, required this.onLeave});
  final VoidCallback onKeepPlaying;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.72),
        child: Center(
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF1B140C),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF6B5533), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Leave the game?',
                    style: TextStyle(
                        fontFamily: 'GoudyHeavyface',
                        fontSize: 22,
                        color: colors.gold)),
                const SizedBox(height: 8),
                Text("You'll forfeit your seat and progress.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: colors.cream.withValues(alpha: 0.7),
                        fontSize: 14)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onKeepPlaying,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                              color: const Color(0xFF2A6B4F),
                              borderRadius: BorderRadius.circular(10)),
                          child: Center(
                              child: Text('Keep Playing',
                                  style: TextStyle(
                                      color: colors.cream,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: onLeave,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                              color: const Color(0xFFB3261E),
                              borderRadius: BorderRadius.circular(10)),
                          child: Center(
                              child: Text('Leave',
                                  style: TextStyle(
                                      color: colors.cream,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15))),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Lobby + Leaderboard ──────────────────────────────────────────────

class _LobbyView extends StatelessWidget {
  const _LobbyView({required this.onBack, required this.onLeaderboard, this.cellRealmId, this.joinTicket, this.onGameLaunch});
  final VoidCallback onBack;
  final VoidCallback onLeaderboard;
  final String? cellRealmId;
  final Object? joinTicket;
  final void Function(MedievalPokerOnlineScreen screen)? onGameLaunch;

  @override
  Widget build(BuildContext context) {
    final LobbyTicket? ticket = joinTicket is LobbyTicket ? joinTicket as LobbyTicket : null;
    return Column(children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
          child: IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back_rounded,
                color: context.kiduna.cream.withValues(alpha: 0.7)),
          ),
        ),
      ),
      Expanded(
          child: MedievalPokerLobbyScreen(
            onLeaderboard: onLeaderboard,
            cellRealmId: cellRealmId,
            initialTicket: ticket,
            onGameLaunch: onGameLaunch,
          )),
    ]);
  }
}

class _LeaderboardView extends StatelessWidget {
  const _LeaderboardView({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
          child: IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back_rounded,
                color: context.kiduna.cream.withValues(alpha: 0.7)),
          ),
        ),
      ),
      const Expanded(child: MedievalPokerLeaderboardScreen()),
    ]);
  }
}

// ── Mode selector ────────────────────────────────────────────────────

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.onSinglePlayer,
    required this.onPlayOnline,
  });
  final VoidCallback onSinglePlayer;
  final VoidCallback onPlayOnline;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: colors.field,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(l10n.gameTitle, style: text.h4.copyWith(color: colors.gold)),
          const SizedBox(height: 8),
          Text(l10n.gameSubtitle,
              style: text.caption
                  .copyWith(color: colors.gold.withValues(alpha: 0.6))),
          const SizedBox(height: 48),
          _ModeButton(
              icon: Icons.person,
              label: l10n.singlePlayerLabel,
              subtitle: l10n.singlePlayerSubtitle,
              onTap: onSinglePlayer),
          const SizedBox(height: 16),
          _ModeButton(
              icon: Icons.public,
              label: l10n.playOnlineLabel,
              subtitle: 'Create or join a room by code',
              onTap: onPlayOnline),
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
              Icon(icon,
                  color: enabled
                      ? colors.gold
                      : colors.gold.withValues(alpha: 0.3),
                  size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: text.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: enabled
                                ? colors.cream
                                : colors.cream.withValues(alpha: 0.3))),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: text.caption.copyWith(
                            color: enabled
                                ? colors.muted
                                : colors.muted.withValues(alpha: 0.3))),
                  ],
                ),
              ),
              if (enabled)
                Icon(Icons.chevron_right,
                    color: colors.gold.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Poker table with Ki tips ─────────────────────────────────────────

class _PokerTableView extends ConsumerStatefulWidget {
  const _PokerTableView({super.key, required this.onExit});
  final VoidCallback onExit;

  @override
  ConsumerState<_PokerTableView> createState() => _PokerTableViewState();
}

class _PokerTableViewState extends ConsumerState<_PokerTableView> {
  late final MedievalPokerGame _game;

  // Track what tips we've already shown (prevent repeats)
  bool _sentWelcome = false;
  bool _wasHeatingUp = false;
  bool _wasTilted = false;
  bool _wasGameOver = false;
  bool _hadPowerPrompt = false;
  bool _wasPlayerTurn = false;
  bool _sentFirstFlop = false;
  bool _sentFirstBetting = false;
  bool _hadSetupPrompt = false;
  bool _hadClassSelect = false;
  bool _hadCourtSelect = false;
  bool _hadDeckBuild = false;

  @override
  void initState() {
    super.initState();
    _game = MedievalPokerGame(opponentCount: 3);
    _game.view.addListener(_onViewChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Welcome already shown by _startSinglePlayer.
      // Just mark as sent so it doesn't repeat.
      _sentWelcome = true;
    });
  }

  void _tip(String text) {
    if (!mounted) return;
    ref.read(kiChatControllerProvider.notifier).addLocalTip(text);
  }

  String _buildCardContext() {
    try {
      final human = _game.engine.players.firstWhere((p) => p.isHuman);
      final hole = human.hole.map(_cardText).join(' ');
      final board = _game.engine.community.map(_cardText).join(' ');
      final pot = _game.engine.pot;
      final parts = <String>[];
      if (hole.isNotEmpty) parts.add('Your cards: $hole');
      if (board.isNotEmpty) parts.add('Board: $board');
      parts.add('Pot: $pot coins');
      return parts.join('. ');
    } catch (_) {
      return '';
    }
  }

  String _buildCardTip() {
    try {
      final human = _game.engine.players.firstWhere((p) => p.isHuman);
      final holeCards = human.hole.map(_cardText).toList();
      if (holeCards.isEmpty) return '';
      final boardCards = _game.engine.community.map(_cardText).toList();
      final pot = _game.engine.pot;

      final holeRanks = human.hole.map((c) {
        try { return c.rankLabel as String; } catch (_) { return '?'; }
      }).toList();
      final boardRanks = _game.engine.community.map((c) {
        try { return c.rankLabel as String; } catch (_) { return '?'; }
      }).toList();

      final eval = _evaluateHand(holeRanks, boardRanks);
      final buf = StringBuffer('Your cards: ${holeCards.join(" ")}');
      if (boardCards.isNotEmpty) buf.write('. Board: ${boardCards.join(" ")}');
      buf.write('. Pot: $pot coins. $eval');
      return buf.toString();
    } catch (_) {
      return '';
    }
  }

  void _onViewChanged() {
    if (!mounted) return;
    final v = _game.view.value;
    final ki = ref.read(kiChatControllerProvider.notifier);

    // Class selection — shown once
    if (v.showClassSelect && !_hadClassSelect) {
      _hadClassSelect = true;
      _tip(_tipClassSelect);
    }

    // Deck building — shown once
    if (v.showDeckBuild && !_hadDeckBuild) {
      _hadDeckBuild = true;
      _tip(_tipDeckBuild);
    }

    // Court card selection — shown once
    if (v.showCourtSelect && !_hadCourtSelect) {
      _hadCourtSelect = true;
      _tip(_tipCourtSelect);
    }

    // Setup card prompt — shown once
    if (v.showPower && v.powerTitle.contains('Setup') && !_hadSetupPrompt) {
      _hadSetupPrompt = true;
      _tip(_tipSetupCard);
    }

    // First time flop appears — detect board cards
    if (!_sentFirstFlop) {
      try {
        if (_game.engine.community.isNotEmpty) {
          _sentFirstFlop = true;
          _tip(_tipFirstFlop);
        }
      } catch (_) {}
    }

    // First time player's turn — explain betting options
    if (v.showActions && !_sentFirstBetting) {
      _sentFirstBetting = true;
      _tip(_tipFirstBetting);
    }

    // Heating Up
    if (v.banner.contains('Heating Up') && !_wasHeatingUp) {
      _wasHeatingUp = true;
      _tip(_tipHeatingUp);
    } else if (!v.banner.contains('Heating Up')) {
      _wasHeatingUp = false;
    }

    // Tilted
    if (v.banner.contains('Tilted') && !_wasTilted) {
      _wasTilted = true;
      _tip(_tipTilted);
    } else if (!v.banner.contains('Tilted')) {
      _wasTilted = false;
    }

    // Power Card counter prompt (not Setup)
    if (v.showPower &&
        v.powerTitle.contains('Respond') &&
        !_hadPowerPrompt) {
      _hadPowerPrompt = true;
      _tip(_tipPowerCard);
    } else if (!v.showPower || !v.powerTitle.contains('Respond')) {
      _hadPowerPrompt = false;
    }

    // Player's turn — card evaluation (every turn)
    if (v.showActions && !_wasPlayerTurn) {
      _wasPlayerTurn = true;
      final ctx = _buildCardContext();
      if (ctx.isNotEmpty) ki.setGameContext(ctx);
      final tip = _buildCardTip();
      if (tip.isNotEmpty) _tip(tip);
    } else if (!v.showActions) {
      _wasPlayerTurn = false;
    }

    // Game Over
    if (v.gameOver && !_wasGameOver) {
      _wasGameOver = true;
      ki.clearGameContext();
      _tip(v.won ? _tipWin : _tipLose);
    }
  }

  @override
  void dispose() {
    _game.view.removeListener(_onViewChanged);
    final ki = ref.read(kiChatControllerProvider.notifier);
    ki.clearGameContext();
    ki.clearLocalTips();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: GameWidget<MedievalPokerGame>(
        game: _game,
        overlayBuilderMap: {
          'hud': (context, g) => PokerHud(
                game: _game,
                onExit: widget.onExit,
              ),
        },
        initialActiveOverlays: const ['hud'],
      ),
    );
  }
}