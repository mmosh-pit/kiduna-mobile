import 'dart:math';

import 'cards.dart';
import 'class_cards.dart';
import 'court_cards.dart';
import 'hand_evaluator.dart';
import 'items.dart';
import 'power_cards.dart';

/// AI archetypes drawn from the Medieval Poker class cards.
enum AiPersonality {
  rogue, // tight / aggressive
  merchant, // adaptive / midrange
  warrior, // loose / aggressive
  noble, // tight / control
}

extension AiPersonalityLabel on AiPersonality {
  String get title {
    switch (this) {
      case AiPersonality.rogue:
        return 'The Rogue';
      case AiPersonality.merchant:
        return 'The Merchant';
      case AiPersonality.warrior:
        return 'The Warrior';
      case AiPersonality.noble:
        return 'The Noble';
    }
  }

  String get subtitle {
    switch (this) {
      case AiPersonality.rogue:
        return 'Tight / Aggressive';
      case AiPersonality.merchant:
        return 'Adaptive / Midrange';
      case AiPersonality.warrior:
        return 'Loose / Aggressive';
      case AiPersonality.noble:
        return 'Tight / Control';
    }
  }
}

/// The betting stages of a hand.
enum Street { preflop, flop, turn, river, showdown, handOver }

/// The kinds of action a player can take on their turn.
enum PlayerActionType { fold, check, call, bet, raise }

/// A chosen action. For [bet]/[raise], [amount] is the *total* the player
/// wants their current-round contribution to reach (the "raise-to").
class PokerAction {
  final PlayerActionType type;
  final int amount;
  const PokerAction(this.type, [this.amount = 0]);

  const PokerAction.fold() : this(PlayerActionType.fold);
  const PokerAction.check() : this(PlayerActionType.check);
  const PokerAction.call() : this(PlayerActionType.call);
  const PokerAction.bet(int to) : this(PlayerActionType.bet, to);
  const PokerAction.raise(int to) : this(PlayerActionType.raise, to);
}

/// One player at the table (human or AI).
class PokerPlayer {
  final int seat;

  /// Display name. Defaults to a positional label ("Seat N") and is replaced
  /// with the real player name when a human claims the seat (online).
  String name;
  final bool isHuman;

  /// The player's chosen class (also drives AI playstyle).
  AiPersonality personality;

  /// The player's chosen Court member (adds 9 cards to their deck).
  CourtMember? court;

  int stack;
  List<PlayingCard> hole = [];

  bool folded = false;
  bool allIn = false;
  bool eliminated = false;

  /// Chips contributed during the current betting round.
  int roundBet = 0;

  /// Chips contributed across the whole hand (drives side pots).
  int totalBet = 0;

  /// Whether the player has acted since the last aggressive action.
  bool hasActed = false;

  /// Set at showdown for players who reach it.
  HandValue? showdownHand;

  /// Transient label describing the player's last action (for the UI).
  String? lastActionLabel;

  /// Power Card state (deck-building layer). The hand persists across poker
  /// hands; players draw into it each hand.
  List<PowerCard> powerDeck = [];
  List<PowerCard> powerHand = [];
  List<PowerCard> powerDiscard = [];

  /// One Shot pile — cards removed from the deck cycle (never reshuffled).
  List<PowerCard> oneShotPile = [];

  // ── Status conditions (persist across hands) ──────────────────────────
  /// Heating Up unlocks Fire cards; gained by winning 2 hands in a row.
  bool heatingUp = false;

  /// Tilted locks the player out of Power Cards except Flex / Tilted cards.
  bool tilted = false;

  /// Main pots won in a row (drives Heating Up).
  int consecutiveWins = 0;

  /// Comp Chips can be spent instead of coins when a card says "pay".
  int compChips = 0;

  /// Stealthed (Rogue): can't be targeted by opponents this hand.
  bool stealthed = false;

  /// Locked out of betting/raising this hand (e.g. Intimidate); reset each hand.
  bool cantRaiseThisHand = false;

  /// PEEK: when set, this player's hole cards are shown to the human (e.g. via
  /// Spot the Tell). Reset each hand.
  bool revealedToHuman = false;

  /// Trust Fund token (Noble): gain coins at the start of each Setup.
  bool trustFund = false;

  /// Active Item/Token effects held by this player (persistent across hands).
  List<GameItem> tokens = [];

  /// Persistent Court "character" tokens (keyed by their card templateId).
  List<PowerCard> courtTokens = [];

  PokerPlayer({
    required this.seat,
    required this.name,
    required this.stack,
    this.isHuman = false,
    this.personality = AiPersonality.merchant,
  });

  bool get inHand => !folded && !eliminated;
  // Stack 0 means effectively all-in — even if drained by a Power Card rather
  // than by betting — so such a player can't act.
  bool get canAct => inHand && !allIn && stack > 0;
}

/// Result of awarding one (main or side) pot.
class PotAward {
  final int amount;
  final List<PokerPlayer> winners;
  final bool wasShowdown;
  const PotAward(this.amount, this.winners, this.wasShowdown);
}

/// One Power Card on the counter chain (a LIFO stack of unresolved plays).
class ChainEntry {
  final PokerPlayer player;
  final PowerCard card;

  /// Chosen opponent, for cards that target a player (e.g. Trash Talker).
  PokerPlayer? targetPlayer;

  /// The entry this counter is responding to (for cancel effects).
  ChainEntry? targetEntry;

  /// Set true when a resolving counter cancels this entry.
  bool canceled = false;

  ChainEntry(this.player, this.card, {this.targetPlayer, this.targetEntry});
}

/// A follow-up card pick an item asks the player to make.
class ItemPick {
  final String prompt;
  final List<String> options;

  /// When true the player may decline (a negative index).
  final bool optional;

  const ItemPick(this.prompt, this.options, {this.optional = false});
}

/// Static configuration for a table.
class PokerConfig {
  final int startingStack;
  final List<int> anteLevels;
  final int handsPerLevel;
  final int holeCards;
  final bool enablePowerCards;
  final int maxPowerHand;
  final int compChipsPerPlayer;

  /// Hard cap on hole cards (Power effects can add cards; this bounds both
  /// balance and hand-evaluation cost).
  final int maxHoleCards;

  /// Sudden Death: after the ante levels finish, play [suddenDeathHands] more
  /// hands at [suddenDeathAnte]; then the largest stack wins.
  final int suddenDeathAnte;
  final int suddenDeathHands;

  /// When true, ante levels advance on a real clock ([levelDurationSeconds]
  /// each) instead of by hand count; a hand-count backstop still guarantees
  /// the game ends headlessly.
  final bool timedLevels;
  final int levelDurationSeconds;

  /// Target Power Deck size when building a deck (players choose which cards).
  final int powerDeckSize;

  /// Wild Jokers shuffled into the poker deck.
  final int jokerCount;

  const PokerConfig({
    this.startingStack = 100,
    this.anteLevels = const [1, 3, 5, 10],
    this.handsPerLevel = 4,
    this.holeCards = 3,
    this.enablePowerCards = true,
    this.maxPowerHand = 5,
    this.compChipsPerPlayer = 2,
    this.maxHoleCards = 7,
    this.suddenDeathAnte = 25,
    this.suddenDeathHands = 4,
    this.powerDeckSize = 30,
    this.jokerCount = 1,
    this.timedLevels = false,
    this.levelDurationSeconds = 600,
  });

  PokerConfig copyWith({bool? timedLevels, int? levelDurationSeconds}) =>
      PokerConfig(
        startingStack: startingStack,
        anteLevels: anteLevels,
        handsPerLevel: handsPerLevel,
        holeCards: holeCards,
        enablePowerCards: enablePowerCards,
        maxPowerHand: maxPowerHand,
        compChipsPerPlayer: compChipsPerPlayer,
        maxHoleCards: maxHoleCards,
        suddenDeathAnte: suddenDeathAnte,
        suddenDeathHands: suddenDeathHands,
        powerDeckSize: powerDeckSize,
        jokerCount: jokerCount,
        timedLevels: timedLevels ?? this.timedLevels,
        levelDurationSeconds: levelDurationSeconds ?? this.levelDurationSeconds,
      );
}

/// The authoritative, UI-agnostic Medieval Poker (base variant) engine.
///
/// Drive it turn by turn: [startHand] → repeatedly read [actingPlayer] and
/// call [applyAction] until [isBettingRoundComplete], then [advanceStreet];
/// at [Street.showdown] call [settle].
class PokerGame {
  final PokerConfig config;
  final List<PokerPlayer> players;
  final void Function(String message)? onLog;

  /// Surfaces PEEK information to the human (e.g. "Next board card: K♠").
  final void Function(String message)? onPeek;

  final Deck _deck;
  final Random _rng;
  final List<PlayingCard> community = [];

  /// The counter chain: Power Cards proposed but not yet resolved (LIFO).
  final List<ChainEntry> _chain = [];

  /// Showdown cards played face-down this hand, resolved after the winner is
  /// known.
  final List<ChainEntry> _showdownPending = [];

  /// The last player to bet or raise in the current betting round.
  PokerPlayer? _lastAggressor;

  /// While set, [_payToBank] waives this player's "pay" costs by spending a
  /// Comp Chip instead of coins (set per-play by the UI, then cleared).
  PokerPlayer? payWithChipFor;

  /// Base coin cost of a Power Card's "pay" clause (for the pay-with-chip
  /// prompt). Cards not listed have no "pay" cost.
  static const Map<String, int> _payCosts = {
    'shopping_spree': 10,
    'merchant_bargain_bin': 10,
    'merchant_deal_of_lifetime': 10,
    'noble_exquisite_bounty': 20,
    'king_tip_the_dealer': 10,
  };

  /// Whether [card] has a "pay coins" cost (eligible for a Comp Chip).
  bool cardHasPayCost(PowerCard card) => _payCosts.containsKey(card.templateId);

  int payCostOf(PowerCard card) => _payCosts[card.templateId] ?? 0;

  /// A Midas Crown token in play lets any player sell Comp Chips at Setup.
  bool get midasInPlay =>
      players.any((p) => !p.eliminated && _hasToken(p, 'king_midas'));

  /// Whether [p] may sell a Comp Chip for coins right now (Midas Crown).
  bool canSellChip(PokerPlayer p) =>
      midasInPlay && p.compChips > 0 && !p.eliminated;

  /// Sell one of [p]'s Comp Chips to the bank for [chipSellValue] coins.
  void sellChip(PokerPlayer p) {
    if (!canSellChip(p)) return;
    p.compChips--;
    p.stack += chipSellValue;
    _log('${p.name} sells a Comp Chip for $chipSellValue coins.');
  }

  int get chipSellValue => 10;

