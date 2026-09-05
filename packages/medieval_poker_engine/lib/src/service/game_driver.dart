import 'package:medieval_poker_engine/medieval_poker_engine.dart';

import 'agent.dart';

/// Drives a full authoritative game over the shared [PokerGame] engine, asking
/// each seat's [PlayerAgent] to decide at every point. Structurally mirrors the
/// verified offline/sim loop; the only difference is that decisions come from
/// agents (AI or remote humans) instead of being computed inline.
class GameDriver {
  final PokerGame game;
  final List<PlayerAgent> agents; // indexed by seat

  /// Emitted whenever visible state changes. [revealSeats] are seats whose hole
  /// cards should be revealed to everyone (showdown).
  final void Function(Set<int> revealSeats)? onState;
  final void Function(List<PotAward> awards)? onResult;
  final void Function()? onGameOver;

  GameDriver({
    required this.game,
    required this.agents,
    this.onState,
    this.onResult,
    this.onGameOver,
  });

  void _emit([Set<int> reveal = const {}]) => onState?.call(reveal);
  PlayerAgent _agent(PokerPlayer p) => agents[p.seat];

  Future<void> run() async {
    await _setupDecks();
    game.drawForButton();
    _emit();

    while (!game.isGameOver) {
      game.startHand();
      _emit();
      await _setupPhase();
      await _bettingAndBoard();
      await _showdownPhase();

      final awards = game.settle();
      final winners =
          awards.isNotEmpty ? awards.first.winners.toSet() : <PokerPlayer>{};
      game.resolveShowdown(winners);
      // Reveal contenders' hands after a contested showdown.
      final reveal = <int>{
        for (final p in game.players)
          if (p.showdownHand != null) p.seat
      };
      _emit(reveal);
      onResult?.call(awards);
    }
    onGameOver?.call();
  }

  // ── Deck-building ──────────────────────────────────────────────────────
  // Every player sets up their deck fully independently and concurrently — no
  // one waits in a queue for another to pick their class, Court, or deck. Each
  // player's own choices are sequential (class → Court → deck), but a player who
  // finishes early doesn't block anyone else. The single barrier is here: play
  // begins only once everyone has finished their own setup.
  Future<void> _setupDecks() async {
    await Future.wait([for (final p in game.players) _setupPlayer(p)]);
  }

  Future<void> _setupPlayer(PokerPlayer p) async {
    final a = _agent(p);
    if (a.isAi) {
      game.autoBuildDeckFor(p); // AI keeps its pre-assigned class/Court
      return;
    }
    await _chooseClassAndCourt(p);
    // The deck pool depends only on THIS player's class/Court (both now chosen),
    // so we can prompt their deck-build immediately — no wait for other players.
    final chosen = await a.buildDeck(game.deckCandidatesFor(p), game.deckSize);
    if (chosen != null) {
      game.buildDeckFor(p, chosen);
    } else {
      game.autoBuildDeckFor(p); // timed out / skipped → full auto pool
    }
  }

  Future<void> _chooseClassAndCourt(PokerPlayer p) async {
    const classes = AiPersonality.values;
    const courts = CourtMember.values;
    final a = _agent(p);
    final ci = await a.chooseClass([for (final c in classes) c.title]);
    p.personality = classes[ci.clamp(0, classes.length - 1)];
    final qi = await a.chooseCourt([for (final c in courts) c.title]);
    p.court = courts[qi.clamp(0, courts.length - 1)];
  }

  // ── Setup phase (Midas chip-sell + Setup power cards) ─────────────────
  Future<void> _setupPhase() async {
    for (final p in game.playersFromButton()) {
      final a = _agent(p);
      var guard = 0;
      while (game.canSellChip(p) && guard++ < 10) {
        if (!await a.sellChip(game, p)) break;
        game.sellChip(p);
        _emit();
      }
      await _powerWindow(p, PowerTiming.setup);
    }
  }