  /// Hand-scoped betting restrictions (from cards like Check It Down / Run the
  /// Table / Royal Decree): cold (non-Heating-Up) players can't raise / can't
  /// play Round cards. Reset each hand.
  bool _coldNoRaise = false;
  bool _coldNoRound = false;

  /// The board cards dealt by the most recent [advanceStreet] (for the
  /// "Just Dealt" board-mulligan counters).
  int _lastDealtStart = -1;
  int _lastDealtCount = 0;

  /// True while a Fool's Gold is riding in the pot (its winner is Tilted).
  bool _foolsGoldInPot = false;

  /// Cards burned before each community street (for Grappling Hook).
  final List<PlayingCard> _burn = [];

  Street street = Street.handOver;
  int buttonSeat = 0;
  int handNumber = 0;

  /// Current ante-level index (0-based). >= anteLevels.length ⇒ Sudden Death.
  /// Advanced by the timer (live) and by a hand-count backstop (headless).
  int level = 0;

  /// Sudden-death hands completed, and whether the current hand is one.
  int _suddenDeathDone = 0;
  bool _handInSuddenDeath = false;

  /// Highest per-round contribution anyone has committed this round.
  int currentBet = 0;

  /// Minimum legal raise increment for the current round.
  int minRaiseSize = 0;

  int _actingIndex = -1;

  PokerGame({
    required this.config,
    required this.players,
    Random? rng,
    this.onLog,
    this.onPeek,
  })  : _deck = Deck(rng: rng, jokerCount: config.jokerCount),
        _rng = rng ?? Random() {
    if (config.enablePowerCards) {
      for (final p in players) {
        p.powerDeck = PowerCards.starterDeck(_rng);
        p.compChips = config.compChipsPerPlayer;
      }
    }
  }

  /// The pool of Power Cards a player may include in their deck: every standard
  /// (non-promo) Neutral, plus their class's 12 cards and their Court's 9 cards.
  List<PowerCard> deckCandidatesFor(PokerPlayer p) => <PowerCard>[
        ...PowerCards.standard,
        ...ClassCards.forClass(p.personality),
        ...CourtCards.forMember(p.court),
      ];

  /// Target Power Deck size (players choose which cards to include).
  int get deckSize => config.powerDeckSize;

  /// Build each player's Power Deck from their full candidate pool. Call after
  /// classes and Courts are assigned (used for AI opponents / auto-build).
  void buildDecks() {
    for (final p in players) {
      autoBuildDeckFor(p);
    }
  }

  /// Build [p]'s Power Deck from their full candidate pool (the auto/default
  /// deck). Depends only on [p]'s own class/Court, so it can be called per
  /// player the moment that player finishes setup — no need to wait for others.
  void autoBuildDeckFor(PokerPlayer p) {
    if (!config.enablePowerCards) return;
    _resetPowerPiles(p);
    p.powerDeck = deckCandidatesFor(p)..shuffle(_rng);
  }

  /// Build [p]'s Power Deck from the chosen [templateIds] (deck-building). Ids
  /// not in the candidate pool are ignored; the result is shuffled.
  void buildDeckFor(PokerPlayer p, List<String> templateIds) {
    if (!config.enablePowerCards) return;
    final byId = {for (final c in deckCandidatesFor(p)) c.templateId: c};
    _resetPowerPiles(p);
    p.powerDeck = [
      for (final id in templateIds)
        if (byId[id] != null) byId[id]!,
    ]..shuffle(_rng);
  }

  void _resetPowerPiles(PokerPlayer p) {
    p.powerHand = [];
    p.powerDiscard = [];
    p.oneShotPile = [];
  }

  // ── Derived state ─────────────────────────────────────────────────────

  /// True once the ante levels are exhausted (Sudden Death has begun).
  bool get inSuddenDeath => level >= config.anteLevels.length;

  /// Which Sudden Death hand this is (1-based), or 0 if not in Sudden Death.
  int get suddenDeathHand =>
      inSuddenDeath ? (_suddenDeathDone + 1).clamp(1, config.suddenDeathHands) : 0;

  int get ante => inSuddenDeath
      ? config.suddenDeathAnte
      : config.anteLevels[level.clamp(0, config.anteLevels.length - 1)];

  /// Advance to the next ante level (called by the live timer). Once past the
  /// last level, Sudden Death begins.
  void advanceLevel() => level++;

  /// Keep [level] from lagging the hand count — the timer leads in live play,
  /// but this backstop guarantees the game reaches Sudden Death headlessly.
  void _syncLevelFloor() {
    // A loose cap in timed play (so the clock drives); exact in hand-count play.
    final per = config.timedLevels ? 40 : config.handsPerLevel;
    final byHands = (handNumber - 1) ~/ per;
    if (byHands > level) level = byHands;
  }

  int get pot => players.fold(0, (sum, p) => sum + p.totalBet);

  List<PokerPlayer> get liveInHand =>
      players.where((p) => p.inHand).toList();

  List<PokerPlayer> get contenders => liveInHand; // not folded, not out

  PokerPlayer? get actingPlayer =>
      _actingIndex >= 0 ? players[_actingIndex] : null;

  bool get isBettingRoundComplete => _actingIndex < 0;

  bool get handComplete => street == Street.handOver;

  List<PokerPlayer> get remainingInGame =>
      players.where((p) => !p.eliminated).toList();

  /// Over when one player is left, or when all Sudden Death hands are done.
  bool get isGameOver =>
      remainingInGame.length <= 1 ||
      _suddenDeathDone >= config.suddenDeathHands;

  /// The winner: the last player standing, or (after Sudden Death) the largest
  /// stack. Null while the game is still live.
  PokerPlayer? get gameWinner {
    final rem = remainingInGame;
    if (rem.isEmpty) return null;
    if (rem.length == 1) return rem.first;
    if (_suddenDeathDone >= config.suddenDeathHands) {
      return rem.reduce((a, b) => a.stack >= b.stack ? a : b);
    }
    return null;
  }

  // ── Betting math for the acting player ────────────────────────────────

  int callAmount(PokerPlayer p) =>
      (currentBet - p.roundBet).clamp(0, p.stack);

  bool get facingBet =>
      actingPlayer != null && currentBet - actingPlayer!.roundBet > 0;

  /// Smallest legal raise-to for [p] (may exceed stack → then only all-in).
  int minRaiseTo(PokerPlayer p) {
    final target = currentBet + (minRaiseSize > 0 ? minRaiseSize : ante);
    return min(target, p.roundBet + p.stack);
  }

  /// Largest raise-to for [p] (their entire stack — no-limit).
  int maxRaiseTo(PokerPlayer p) => p.roundBet + p.stack;

  /// Whether [p] may bet or raise right now (respects card-imposed lockouts).
  bool canRaise(PokerPlayer p) {
    if (p.cantRaiseThisHand) return false;
    if (_coldNoRaise && !p.heatingUp) return false;
    return p.stack > callAmount(p);
  }

  /// Perform a call as part of a Power Card effect (the player's turn action
  /// then resolves as a check). Safe to call only for the acting player.
  void _cardCall(PokerPlayer p) {
    final amt = callAmount(p);
    if (amt > 0) _commit(p, amt);
    p.hasActed = true;
    p.lastActionLabel = p.allIn ? 'All-In' : 'Call';
  }

  /// Perform a bet/raise as part of a Power Card effect.
  void _cardRaise(PokerPlayer p, int to) {
    _applyRaise(p, to);
  }

  // ── Hand lifecycle ────────────────────────────────────────────────────

  /// Begin a new hand: rotate the button, post antes, deal hole cards.
  void startHand() {
    handNumber++;
    _syncLevelFloor();
    _handInSuddenDeath = inSuddenDeath;
    community.clear();
    _chain.clear();
    _showdownPending.clear();
    _lastDealtCount = 0;
    _foolsGoldInPot = false;
    _burn.clear();
    _coldNoRaise = false;
    _coldNoRound = false;
    _deck.reset();
    _deck.shuffle();
    currentBet = 0;
    minRaiseSize = ante;

    for (final p in players) {
      p.hole = [];
      p.folded = p.eliminated;
      p.allIn = false;
      p.roundBet = 0;
      p.totalBet = 0;
      p.hasActed = false;
      p.showdownHand = null;
      p.lastActionLabel = null;
      p.stealthed = false;
      p.cantRaiseThisHand = false;
      p.revealedToHuman = false;
    }

    _rotateButton();
    _postAntes();

    // Trust Fund token pays out each Setup.
    for (final p in players) {
      if (!p.eliminated && p.trustFund) _gainFromBank(p, 10);
    }

    // Deal hole cards clockwise from the button.
    for (int i = 0; i < config.holeCards; i++) {
      for (final p in _seatsFrom(buttonSeat + 1)) {
        if (!p.eliminated) p.hole.add(_deck.draw());
      }
    }

    if (config.enablePowerCards) _drawPowerPhase();

    // Setup-time Token effects.
    for (final p in players) {
      if (p.eliminated) continue;
      for (final tok in List<GameItem>.of(p.tokens)) {
        switch (tok.id) {
          case 'merch_stockpile':
            _grantItem(p, _randomItemOfType(ItemType.merchant));
            break;
          case 'cursed_amulet':
            if (p.tilted) _gainHole(p);
            break;
          case 'treasure_goblin':
            _setHeatingUp(p);
            break;
          case 'crystal_ball':
            _drawPower(p, 1);
            break;
        }
      }
      // Court-token Setup effects.
      for (final tok in List<PowerCard>.of(p.courtTokens)) {
        if (tok.templateId == 'jack_royal_skill' && _duelistFor(p)) {
          _gainHole(p);
        }
      }
    }

    street = Street.preflop;
    _log('— Hand $handNumber (ante $ante) —');
    _beginBettingRound();
  }

  /// Each player draws Power Cards at the start of a hand (3 on the very first
  /// hand of the game, otherwise 1), then trims to [PokerConfig.maxPowerHand].
  void _drawPowerPhase() {
    final draws = handNumber == 1 ? 3 : 1;
    for (final p in players) {
      if (p.eliminated) continue;
      _drawPower(p, draws);
    }
  }

  /// "Cut for the deal": draw one card per player; the high card seats the
  /// button (ties broken by suit s>h>d>c, Joker high). Returns each player's
  /// draw. Call once before the first hand; sets [buttonSeat].
  Map<PokerPlayer, PlayingCard> drawForButton() {
    _deck.reset();
    _deck.shuffle();
    int cutValue(PlayingCard c) {
      if (c.isJoker) return 1000;
      const suit = {Suit.spades: 3, Suit.hearts: 2, Suit.diamonds: 1, Suit.clubs: 0};
      return c.rank * 4 + suit[c.suit]!;
    }

    final draws = <PokerPlayer, PlayingCard>{};
    PokerPlayer? winner;
    for (final p in players) {
      if (p.eliminated) continue;
      final c = _deck.draw();
      draws[p] = c;
      if (winner == null || cutValue(c) > cutValue(draws[winner]!)) winner = p;
    }
    if (winner != null) {
      buttonSeat = winner.seat;
      _log('${winner.name} draws the high card and takes the button.');
    }
    return draws; // the deck is reshuffled again in startHand
  }

  void _rotateButton() {
    // Hand 1 keeps the button set by drawForButton (or the default seat 0).
    if (handNumber == 1) return;
    for (int step = 1; step <= players.length; step++) {
      final seat = (buttonSeat + step) % players.length;
      if (!players[seat].eliminated) {
        buttonSeat = seat;
        return;
      }
    }
  }

  void _postAntes() {
    for (final p in players) {
      if (p.eliminated) continue;
      final amount = min(ante, p.stack);
      p.stack -= amount;
      p.totalBet += amount;
      if (p.stack == 0) p.allIn = true;
    }
  }

  /// Reset per-round state and seat the first actor (left of button).
  void _beginBettingRound() {
    currentBet = 0;
    minRaiseSize = ante;
    _lastAggressor = null;
    for (final p in players) {
      p.roundBet = 0;
      p.hasActed = false;
    }
    // If fewer than two players can act, skip straight to the next street.
    if (players.where((p) => p.canAct).length < 2 &&
        _playersToShowdown()) {
      _actingIndex = -1;
      return;
    }
    _onBettingRoundStart();
    _actingIndex = _firstActorFrom(buttonSeat + 1);
  }

  bool _playersToShowdown() {
    // True when the hand should proceed to showdown rather than fold out.
    return contenders.length > 1;
  }

  int _firstActorFrom(int startSeat) {
    for (final p in _seatsFrom(startSeat)) {
      if (p.canAct) return players.indexOf(p);
    }
    return -1;
  }

  /// Players in seat order starting at [startSeat] (wraps around).
  Iterable<PokerPlayer> _seatsFrom(int startSeat) sync* {
    for (int i = 0; i < players.length; i++) {
      yield players[(startSeat + i) % players.length];
    }
  }

  /// Apply [action] for the current [actingPlayer], then advance the turn.
  void applyAction(PokerAction action) {
    final p = actingPlayer;
    if (p == null) {
      throw StateError('No player is currently acting');
    }

    switch (action.type) {
      case PlayerActionType.fold:
        p.folded = true;
        p.hasActed = true;
        p.lastActionLabel = 'Fold';
        _log('${p.name} folds.');
        _onFold(p);
        break;

      case PlayerActionType.check:
        if (callAmount(p) != 0) {
          throw StateError('${p.name} cannot check facing a bet');
        }
        p.hasActed = true;
        p.lastActionLabel = 'Check';
        _log('${p.name} checks.');
        break;

      case PlayerActionType.call:
        final amt = callAmount(p);
        _commit(p, amt);
        p.hasActed = true;
        p.lastActionLabel = p.allIn ? 'All-In' : 'Call';
        _log('${p.name} calls $amt${p.allIn ? ' (all-in)' : ''}.');
        break;

      case PlayerActionType.bet:
      case PlayerActionType.raise:
        _applyRaise(p, action.amount);
        break;
    }

    _advanceActing();
  }

  void _applyRaise(PokerPlayer p, int raiseTo) {
    final target = raiseTo.clamp(p.roundBet + 1, p.roundBet + p.stack);
    final delta = target - p.roundBet;
    final previousBet = currentBet;
    _commit(p, delta);

    final isBet = previousBet == 0;
    if (p.roundBet > currentBet) {
      final increment = p.roundBet - previousBet;
      currentBet = p.roundBet;
      // A full-sized aggressive action reopens the betting to everyone else.
      if (increment >= minRaiseSize) minRaiseSize = increment;
      for (final other in players) {
        if (other != p && other.canAct) other.hasActed = false;
      }
      _lastAggressor = p;
    }
    p.hasActed = true;
    p.lastActionLabel = p.allIn
        ? 'All-In $currentBet'
        : (isBet ? 'Bet $currentBet' : 'Raise $currentBet');
    _log('${p.name} ${p.lastActionLabel!.toLowerCase()}.');
    _onBetRaise(p);
  }

  /// Move [amount] chips from a player's stack into the pot.
  void _commit(PokerPlayer p, int amount) {
    final amt = amount.clamp(0, p.stack);
    p.stack -= amt;
    p.roundBet += amt;
    p.totalBet += amt;
    if (p.stack == 0) p.allIn = true;
  }

  void _advanceActing() {
    // Hand ends immediately if everyone but one has folded.
    if (contenders.length <= 1) {
      _actingIndex = -1;
      return;
    }
    final start = _actingIndex;
    for (int step = 1; step <= players.length; step++) {
      final idx = (start + step) % players.length;
      final p = players[idx];
      if (p.canAct && (!p.hasActed || p.roundBet < currentBet)) {
        _actingIndex = idx;
        return;
      }
    }
    _actingIndex = -1; // round complete
  }

  /// Deal the next street (or move to showdown / hand-over). Call only when
  /// [isBettingRoundComplete] is true.
  void advanceStreet() {
    // Uncontested — everyone folded to one player.
    if (contenders.length <= 1) {
      street = Street.showdown;
      return;
    }
    switch (street) {
      case Street.preflop:
        _burnCard(); // burn before the flop
        _lastDealtStart = community.length;
        community.addAll(_deck.drawMany(3));
        _lastDealtCount = 3;
        street = Street.flop;
        _log('Flop: ${community.map((c) => c.label).join(' ')}');
        _beginBettingRound();
        break;
      case Street.flop:
        _burnCard(); // burn before the turn
        _lastDealtStart = community.length;
        community.add(_deck.draw());
        _lastDealtCount = 1;
        street = Street.turn;
        _log('Turn: ${community.last.label}');
        _beginBettingRound();
        break;
      case Street.turn:
        _burnCard(); // burn before the river
        _lastDealtStart = community.length;
        community.add(_deck.draw());
        _lastDealtCount = 1;
        street = Street.river;
        _log('River: ${community.last.label}');
        _beginBettingRound();
        break;
      case Street.river:
        street = Street.showdown;
        break;
      case Street.showdown:
      case Street.handOver:
        break;
    }
  }

  /// Burn the top card face-down before dealing a community street.
  void _burnCard() {
    if (_deck.remaining > 0) _burn.add(_deck.draw());
  }

  /// True once all community cards are out and no more betting is possible,
  /// so the remaining streets can be dealt without further action.
  bool get shouldRunOutBoard =>
      isBettingRoundComplete &&
      contenders.length > 1 &&
      players.where((p) => p.canAct).length < 2;

  /// Settle the hand: evaluate hands, build side pots, award chips.
  /// Returns the list of pot awards (main pot first).
  List<PotAward> settle() {
    final awards = <PotAward>[];

    // Uncontested pot.
    if (contenders.length == 1) {
      final winner = contenders.first;
      final amount = pot;
      winner.stack += amount;
      awards.add(PotAward(amount, [winner], false));
      _log('${winner.name} wins $amount (uncontested).');
      _finishHand(awards);
      return awards;
    }

    // Lucky Charm: a contender revealing it at showdown gains 2 hole cards
    // (mucks the charm), improving the hand they're about to show.
    for (final p in contenders) {
      if (_holdsItem(p, 'lucky_charm')) {
        _muckItem(p, 'lucky_charm');
        _gainHole(p);
        _gainHole(p);
        _log('${p.name} reveals Lucky Charm (+2 hole cards).');
      }
    }

    // Evaluate every contender's best five-card hand.
    for (final p in contenders) {
      p.showdownHand = HandEvaluator.evaluateBest([...p.hole, ...community]);
    }

    // Build side pots from per-player total contributions.
    final contrib = {for (final p in players) p: p.totalBet};
    while (contrib.values.any((c) => c > 0)) {
      final level = contrib.entries
          .where((e) => e.value > 0)
          .map((e) => e.value)
          .reduce(min);
      final contributors =
          contrib.entries.where((e) => e.value > 0).map((e) => e.key).toList();
      int amount = 0;
      for (final p in contributors) {
        amount += level;
        contrib[p] = contrib[p]! - level;
      }
      final eligible =
          contributors.where((p) => p.inHand && p.showdownHand != null).toList();
      if (eligible.isEmpty) continue;

      HandValue best = eligible.first.showdownHand!;
      for (final p in eligible) {
        if (p.showdownHand! > best) best = p.showdownHand!;
      }
      final winners = eligible
          .where((p) => p.showdownHand!.compareTo(best) == 0)
          .toList()
        ..sort((a, b) => a.seat.compareTo(b.seat));

      _payout(winners, amount);
      awards.add(PotAward(amount, winners, true));
      _log('${winners.map((w) => w.name).join(', ')} '
          'win${winners.length == 1 ? 's' : ''} $amount '
          'with ${best.category.label}.');
      for (final w in winners) {
        // Snake Oil: draw 2 for winning a showdown holding it.
        if (_holdsItem(w, 'snake_oil')) {
          _muckItem(w, 'snake_oil');
          _drawPower(w, 2);
          _log('${w.name} cashes in Snake Oil (draw 2).');
        }
      }
    }

    _finishHand(awards);
    return awards;
  }

  /// Fool's Gold in the pot Tilts whoever wins the (main) pot.
  void _awardFoolsGold(List<PotAward> awards) {
    if (!_foolsGoldInPot || awards.isEmpty) return;
    _foolsGoldInPot = false;
    for (final w in awards.first.winners) {
      if (!w.tilted && !w.eliminated) {
        w.tilted = true;
        _log('${w.name} wins the pot with Fool\'s Gold — now Tilted!');
      }
    }
  }

  void _payout(List<PokerPlayer> winners, int amount) {
    final share = amount ~/ winners.length;
    var remainder = amount - share * winners.length;
    for (final w in winners) {
      w.stack += share;
    }
    // Odd chip goes to the earliest seat left of the button.
    if (remainder > 0) {
      for (final p in _seatsFrom(buttonSeat + 1)) {
        if (winners.contains(p)) {
          p.stack += remainder;
          break;
        }
      }
    }
  }

  void _finishHand(List<PotAward> awards) {
    _applyStatusTransitions(awards);
    // Fool's Gold Tilts the pot winner AFTER status transitions, so the
    // "won a pot → recover" step can't undo the curse.
    _awardFoolsGold(awards);
    for (final p in players) {
      if (!p.eliminated && p.stack <= 0) {
        p.eliminated = true;
        p.folded = true;
        _log('${p.name} is out of chips.');
      }
    }
    if (_handInSuddenDeath) _suddenDeathDone++;
    street = Street.handOver;
  }