  // ── Betting rounds + board dealing ────────────────────────────────────
  Future<void> _bettingAndBoard() async {
    var guard = 0;
    while (true) {
      while (!game.isBettingRoundComplete) {
        final p = game.actingPlayer!;
        await _itemWindow(p);
        await _powerWindow(p, PowerTiming.round);
        final action =
            p.folded ? const PokerAction.fold() : await _agent(p).bettingAction(game, p);
        game.applyAction(action);
        _emit();
        if (++guard > 12000) throw StateError('betting did not converge');
      }
      if (game.contenders.length <= 1) break;
      if (game.street == Street.river) break;
      game.advanceStreet();
      _emit();
      await _boardCounterWindow();
    }
    while (game.contenders.length > 1 && game.community.length < 5) {
      game.advanceStreet();
      _emit();
      await _boardCounterWindow();
    }
  }

  Future<void> _showdownPhase() async {
    if (game.contenders.length <= 1) return;
    for (final p in game.playersFromButton()) {
      if (!p.inHand) continue;
      final a = _agent(p);
      a.beginWindow();
      var guard = 0;
      while (guard++ < 12) {
        final opts = game.playableShowdown(p);
        if (opts.isEmpty) break;
        final id = await a.pickWindowCard(game, p, PowerTiming.showdown, opts);
        if (id == null) break;
        game.proposeShowdown(p, _byId(opts, id));
        _emit();
      }
    }
  }

  // ── Shared window helpers ─────────────────────────────────────────────
  Future<void> _powerWindow(PokerPlayer p, PowerTiming timing) async {
    final a = _agent(p);
    a.beginWindow();
    var guard = 0;
    while (guard++ < 20) {
      if (p.folded) break;
      final playable = game.playablePower(p, timing);
      if (playable.isEmpty) break;
      final id = await a.pickWindowCard(game, p, timing, playable);
      if (id == null) break;
      await _playPowerWithCounters(p, _byId(playable, id));
    }
  }

  Future<void> _itemWindow(PokerPlayer p) async {
    final a = _agent(p);
    a.beginWindow();
    var guard = 0;
    while (guard++ < 12) {
      if (p.folded) break;
      final items = game.playableItems(p);
      if (items.isEmpty) break;
      final id = await a.pickItem(game, p, items);
      if (id == null) break;
      final item = items.firstWhere((it) => it.id == id);
      final modes = game.itemModes(item);
      final mode = modes.isEmpty ? 0 : await a.pickItemMode(game, p, item, modes);
      int? pick;
      final ip = game.itemPick(p, item, mode);
      if (ip != null) pick = await a.pickItemCardIndex(game, p, item, mode, ip);
      game.playItem(p, item, mode: mode, pick: pick);
      _emit();
    }
  }

  Future<void> _boardCounterWindow() async {
    var guard = 0;
    while (guard++ < 12) {
      final responders = game.boardCounterResponders();
      if (responders.isEmpty) break;
      var responded = false;
      for (final r in responders) {
        final opts = game.playableJustDealt(r);
        final id = await _agent(r).pickBoardCounter(game, r, opts);
        if (id != null) {
          game.playBoardCounter(r, _byId(opts, id));
          _emit();
          responded = true;
          break;
        }
      }
      if (!responded) break;
    }
  }

  Future<void> _playPowerWithCounters(PokerPlayer p, PowerCard card) async {
    final a = _agent(p);
    PokerPlayer? target;
    if (game.cardNeedsPlayerTarget(card)) {
      final targets = game.targetsFor(p, card);
      if (targets.isNotEmpty) {
        final seat = await a.pickTargetSeat(game, p, card, targets);
        if (seat != null) {
          final t = game.players[seat];
          if (targets.contains(t)) target = t;
        }
      }
    }
    if (game.cardHasPayCost(card) && p.compChips > 0) {
      game.payWithChipFor = (await a.payWithChip(game, p, card)) ? p : null;
    } else {
      game.payWithChipFor = null;
    }
    game.proposePower(p, card, targetPlayer: target);
    _emit();

    var guard = 0;
    while (guard++ < 40) {
      final top = game.chainTop;
      if (top == null) break;
      var responded = false;
      for (final r in game.counterRespondersFor(top)) {
        final opts = game.playableCounters(r, top);
        final id = await _agent(r).pickCounter(game, r, top, opts);
        if (id != null) {
          game.proposePower(r, _byId(opts, id), targetEntry: top);
          responded = true;
          break;
        }
      }
      if (!responded) break;
    }
    game.resolveChain();
    game.payWithChipFor = null;
    _emit();
  }

  PowerCard _byId(List<PowerCard> cards, String id) =>
      cards.firstWhere((c) => c.templateId == id, orElse: () => cards.first);
}