  /// Update Heating Up / Tilted based on the main pot (the first award).
  /// Winning the main pot: streak++ (Heating Up at 2 in a row) and Recover.
  /// Losing it: Cool Off and reset the streak.
  void _applyStatusTransitions(List<PotAward> awards) {
    if (awards.isEmpty) return;
    final mainWinners = awards.first.winners.toSet();
    for (final p in players) {
      if (p.hole.isEmpty) continue; // wasn't dealt into this hand
      if (mainWinners.contains(p)) {
        p.consecutiveWins += 1;
        if (p.tilted) {
          p.tilted = false;
          _log('${p.name} recovers from Tilt.');
        }
        if (p.consecutiveWins >= 2 && !p.heatingUp) {
          p.heatingUp = true;
          _log('${p.name} is Heating Up!');
        }
        // Inside Connections: skim a Merchant Item on a pot win.
        if (_hasToken(p, 'inside_connections')) {
          _grantItem(p, _randomItemOfType(ItemType.merchant));
        }
        // Midas Crown: gain a Comp Chip on a pot win.
        if (_hasToken(p, 'king_midas')) _gainCompChips(p, 1);
        // Press the Advantage: return a card from discard on a win.
        if (_hasToken(p, 'jack_press')) {
          _returnFromDiscard(
              p, const {PowerTiming.round, PowerTiming.counter, PowerTiming.setup});
        }
      } else {
        p.consecutiveWins = 0;
        if (p.heatingUp) {
          p.heatingUp = false;
          _log('${p.name} cools off.');
        }
        // Most Wanted: the loser's bounty pays the pot winner(s).
        if (_hasToken(p, 'wanted')) {
          p.tokens.removeWhere((t) => t.id == 'wanted');
          _log('${p.name}\'s bounty is collected!');
          for (final w in mainWinners) {
            _gainFromBank(w, 20);
          }
          for (final o in players) {
            if (!identical(o, p) && !o.eliminated) _drawPower(o, 1);
          }
        }
      }
    }
  }

  // ── Power Cards ───────────────────────────────────────────────────────

  /// Players in acting order starting left of the button (skips eliminated).
  List<PokerPlayer> playersFromButton() =>
      _seatsFrom(buttonSeat + 1).where((p) => !p.eliminated).toList();

  /// Whether [p]'s status allows playing [card] right now (ignoring timing).
  /// Fire cards need Heating Up; a Tilted player may only play Flex / Tilted
  /// cards.
  bool canPlayPower(PokerPlayer p, PowerCard card) {
    // Cursed Amulet: Fire cards are playable while Tilted.
    if (card.fire && p.tilted && _hasToken(p, 'cursed_amulet')) return true;
    if (card.fire && !p.heatingUp) return false;
    if (p.tilted && !(card.flex || card.playableWhileTilted)) return false;
    return true;
  }

  /// Whether [p] holds a persistent token with [id] (Item token or Court token).
  bool _hasToken(PokerPlayer p, String id) =>
      p.tokens.any((t) => t.id == id) ||
      p.courtTokens.any((c) => c.templateId == id);

  /// Duelist bonuses apply heads-up, or always for a Press the Advantage holder.
  bool _duelistFor(PokerPlayer p) =>
      remainingInGame.length <= 2 || _hasToken(p, 'jack_press');

  void _grantCourtToken(PokerPlayer p, PowerCard card) {
    if (!_hasToken(p, card.templateId)) {
      p.courtTokens.add(card);
      _log('${p.name} gains the ${card.name} token.');
    }
  }

  /// The cards in [p]'s hand playable in the given [timing] window, respecting
  /// status conditions.
  List<PowerCard> playablePower(PokerPlayer p, PowerTiming timing) {
    // Round-card silence (Run the Table / Royal Decree) muzzles cold players.
    if (timing == PowerTiming.round && _coldNoRound && !p.heatingUp) return [];
    return p.powerHand
        .where((c) => c.timing == timing && canPlayPower(p, c))
        .toList();
  }

  // ── Counter chain ──────────────────────────────────────────────────

  /// The card currently on top of the counter chain (null if empty).
  ChainEntry? get chainTop => _chain.isEmpty ? null : _chain.last;

  /// Does [card] require the player to choose an opponent to target?
  bool cardNeedsPlayerTarget(PowerCard card) =>
      card.templateId == 'trash_talker' ||
      card.templateId == 'show_mercy' ||
      card.templateId == 'queen_spot_the_tell';

  /// Opponents of [p] that can be targeted (not self, eliminated, or Stealthed).
  List<PokerPlayer> targetableOpponents(PokerPlayer p) => players
      .where((o) => !identical(o, p) && !o.eliminated && !o.stealthed)
      .toList();

  /// The legal targets for [card] played by [actor].
  List<PokerPlayer> targetsFor(PokerPlayer actor, PowerCard card) {
    switch (card.templateId) {
      case 'trash_talker':
        return players
            .where((o) =>
                !identical(o, actor) &&
                !o.eliminated &&
                !o.heatingUp &&
                !o.tilted)
            .toList();
      case 'show_mercy':
        return players
            .where((o) =>
                !identical(o, actor) && (o.folded || o.eliminated))
            .toList();
      default:
        return targetableOpponents(actor);
    }
  }

  bool _canCounter(PowerCard counter, ChainEntry top) {
    // These cancels can only target non-Fire cards.
    const nonFireOnly = {
      'feign_weakness',
      'noble_shiny_distraction',
      'queen_royal_charm',
    };
    if (nonFireOnly.contains(counter.templateId) && top.card.fire) return false;
    return true;
  }

  /// Counter cards in [p]'s hand that may respond to [top] right now. Excludes
  /// "Just Dealt" counters, which respond to board deals instead.
  List<PowerCard> playableCounters(PokerPlayer p, ChainEntry top) {
    if (identical(p, top.player) || p.folded || p.eliminated) return [];
    return p.powerHand
        .where((c) =>
            c.timing == PowerTiming.counter &&
            !c.justDealt &&
            canPlayPower(p, c) &&
            _canCounter(c, top))
        .toList();
  }

  // ── Just-Dealt board counters ──────────────────────────────────────────

  /// "Just Dealt" counters in [p]'s hand playable against the current board.
  List<PowerCard> playableJustDealt(PokerPlayer p) {
    if (p.folded || p.eliminated || _lastDealtCount <= 0) return [];
    return p.powerHand
        .where((c) =>
            c.justDealt &&
            c.timing == PowerTiming.counter &&
            canPlayPower(p, c))
        .toList();
  }

  List<PokerPlayer> boardCounterResponders() =>
      playersFromButton().where((p) => playableJustDealt(p).isNotEmpty).toList();

  /// Play a "Just Dealt" counter: re-deal the most recently dealt board card.
  void playBoardCounter(PokerPlayer p, PowerCard card) {
    if (!p.powerHand.remove(card)) return;
    if (card.oneShot) {
      p.oneShotPile.add(card);
    } else {
      p.powerDiscard.add(card);
    }
    _log('${p.name} plays ${card.name}.');
    final idx = _lastDealtStart + _lastDealtCount - 1;
    switch (card.templateId) {
      case 'river_rat':
        _replaceBoardCard(idx);
        _drawPower(p, 1);
        break;
      case 'run_good':
        _replaceBoardCard(idx);
        _replaceBoardCard(idx); // "you may mulligan it again"
        break;
      case 'monkey':
        int guard = 0;
        while (guard++ < 20 && _deck.remaining > 0) {
          _replaceBoardCard(idx);
          if (idx < 0 || idx >= community.length) break;
          final c = community[idx];
          if (c.isJoker || c.rank >= 11) break;
        }
        break;
    }
    _onMulligan(p); // board card mulligan (Dealer's Favorite etc.)
  }

  void _replaceBoardCard(int index) {
    if (index >= 0 && index < community.length && _deck.remaining > 0) {
      community[index] = _deck.draw();
      _log('Board re-dealt: ${community[index].label}');
    }
  }

  /// Players (in acting order) who could counter [top].
  List<PokerPlayer> counterRespondersFor(ChainEntry top) =>
      playersFromButton().where((p) => playableCounters(p, top).isNotEmpty).toList();

  /// Propose [card] onto the chain (removes it from hand) without resolving.
  /// For a counter, pass [targetEntry] = the entry it responds to.
  ChainEntry proposePower(
    PokerPlayer p,
    PowerCard card, {
    PokerPlayer? targetPlayer,
    ChainEntry? targetEntry,
  }) {
    p.powerHand.remove(card);
    final entry = ChainEntry(p, card,
        targetPlayer: targetPlayer, targetEntry: targetEntry);
    _chain.add(entry);
    final on = targetPlayer != null ? ' on ${targetPlayer.name}' : '';
    _log('${p.name} plays ${card.name}$on.');
    return entry;
  }

  /// Resolve the whole chain most-recent-first (LIFO). Canceled entries skip
  /// their effect but still leave play (One Shot cards that are canceled go to
  /// the discard, not the One Shot pile).
  void resolveChain() {
    while (_chain.isNotEmpty) {
      final e = _chain.removeLast();
      if (!e.canceled) _applyChainEffect(e);
      if (e.card.oneShot && !e.canceled) {
        e.player.oneShotPile.add(e.card);
      } else {
        e.player.powerDiscard.add(e.card);
      }
    }
  }

  bool _isCancelCounter(String id) =>
      ClassCards.cancelCounters.contains(id) ||
      CourtCards.cancelCounters.contains(id);

  void _applyChainEffect(ChainEntry e) {
    if (_isCancelCounter(e.card.templateId)) {
      final t = e.targetEntry;
      if (t != null && !t.canceled) {
        t.canceled = true;
        _log('${e.player.name} cancels ${t.card.name}.');
      }
      switch (e.card.templateId) {
        case 'feign_weakness':
          if (e.player.tilted) {
            e.player.tilted = false;
            _log('${e.player.name} recovers from Tilt.');
          }
          _drawPower(e.player, 1);
          break;
        case 'noble_shiny_distraction':
          if (t != null) _steal(e.player, t.player, 10); // pay owner 10
          break;
        case 'noble_diplomatic_immunity':
          if (t != null && !t.player.tilted) {
            t.player.tilted = true;
            _log('${t.player.name} is Tilted.');
          }
          break;
        case 'queen_royal_charm':
          _setHeatingUp(e.player);
          break;
        // joker_life_of_party: cancel only.
      }
      return;
    }
    _applyPowerEffect(e.player, e.card, target: e.targetPlayer);
  }

  /// Play [card] immediately with no counter window (propose + resolve). Used
  /// for headless play; the interactive UI proposes, runs a counter window,
  /// then calls [resolveChain].
  void playPowerCard(PokerPlayer p, PowerCard card, {PokerPlayer? target}) {
    proposePower(p, card, targetPlayer: target);
    resolveChain();
  }

  void _applyPowerEffect(PokerPlayer p, PowerCard card, {PokerPlayer? target}) {
    switch (card.templateId) {
      // ── Setup ──
      case 'shopping_spree':
        _payToBank(p, 10);
        _grantItem(p, _randomItemOfType(ItemType.merchant));
        _drawPower(p, 1);
        break;
      case 'run_the_table': // Fire
        _setHeatingUp(p);
        _gainHole(p);
        // Cold players must check to you and can't play Round cards.
        _coldNoRaise = true;
        _coldNoRound = true;
        break;
      case 'add_on':
        _gainFromBank(p, p.heatingUp ? 30 : 20);
        break;

      // ── Round ──
      case 'trash_talker':
        final t = target ?? _firstTiltTarget(p);
        if (t != null && !t.eliminated && !t.tilted) {
          t.tilted = true;
          _log('${p.name} tilts ${t.name}!');
        }
        break;
      case 'cash_out':
        p.folded = true;
        _gainFromBank(p, 10);
        if (p.heatingUp) _drawPower(p, 1);
        break;
      case 'snap_call':
        _cardCall(p); // Snap Call: call the bet
        final a = _lastAggressor;
        if (a != null && !identical(a, p) && !a.eliminated) {
          if (a.heatingUp) {
            a.heatingUp = false;
            _log('${a.name} cools off.');
          } else if (!a.tilted) {
            a.tilted = true;
            _log('${p.name} tilts ${a.name}!');
          }
        }
        if (p.heatingUp) _drawPower(p, 1);
        break;
      case 'rock_solid': // Flex
        if (p.heatingUp) {
          p.heatingUp = false;
          _log('${p.name} cools off.');
          _drawPower(p, 2);
        }
        if (p.tilted) {
          p.tilted = false;
          _log('${p.name} recovers from Tilt.');
          _drawPower(p, 1);
        }
        break;
      case 'burst_of_confidence':
        _drawPower(p, 1);
        _setHeatingUp(p);
        break;
      case 'know_when_to_hold': // promo (not in the standard deck)
        _setHeatingUp(p);
        for (final o in players) {
          if (!identical(o, p) && o.inHand && !o.tilted) o.tilted = true;
        }
        break;
      case 'regain_composure': // Tilted card
        p.folded = true;
        if (p.tilted) {
          p.tilted = false;
          _log('${p.name} recovers from Tilt.');
        }
        _returnFromDiscard(p, const {PowerTiming.setup});
        break;

      // ── Counter (Feign Weakness handled in _applyChainEffect) ──
      case 'show_mercy':
        final m = target ?? _firstFoldedOpponent(p);
        if (m != null) {
          _gainFromBank(m, 10);
          if (m.tilted) {
            m.tilted = false;
            _log('${m.name} recovers from Tilt.');
          }
        }
        _drawPower(p, 1);
        break;
      case 'counterplay':
        _returnFromDiscard(p, const {PowerTiming.counter, PowerTiming.round});
        if (p.tilted) {
          p.tilted = false;
          _log('${p.name} recovers from Tilt.');
        }
        break;
      default:
        _applyClassEffect(p, card, target: target);
    }
  }

  // ── Bank + status helpers ──────────────────────────────────────────────

  void _gainFromBank(PokerPlayer p, int n) {
    p.stack += n;
    _log('${p.name} gains $n coins.');
  }

  /// Deal [p] a hole card, respecting the hole-card cap.
  void _gainHole(PokerPlayer p) {
    if (_deck.remaining > 0 && p.hole.length < config.maxHoleCards) {
      p.hole.add(_deck.draw());
    }
  }

  void _payToBank(PokerPlayer p, int n) {
    // Comp Chip: spend a chip instead of coins for this player's "pay" costs.
    if (identical(p, payWithChipFor) && p.compChips > 0) {
      p.compChips--;
      _log('${p.name} pays with a Comp Chip.');
      return;
    }
    p.stack -= n.clamp(0, p.stack);
  }

  void _setHeatingUp(PokerPlayer p) {
    if (!p.heatingUp) {
      p.heatingUp = true;
      _log('${p.name} is Heating Up!');
    }
  }

  PokerPlayer? _firstTiltTarget(PokerPlayer actor) {
    for (final o in players) {
      if (identical(o, actor) || o.eliminated || o.tilted || o.heatingUp) {
        continue;
      }
      return o;
    }
    return null;
  }

  PokerPlayer? _firstFoldedOpponent(PokerPlayer actor) {
    for (final o in players) {
      if (identical(o, actor)) continue;
      if (o.folded || o.eliminated) return o;
    }
    return null;
  }

  // ── Class card primitives ──────────────────────────────────────────────

  void _steal(PokerPlayer from, PokerPlayer to, int n) {
    final amt = n.clamp(0, from.stack);
    from.stack -= amt;
    to.stack += amt;
    if (amt > 0) _log('${to.name} takes $amt coins from ${from.name}.');
  }

  PokerPlayer? _chipLeaderExcluding(PokerPlayer actor) {
    PokerPlayer? best;
    for (final o in players) {
      if (identical(o, actor) || o.eliminated || o.stealthed) continue;
      if (best == null || o.stack > best.stack) best = o;
    }
    return best;
  }

  void _tiltActiveOpponents(PokerPlayer actor, {bool onlyCold = false}) {
    for (final o in players) {
      if (identical(o, actor) || !o.inHand || o.stealthed || o.tilted) continue;
      if (onlyCold && o.heatingUp) continue;
      o.tilted = true;
    }
    _log('${actor.name} tilts the table!');
  }

  void _coolHotOpponents(PokerPlayer actor) {
    for (final o in players) {
      if (identical(o, actor) || o.eliminated) continue;
      if (o.heatingUp) {
        o.heatingUp = false;
        _log('${o.name} cools off.');
      }
    }
  }

  void _stealHoleCard(PokerPlayer from, PokerPlayer to) {
    if (from.hole.isNotEmpty) {
      to.hole.add(from.hole.removeLast());
      _log('${to.name} steals a hole card from ${from.name}.');
    }
  }

  void _mulliganOneHole(PokerPlayer p) {
    // Re-deal the last real (non-item) hole card.
    final i = p.hole.lastIndexWhere((c) => !c.isItem);
    if (i >= 0 && _deck.remaining > 0) {
      p.hole[i] = _deck.draw();
      _onMulligan(p);
    }
  }

  void _mulliganAllHole(PokerPlayer p) {
    var did = false;
    for (int i = 0; i < p.hole.length; i++) {
      if (!p.hole[i].isItem && _deck.remaining > 0) {
        p.hole[i] = _deck.draw();
        did = true;
      }
    }
    if (did) _onMulligan(p);
  }

  /// Re-deal face cards (or non-face cards when [nonFace]) from [p]'s hole.
  void _mulliganFaceHole(PokerPlayer p, {bool nonFace = false}) {
    var did = false;
    for (int i = 0; i < p.hole.length; i++) {
      if (p.hole[i].isItem) continue;
      final isFace = p.hole[i].isJoker || p.hole[i].rank >= 11;
      if ((isFace != nonFace) && _deck.remaining > 0) {
        p.hole[i] = _deck.draw();
        did = true;
      }
    }
    if (did) _onMulligan(p);
  }

  void _mulliganLastBoardUntilFace() {
    final idx = _lastDealtStart + _lastDealtCount - 1;
    int guard = 0;
    while (guard++ < 20 && idx >= 0 && idx < community.length && _deck.remaining > 0) {
      final c = community[idx];
      if (c.isJoker || c.rank >= 11) break;
      community[idx] = _deck.draw();
    }
  }

  void _destroyBoardCard() {
    if (community.isNotEmpty) {
      final c = community.removeLast();
      _log('$c is destroyed from the board.');
    }
  }

  int _rollD6() => 1 + _rng.nextInt(6);

  /// Duelist bonuses apply when the game is down to two players (heads up).

  /// Swap [p]'s last hole card with the last board card.
  void _swapHoleWithBoard(PokerPlayer p) {
    if (p.hole.isNotEmpty && community.isNotEmpty) {
      final h = p.hole.length - 1;
      final b = community.length - 1;
      final tmp = p.hole[h];
      p.hole[h] = community[b];
      community[b] = tmp;
      _log('${p.name} swaps a card with the board.');
    }
  }

  /// Turn the last board card into a Joker Wild.
  void _boardToJoker() {
    if (community.isNotEmpty) {
      community[community.length - 1] = const PlayingCard.joker();
      _log('A board card becomes WILD!');
    }
  }

  void _gainCompChips(PokerPlayer p, int n) {
    p.compChips += n;
    _log('${p.name} gains $n Comp Chip${n == 1 ? '' : 's'}.');
  }

  // ── Persistent-token event hooks ───────────────────────────────────────

  /// A hole/board card was mulliganed by [who].
  void _onMulligan(PokerPlayer who) {
    // Dealer's Favorite: peek the bottom of the deck and take it.
    if (_hasToken(who, 'queen_favorite') && _deck.remaining > 0) {
      if (who.isHuman) {
        onPeek?.call(
            'Bottom of deck: ${_deck.peekBottom(1).map((c) => c.label).join()}');
      }
      if (who.hole.length < config.maxHoleCards) {
        who.hole.add(_deck.drawBottom());
        _log('${who.name} takes the bottom card (Dealer\'s Favorite).');
      }
    }
  }

  /// [aggressor] just bet or raised.
  void _onBetRaise(PokerPlayer aggressor) {
    // Analytical Fighter: a human holder peeks the aggressor's hole cards.
    for (final h in players) {
      if (h.isHuman &&
          !identical(h, aggressor) &&
          _hasToken(h, 'queen_analytical')) {
        aggressor.revealedToHuman = true;
        onPeek?.call('${aggressor.name}\'s hole: '
            '${aggressor.hole.map((c) => c.label).join(' ')}');
      }
    }
  }

  /// Fired at the start of each betting round.
  void _onBettingRoundStart() {
    for (final p in players) {
      if (p.eliminated) continue;
      // Future Sight Ring: a hot human holder peeks the next board card.
      if (p.isHuman &&
          p.heatingUp &&
          _hasToken(p, 'queen_ring') &&
          _deck.remaining > 0) {
        onPeek?.call(
            'Next board card: ${_deck.peek(1).map((c) => c.label).join()}');
      }
      // Drunken Boxing: a Tilted holder digs (mulligan a hole + retrieve).
      if (_hasToken(p, 'joker_drunken_boxing') && p.tilted) {
        _mulliganOneHole(p);
        _returnFromDiscard(p, const {PowerTiming.round, PowerTiming.counter});
      }
    }
  }

  /// [who] folded.
  void _onFold(PokerPlayer who) {
    // Lucky Charm: revealing it on a fold gives Heating Up (mucks the charm).
    if (_holdsItem(who, 'lucky_charm')) {
      _muckItem(who, 'lucky_charm');
      _setHeatingUp(who);
      _log('${who.name} reveals Lucky Charm on the fold — Heating Up!');
    }
    // Adored by All: a holding opponent takes one of the folder's hole cards.
    for (final o in players) {
      if (identical(o, who) || o.eliminated) continue;
      if (_hasToken(o, 'queen_adored') &&
          who.hole.isNotEmpty &&
          o.hole.length < config.maxHoleCards) {
        o.hole.add(who.hole.removeLast());
        _log('${o.name} takes a card from ${who.name} (Adored by All).');
      }
    }
    // Midas Crown: the folder gains a Comp Chip.
    if (_hasToken(who, 'king_midas')) _gainCompChips(who, 1);
  }

  // ── Item / Token economy ───────────────────────────────────────────────

  GameItem? _randomItemOfType(ItemType t) {
    final pool = Items.ofType(t);
    return pool.isEmpty ? null : pool[_rng.nextInt(pool.length)];
  }

  /// Grant [item] to [p]: Tokens stay in play; Items resolve immediately (the
  /// bank has an unlimited supply, matching the physical bank).
  void _grantItem(PokerPlayer p, GameItem? item) {
    if (item == null) return;
    if (item.isToken) {
      if (!_hasToken(p, item.id)) {
        p.tokens.add(item);
        _log('${p.name} gains the ${item.name} token.');
      }
      // Immediate token payoffs on acquisition.
      if (item.id == 'treasure_goblin') _setHeatingUp(p);
      return;
    }
    // Counterfeit Ace is a card substitute — it counts as the Ace of Spades.
    if (item.id == 'counterfeit_ace') {
      if (p.hole.length < config.maxHoleCards) {
        p.hole.add(const PlayingCard(14, Suit.spades));
        _log('${p.name} slips in a Counterfeit Ace.');
      }
      return;
    }
    // On-grant items (Spare Change) resolve immediately on the draw.
    if (item.timing == ItemTiming.onGrant) {
      _log('${p.name} gains ${item.name}.');
      _applyItem(p, item);
      return;
    }
    // Other items are added to the player's hole cards as Item cards (some are
    // played on your turn, others trigger at showdown / in the pot).
    if (p.hole.length < config.maxHoleCards) {
      p.hole.add(PlayingCard.item(item.id));
      _log('${p.name} gains ${item.name}.');
    }
  }

  // ── Held items ─────────────────────────────────────────────────────────

  /// All Item cards held in [p]'s hole cards.
  List<GameItem> heldItems(PokerPlayer p) => [
        for (final c in p.hole)
          if (c.isItem) Items.byId(c.itemId!)!,
      ];

  /// Held Items [p] may actively play on their turn (active + in-pot items;
  /// showdown/on-win items trigger automatically).
  List<GameItem> playableItems(PokerPlayer p) => heldItems(p)
      .where((it) =>
          it.timing == ItemTiming.active || it.timing == ItemTiming.inPot)
      .toList();

  bool _holdsItem(PokerPlayer p, String id) =>
      p.hole.any((c) => c.itemId == id);

  /// Remove one held [itemId] card from [p]'s hole (to the muck).
  void _muckItem(PokerPlayer p, String itemId) {
    final idx = p.hole.indexWhere((c) => c.itemId == itemId);
    if (idx >= 0) p.hole.removeAt(idx);
  }

  /// The mode choices an item offers (empty = a single fixed effect).
  List<String> itemModes(GameItem item) {
    switch (item.id) {
      case 'monkey_paw':
        return const [
          'Gain a hole card, discard a Power Card',
          'Draw 2 Power Cards, discard a hole card',
          'Gain 30 coins — you\'re Tilted',
        ];
      case 'grappling_hook':
        return const [
          'Take a card from the burn pile',
          'Steal a card from a Tilted opponent',
        ];
      default:
        return const [];
    }
  }

  /// A follow-up card pick an item requires (null = none). The chosen index in
  /// [options] is passed back to [playItem] as `pick`; when [optional] the
  /// player may decline (pass a negative index).
  ItemPick? itemPick(PokerPlayer p, GameItem item, int mode) {
    switch (item.id) {
      case 'monkey_paw':
        if (mode == 0 && p.powerHand.isNotEmpty) {
          return ItemPick('Discard a Power Card',
              [for (final c in p.powerHand) c.name]);
        }
        if (mode == 1) {
          final labels = _realHoleIndices(p).map((i) => p.hole[i].label).toList();
          if (labels.isNotEmpty) return ItemPick('Discard a hole card', labels);
        }
        return null;
      case 'rabbit_foot':
        final labels =
            _lowBoardIndices().map((i) => community[i].label).toList();
        if (labels.isNotEmpty) {
          return ItemPick('Mulligan a board card?', labels, optional: true);
        }
        return null;
      default:
        return null;
    }
  }

  /// Actively play a held [item] from [p]'s hole. [mode] selects a choice for
  /// multi-mode items; [pick] answers any follow-up card pick (see [itemPick],
  /// null → the engine auto-picks).
  void playItem(PokerPlayer p, GameItem item, {int mode = 0, int? pick}) {
    if (!_holdsItem(p, item.id)) return;
    if (item.timing == ItemTiming.inPot) {
      // Fool's Gold: put it in the pot as 10 coins; its winner is Tilted.
      _muckItem(p, item.id);
      p.totalBet += 10;
      _foolsGoldInPot = true;
      _log('${p.name} tosses ${item.name} into the pot (+10).');
      return;
    }
    _muckItem(p, item.id);
    _log('${p.name} uses ${item.name}.');
    _applyItem(p, item, mode, pick);
  }

  /// Indices of [p]'s real (non-item) hole cards, in order.
  List<int> _realHoleIndices(PokerPlayer p) => [
        for (int i = 0; i < p.hole.length; i++)
          if (!p.hole[i].isItem) i,
      ];

  /// Board indices holding a 2-9 card (Rabbit Foot targets).
  List<int> _lowBoardIndices() => [
        for (int i = 0; i < community.length; i++)
          if (!community[i].isJoker &&
              !community[i].isItem &&
              community[i].rank <= 9)
            i,
      ];

  /// Discard one Power Card from [p]'s hand — [pick] into powerHand, else first.
  void _discardOnePower(PokerPlayer p, [int? pick]) {
    if (p.powerHand.isEmpty) return;
    final i = (pick != null && pick >= 0 && pick < p.powerHand.length) ? pick : 0;
    p.powerDiscard.add(p.powerHand.removeAt(i));
  }

  /// Discard one real hole card from [p] — [pick] into the real-hole list, else
  /// the lowest.
  void _discardOneHole(PokerPlayer p, [int? pick]) {
    final real = _realHoleIndices(p);
    if (real.isEmpty) return;
    int holeIdx;
    if (pick != null && pick >= 0 && pick < real.length) {
      holeIdx = real[pick];
    } else {
      holeIdx = real.reduce((a, b) => p.hole[a].rank <= p.hole[b].rank ? a : b);
    }
    p.hole.removeAt(holeIdx);
  }

  void _applyItem(PokerPlayer p, GameItem item, [int mode = 0, int? pick]) {
    switch (item.id) {
      case 'monkey_paw':
        switch (mode) {
          case 1:
            _drawPower(p, 2);
            _discardOneHole(p, pick);
            break;
          case 2:
            _gainFromBank(p, 30);
            p.tilted = true;
            _log('${p.name} is Tilted.');
            break;
          default:
            _gainHole(p);
            _discardOnePower(p, pick);
        }
        break;
      case 'rabbit_foot':
        _gainHole(p);
        // Mulligan a 2-9 board card: the player's [pick] (into the low-board
        // list), or the lowest if none chosen. A negative pick declines.
        final low = _lowBoardIndices();
        if (low.isNotEmpty && !(pick != null && pick < 0)) {
          final target = (pick != null && pick < low.length)
              ? low[pick]
              : low.reduce((a, b) => community[a].rank <= community[b].rank ? a : b);
          _replaceBoardCard(target);
        }
        break;
      // lucky_charm / snake_oil / fools_gold are handled by their timing hooks
      // (_applyShowdownItems / _applyWinItems / pot-award), not here.
      case 'spare_change':
        final rich = p.personality == AiPersonality.merchant ||
            p.personality == AiPersonality.noble;
        _gainFromBank(p, rich ? 10 : 5);
        break;
      case 'grappling_hook':
        PokerPlayer? mark;
        for (final o in players) {
          if (!identical(o, p) && o.inHand && o.tilted && o.hole.isNotEmpty) {
            mark = o;
            break;
          }
        }
        // Mode 1: steal from a Tilted opponent (falls back to burn/deck).
        if (mode == 1 && mark != null) {
          _stealHoleCard(mark, p);
        } else if (_burn.isNotEmpty && p.hole.length < config.maxHoleCards) {
          // Mode 0: take a card from the burn pile.
          p.hole.add(_burn.removeLast());
          _log('${p.name} hooks a card from the burn pile.');
        } else if (mark != null) {
          _stealHoleCard(mark, p);
        } else {
          _gainHole(p);
        }
        break;
      case 'smoke_bomb':
        p.folded = true;
        for (final o in players) {
          if (!identical(o, p) && o.inHand && !o.heatingUp &&
              o.powerHand.isNotEmpty) {
            o.powerDiscard.add(o.powerHand.removeLast());
          }
        }
        p.stealthed = true;
        _log('${p.name} is Stealthed.');
        break;
      case 'healing_potion':
        if (p.tilted) {
          _drawPower(p, 2);
          _setHeatingUp(p);
        } else {
          _drawPower(p, 1);
        }
        break;
      case 'counterfeit_ace':
        if (p.hole.length < config.maxHoleCards) {
          p.hole.add(const PlayingCard(14, Suit.spades));
          _log('${p.name} slips in a Counterfeit Ace.');
        }
        break;
    }
  }

  /// Best-effort implementation of the 48 Class cards (see class_cards.dart for
  /// which effects are approximations of the printed cards).
  void _applyClassEffect(PokerPlayer p, PowerCard card, {PokerPlayer? target}) {
    final opp = target ?? _chipLeaderExcluding(p);
    switch (card.templateId) {
      // ── Rogue ──
      case 'rogue_dramatic_reversal':
        _tutor(p, (c) => c.fire, 'Fire');
        _setHeatingUp(p);
        break;
      case 'rogue_back_alley_deal':
        if (opp != null) {
          _grantItem(opp, _randomItemOfType(ItemType.rogue));
          _steal(opp, p, opp.tilted ? 15 : 10);
        }
        break;
      case 'rogue_twist_of_fate':
        final r = _rollD6();
        if (r == 1) {
          p.tilted = true;
          _log('${p.name} is Tilted.');
        } else if (r <= 5) {
          _mulliganOneHole(p);
          _drawPower(p, 1);
          if (p.tilted) {
            p.tilted = false;
            _log('${p.name} recovers from Tilt.');
          }
        } else {
          _gainHole(p);
          _drawPower(p, 2);
          _setHeatingUp(p);
        }
        break;
      case 'rogue_sleight_of_hand':
        _mulliganAllHole(p);
        if (p.heatingUp) _drawPower(p, 2);
        break;
      case 'rogue_splash_the_pot':
        _cardCall(p); // call the bet
        final a = _lastAggressor;
        if (a != null && !identical(a, p) && !a.heatingUp && !a.tilted) {
          a.tilted = true;
          _log('${p.name} tilts ${a.name}!');
        }
        break;
      case 'rogue_hot_dice':
        final r = _rollD6() + _rollD6();
        if (r == 7) {
          p.tilted = true;
          _log('${p.name} is Tilted.');
        } else if (r >= 8) {
          _gainFromBank(p, 25);
          _drawPower(p, 1);
        } else {
          _gainFromBank(p, 5);
        }
        break;
      case 'rogue_misdirection':
        if (opp != null) _steal(opp, p, 15);
        break;
      case 'rogue_ambush':
        if (opp != null) _steal(opp, p, 20);
        break;
      case 'rogue_bag_o_tricks':
        _grantItem(p, _randomItemOfType(ItemType.rogue));
        break;
      case 'rogue_dual_wielding':
        _gainHole(p);
        break;
      case 'rogue_stealth':
        _drawPower(p, 1);
        p.stealthed = true;
        _log('${p.name} is Stealthed.');
        break;

      // ── Warrior ──
      case 'warrior_intimidate':
        final a = _lastAggressor;
        if (a != null && !identical(a, p)) {
          a.cantRaiseThisHand = true; // they check or call instead
          if (a.heatingUp) {
            a.heatingUp = false;
            _log('${a.name} cools off.');
          } else if (!a.tilted) {
            a.tilted = true;
            _log('${p.name} tilts ${a.name}!');
          }
        }
        break;
      case 'warrior_low_ball':
        _mulliganFaceHole(p);
        break;
      case 'warrior_honorable_combat':
        _drawPower(p, 1);
        _gainHole(p);
        break;
      case 'warrior_check_it_down':
        _cardCall(p); // check or call
        _coldNoRaise = true; // cold players can't bet/raise the rest of the hand
        break;
      case 'warrior_ready_to_rumble':
        p.powerDiscard.addAll(p.powerHand);
        p.powerHand = [];
        _drawPower(p, 3);
        p.tilted = true;
        _log('${p.name} is Tilted.');
        if (p.heatingUp) _coolHotOpponents(p);
        break;
      case 'warrior_training_montage':
        _gainHole(p);
        _drawPower(p, 1);
        break;
      case 'warrior_mad_money':
        _gainFromBank(p, p.tilted ? 30 : 20);
        // ...then bet or raise.
        if (canRaise(p)) {
          final to = (currentBet + max(minRaiseSize, ante))
              .clamp(minRaiseTo(p), maxRaiseTo(p))
              .toInt();
          _cardRaise(p, to);
        }
        _tiltActiveOpponents(p, onlyCold: true);
        break;
      case 'warrior_table_taunts':
        if (opp != null && !opp.heatingUp && !opp.tilted) {
          opp.tilted = true;
          _log('${p.name} tilts ${opp.name}!');
        }
        p.tilted = true;
        _drawPower(p, 1);
        break;
      case 'warrior_inferno_strike':
        if (opp != null) {
          _payToBank(opp, opp.heatingUp ? 30 : 20);
          _log('${p.name} destroys coins from ${opp.name}!');
        }
        if (p.heatingUp) {
          p.heatingUp = false;
          _log('${p.name} cools off.');
        }
        break;
      case 'warrior_mighty_blow':
        _destroyBoardCard();
        _setHeatingUp(p);
        break;
      case 'warrior_show_of_strength':
        if (opp != null && opp.powerHand.isNotEmpty) {
          opp.powerDiscard.add(opp.powerHand.removeLast());
          _log('${opp.name} discards a Power Card.');
        }
        if (p.tilted) {
          p.tilted = false;
          _log('${p.name} recovers from Tilt.');
        }
        break;

      // ── Merchant ──
      case 'merchant_fire_sale':
        _gainFromBank(p, p.heatingUp ? 15 : 10);
        break;
      case 'merchant_irresistible_offer':
        if (opp != null) {
          _steal(opp, p, 10);
          _grantItem(opp, _randomItemOfType(ItemType.merchant));
        }
        break;
      case 'merchant_special_delivery':
        _grantItem(p, _randomItemOfType(ItemType.merchant));
        _grantItem(p, _randomItemOfType(ItemType.merchant));
        break;
      case 'merchant_bargain_bin':
        _payToBank(p, 10);
        for (int i = 0; i < 2; i++) {
          _gainHole(p);
        }
        break;
      case 'merchant_wheel_and_deal':
        _gainHole(p);
        break;
      case 'merchant_expansion_plans':
        _grantItem(
            p, _rng.nextBool() ? Items.merchStockpile : Items.insideConnections);
        break;
      case 'merchant_mystical_wares':
        _grantItem(p, _randomItemOfType(ItemType.merchantToken));
        break;
      case 'merchant_hot_tip':
        _tutor(p, (c) => c.timing == PowerTiming.setup, 'Setup');
        _setHeatingUp(p);
        break;
      case 'merchant_deal_of_lifetime':
        for (int i = 0; i < 3; i++) {
          if (p.stack >= 10 && p.hole.length < config.maxHoleCards) {
            _payToBank(p, 10);
            _gainHole(p);
          }
        }
        if (p.heatingUp) {
          p.heatingUp = false;
          _log('${p.name} cools off.');
        }
        break;
      case 'merchant_hired_muscle':
        if (opp != null) _stealHoleCard(opp, p);
        if (p.tilted) {
          p.tilted = false;
          _log('${p.name} recovers from Tilt.');
        }
        break;

      // ── Noble ──
      case 'noble_curry_favor':
        final m = _firstFoldedOpponent(p);
        if (m != null) {
          _gainFromBank(m, 10);
          if (m.tilted) m.tilted = false;
        }
        _drawPower(p, 2);
        _setHeatingUp(p);
        break;
      case 'noble_alms_for_the_poor':
        int cnt = 0;
        for (final o in players) {
          if (!identical(o, p) && !o.eliminated && o.stack < p.stack) {
            _grantItem(o, Items.spareChange);
            cnt++;
          }
        }
        if (cnt > 0) _drawPower(p, cnt);
        break;
      case 'noble_trust_fund':
        _gainFromBank(p, 10);
        p.trustFund = true;
        break;
      case 'noble_bankroll_backer':
        p.folded = true;
        _drawPower(p, 1);
        break;
      case 'noble_royal_decree':
        // Silence: cold players can't play Round cards. You're Heating Up.
        _setHeatingUp(p);
        _coldNoRound = true;
        break;
      case 'noble_exquisite_bounty':
        _payToBank(p, 20);
        final t = _chipLeaderExcluding(p);
        if (t != null) _grantItem(t, Items.wanted);
        break;
      case 'noble_tax_the_rich':
        for (final o in players) {
          if (!identical(o, p) && !o.eliminated && o.stack > p.stack) {
            _steal(o, p, 10);
          }
        }
        _gainFromBank(p, 10);
        _setHeatingUp(p);
        break;
      case 'noble_powerful_friends':
        _mulliganLastBoardUntilFace();
        _mulliganFaceHole(p, nonFace: true);
        break;
      case 'noble_inheritance':
        _gainFromBank(p, 20);
        break;

      // ── Court: Jack ──
      case 'jack_double_attack':
        _returnFromDiscard(p, const {PowerTiming.round});
        _returnFromDiscard(p, const {PowerTiming.round});
        break;
      case 'jack_tactical_retreat':
        p.folded = true;
        _setHeatingUp(p);
        _tutor(p, (c) => _duelistFor(p) ? c.timing == PowerTiming.setup : c.tableTalk,
            _duelistFor(p) ? 'Setup' : 'Table Talk');
        break;
      case 'jack_royal_skill':
        _grantCourtToken(p, card);
        if (_duelistFor(p)) _gainHole(p);
        break;
      case 'jack_adaptive_playstyle':
        _drawPower(p, 1);
        break;
      case 'jack_hit_the_flop':
        _destroyBoardCard();
        if (_duelistFor(p)) _mulliganAllHole(p);
        break;
      case 'jack_bachelor':
        _tutor(p, (c) => c.tableTalk, 'Table Talk');
        _setHeatingUp(p);
        break;
      case 'jack_guerrilla':
        if (opp != null) _steal(opp, p, _duelistFor(p) ? 30 : 10);
        break;
      case 'jack_mithril':
        _grantCourtToken(p, card); // passive (Replay not modeled)
        break;
      case 'jack_press':
        _grantCourtToken(p, card); // Duelist always active; returns on a win
        _setHeatingUp(p);
        break;

      // ── Court: Queen ──
      case 'queen_spot_the_tell':
        final t = target ?? _chipLeaderExcluding(p);
        if (t != null) {
          if (p.isHuman) {
            t.revealedToHuman = true;
            onPeek?.call('${t.name}\'s hole: '
                '${t.hole.map((c) => c.label).join(' ')}');
            _log('${p.name} peeks at ${t.name}\'s hole cards.');
          }
          if (t.heatingUp) {
            t.heatingUp = false;
            _log('${t.name} cools off.');
          }
        }
        break;
      case 'queen_brilliant_strategist':
        if (p.isHuman) {
          onPeek?.call(
              'Top of deck: ${_deck.peek(3).map((c) => c.label).join('  ')}');
        }
        break;
      case 'queen_analytical':
        _grantCourtToken(p, card); // peek an opponent's card when they bet
        break;
      case 'queen_sick_laydown':
        p.folded = true;
        _setHeatingUp(p);
        if (p.isHuman) {
          final top =
              p.powerDeck.reversed.take(3).map((c) => c.name).join(', ');
          if (top.isNotEmpty) onPeek?.call('Your next Power Cards: $top');
        }
        break;
      case 'queen_table_flirt':
        _setHeatingUp(p);
        _drawPower(p, 1);
        _coolHotOpponents(p);
        break;
      case 'queen_adored':
        _grantCourtToken(p, card); // take a card when an opponent folds
        break;
      case 'queen_favorite':
        _grantCourtToken(p, card); // peek+take on any mulligan
        break;
      case 'queen_ring':
        _grantCourtToken(p, card); // peek a future board card each round (hot)
        break;

      // ── Court: King ──
      case 'king_iou':
        // Call a bet using Comp Chips instead of coins (needs ≥1).
        if (p.compChips > 0) {
          final amt = callAmount(p);
          _commit(p, amt);
          p.stack += amt; // refund coins — the call is paid in Comp Chips
          p.compChips = 0;
          p.hasActed = true;
          p.lastActionLabel = 'Call (chips)';
        }
        break;
      case 'king_tip_the_dealer':
        _payToBank(p, 10);
        _gainHole(p);
        _gainHole(p);
        if (p.heatingUp) _gainCompChips(p, 1);
        break;
      case 'king_royal_rebuy':
        _gainFromBank(p, 100);
        _drawPower(p, 3);
        break;
      case 'king_vip':
        _gainCompChips(p, 1);
        _gainFromBank(p, 10);
        _gainHole(p);
        _drawPower(p, 1);
        break;
      case 'king_bomb_pot':
        p.totalBet += 20; // doubles the pot from the bank
        _log('${p.name} bombs the pot (+20).');
        _drawPower(p, 1);
        break;
      case 'king_midas':
        _grantCourtToken(p, card); // gain a Comp Chip on each fold / pot win
        break;
      case 'king_gold_for_gifts':
        _gainFromBank(p, 10);
        break;
      case 'king_match_might':
        _drawPower(p, 1);
        _gainCompChips(p, 1);
        break;
      case 'king_stimulus':
        for (final o in players) {
          if (!o.eliminated) {
            _gainCompChips(o, 1);
            _gainFromBank(o, 10);
          }
        }
        break;

      // ── Court: Joker ──
      case 'joker_highlander':
        _gainHole(p);
        _drawPower(p, 1);
        break;
      case 'joker_split_personality':
        if (p.tilted) {
          p.tilted = false;
          _log('${p.name} recovers from Tilt.');
          _tutor(p, (c) => c.playableWhileTilted, 'Tilted');
        } else if (p.heatingUp) {
          _tutor(p, (c) => c.fire, 'Fire');
        }
        break;
      case 'joker_quick_change':
        _swapHoleWithBoard(p);
        break;
      case 'joker_royal_wild':
        _boardToJoker();
        break;
      case 'joker_fire_juggler':
        _setHeatingUp(p);
        final fj = _chipLeaderExcluding(p);
        if (fj != null && fj.heatingUp) {
          fj.heatingUp = false;
          _log('${fj.name} cools off.');
        }
        break;
      case 'joker_game_of_chance':
        if (_rollD6() >= 3) {
          _gainHole(p);
          _drawPower(p, 1);
        }
        break;
      case 'joker_drunken_boxing':
        _grantCourtToken(p, card); // while Tilted: dig each betting round
        break;
      case 'joker_trading_up':
        // changelog 7.21.2026: Merchant Item → Non-Magic Item.
        final pool = Items.nonMagicItems;
        _grantItem(p, pool[_rng.nextInt(pool.length)]);
        break;
    }
  }

  /// Move the most recent discard matching [timings] back into [p]'s hand.
  void _returnFromDiscard(PokerPlayer p, Set<PowerTiming> timings) {
    for (int i = p.powerDiscard.length - 1; i >= 0; i--) {
      if (timings.contains(p.powerDiscard[i].timing)) {
        final c = p.powerDiscard.removeAt(i);
        p.powerHand.add(c);
        _log('${p.name} returns ${c.name} from discard.');
        return;
      }
    }
  }

  /// Search the power deck for a card matching [test], move it to hand, reshuffle.
  void _tutor(PokerPlayer p, bool Function(PowerCard) test, String what) {
    final idx = p.powerDeck.indexWhere(test);
    if (idx < 0) return;
    final c = p.powerDeck.removeAt(idx);
    p.powerDeck.shuffle(_rng);
    p.powerHand.add(c);
    _log('${p.name} searches for a $what card (${c.name}).');
  }

  bool _hasPairOrTrips(List<PlayingCard> hole) {
    final counts = <int, int>{};
    for (final c in hole) {
      if (c.isItem) continue;
      if (c.isJoker) return true;
      counts[c.rank] = (counts[c.rank] ?? 0) + 1;
    }
    return counts.values.any((n) => n >= 2);
  }

  // ── Showdown window ────────────────────────────────────────────────────

  /// Showdown cards in [p]'s hand playable now (p must still be in the hand).
  List<PowerCard> playableShowdown(PokerPlayer p) =>
      p.inHand ? playablePower(p, PowerTiming.showdown) : [];

  /// Play a Showdown card face-down (resolved after the winner is known).
  /// One Tough Cookie's "on play" tutor happens immediately.
  void proposeShowdown(PokerPlayer p, PowerCard card) {
    if (!p.powerHand.remove(card)) return;
    _showdownPending.add(ChainEntry(p, card));
    _log('${p.name} plays ${card.name} face down.');
    if (card.templateId == 'one_tough_cookie') {
      _tutor(p, (c) => c.fire, 'Fire');
    } else if (card.templateId == 'rogue_ace_up_sleeve' && p.hole.isNotEmpty) {
      p.hole[0] = const PlayingCard(14, Suit.spades);
      _log('${p.name} slips an Ace into their hand.');
    }
  }

  bool get hasPendingShowdown => _showdownPending.isNotEmpty;

  /// Resolve pending Showdown cards using the main-pot [winners], then
  /// reconcile eliminations (bank top-ups can revive a busted player).
  void resolveShowdown(Set<PokerPlayer> winners) {
    for (final e in _showdownPending) {
      _applyShowdownEffect(e.player, e.card, winners.contains(e.player));
      if (e.card.oneShot) {
        e.player.oneShotPile.add(e.card);
      } else {
        e.player.powerDiscard.add(e.card);
      }
    }
    _showdownPending.clear();
    _reconcileElimination();
  }

  void _applyShowdownEffect(PokerPlayer p, PowerCard card, bool won) {
    switch (card.templateId) {
      case 'ride_the_wave':
        _drawPower(p, 1);
        if (won) {
          _tutor(p, (c) => c.fire, 'Fire');
          _setHeatingUp(p);
        } else {
          _tutor(p, (c) => c.playableWhileTilted, 'Tilted');
          p.tilted = true;
          _log('${p.name} is Tilted.');
        }
        break;
      case 'poor_winner':
        if (won) {
          final minStack = players
              .where((x) => !x.eliminated)
              .map((x) => x.stack)
              .fold<int>(1 << 30, min);
          if (p.stack <= minStack) _gainFromBank(p, 20);
          for (final o in players) {
            if (!identical(o, p) && o.inHand && !o.tilted) o.tilted = true;
          }
        } else {
          p.tilted = true;
          _drawPower(p, 1);
        }
        break;
      case 'pocket_protector':
        final pt = _hasPairOrTrips(p.hole);
        if (won && pt) {
          _drawPower(p, 1); // (saving hole cards not modeled)
        } else if (!won && pt) {
          _gainFromBank(p, 30);
        }
        break;
      case 'top_up':
        if (won) {
          _drawPower(p, 1);
          _setHeatingUp(p);
        } else {
          _gainFromBank(p, 30);
          if (p.tilted) {
            p.tilted = false;
            _log('${p.name} recovers from Tilt.');
          }
        }
        break;
      case 'one_tough_cookie':
        if (won) {
          _setHeatingUp(p);
        } else {
          _returnFromDiscard(p, const {PowerTiming.setup, PowerTiming.round});
        }
        break;
      // ── Class showdown cards ──
      case 'rogue_ace_up_sleeve':
        if (won) _tiltActiveOpponents(p);
        break;
      case 'warrior_berserker_rage':
        _drawPower(p, 2);
        p.tilted = true;
        _log('${p.name} is Tilted.');
        break;
      case 'merchant_rotate_merchandise':
        p.powerDiscard.addAll(p.powerHand);
        p.powerHand = [];
        _drawPower(p, 3);
        break;
      case 'merchant_hidden_gems':
        _grantItem(p, won ? Items.rabbitFoot : Items.monkeyPaw);
        break;
      case 'noble_friendly_chop':
        if (!won) _setHeatingUp(p);
        break;
    }
  }

  void _reconcileElimination() {
    for (final p in players) {
      if (p.stack <= 0 && !p.eliminated) {
        p.eliminated = true;
        p.folded = true;
        _log('${p.name} is out of chips.');
      } else if (p.stack > 0 && p.eliminated) {
        p.eliminated = false;
        _log('${p.name} claws back into the game!');
      }
    }
  }

  /// Draw [n] Power Cards into [p]'s hand, reshuffling the discard when the
  /// deck runs dry, then trim to the hand limit.
  void _drawPower(PokerPlayer p, int n) {
    for (int i = 0; i < n; i++) {
      if (p.powerDeck.isEmpty) {
        if (p.powerDiscard.isEmpty) break;
        p.powerDeck = p.powerDiscard..shuffle(_rng);
        p.powerDiscard = [];
      }
      p.powerHand.add(p.powerDeck.removeLast());
    }
    while (p.powerHand.length > config.maxPowerHand) {
      // Overflow returns to the bottom of the draw pile (oldest first).
      p.powerDeck.insert(0, p.powerHand.removeAt(0));
    }
  }

  /// Reset the whole game to fresh stacks and freshly built Power decks.
  void resetGame() {
    for (final p in players) {
      p.stack = config.startingStack;
      p.eliminated = false;
      p.folded = false;
      p.allIn = false;
      p.hole = [];
      p.roundBet = 0;
      p.totalBet = 0;
      p.showdownHand = null;
      p.lastActionLabel = null;
      p.powerHand = [];
      p.powerDiscard = [];
      p.oneShotPile = [];
      p.heatingUp = false;
      p.tilted = false;
      p.stealthed = false;
      p.trustFund = false;
      p.tokens = [];
      p.courtTokens = [];
      p.consecutiveWins = 0;
      p.compChips = config.compChipsPerPlayer;
      p.powerDeck =
          config.enablePowerCards ? PowerCards.starterDeck(_rng) : [];
    }
    handNumber = 0;
    level = 0;
    _suddenDeathDone = 0;
    _handInSuddenDeath = false;
    buttonSeat = 0;
    community.clear();
    street = Street.handOver;
  }

  void _log(String message) => onLog?.call(message);
}
