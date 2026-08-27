import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'package:medieval_poker_engine/medieval_poker_engine.dart';

import 'components/card_component.dart';
import 'components/seat_component.dart';
import 'components/table_component.dart';
import 'poker_assets.dart';
import 'seat_ring.dart';

/// Immutable snapshot the Flutter overlay renders. Rebuilt on every state
/// change and published through [MedievalPokerGame.view].
@immutable
class PokerViewState {
  final String banner;
  final int pot;
  final bool showActions;
  final bool canCheck;
  final bool canCall;
  final int callAmount;
  final bool canRaise;
  final int minRaiseTo;
  final int maxRaiseTo;
  final int humanRoundBet;
  final bool gameOver;
  final bool won;
  final String resultText;

  /// Power Card prompt (human's turn to play from a timing window, or counter).
  final bool showPower;
  final String powerTitle;
  final String powerDismissLabel;
  final List<PowerOption> powerOptions;

  /// Target picker (choose an opponent for a targeted card).
  final bool showTarget;
  final String targetTitle;
  final List<TargetOption> targetOptions;

  /// Class / Court selection (pre-match deck-building).
  final bool showClassSelect;
  final List<TargetOption> classOptions;
  final bool showCourtSelect;
  final List<TargetOption> courtOptions;

  /// Deck-building (choose your Power Cards).
  final bool showDeckBuild;
  final List<DeckCardInfo> deckPool;
  final int deckTarget;

  /// Pay-with-Comp-Chip prompt.
  final bool showPayChoice;
  final String payCardName;
  final int payCost;
  final int compChips;

  /// Sell-a-Comp-Chip prompt (Midas Crown, at Setup).
  final bool showChipSell;
  final int chipSellValue;

  /// Play-a-held-Item prompt.
  final bool showItemPlay;
  final List<PowerOption> itemOptions;

  /// Item-mode choice prompt (e.g. Monkey Paw's three options).
  final bool showItemMode;
  final String itemModeTitle;
  final List<String> itemModeOptions;

  const PokerViewState({
    this.banner = '',
    this.pot = 0,
    this.showActions = false,
    this.canCheck = false,
    this.canCall = false,
    this.callAmount = 0,
    this.canRaise = false,
    this.minRaiseTo = 0,
    this.maxRaiseTo = 0,
    this.humanRoundBet = 0,
    this.gameOver = false,
    this.won = false,
    this.resultText = '',
    this.showPower = false,
    this.powerTitle = '',
    this.powerDismissLabel = 'Continue',
    this.powerOptions = const [],
    this.showTarget = false,
    this.targetTitle = '',
    this.targetOptions = const [],
    this.showClassSelect = false,
    this.classOptions = const [],
    this.showCourtSelect = false,
    this.courtOptions = const [],
    this.showDeckBuild = false,
    this.deckPool = const [],
    this.deckTarget = 30,
    this.showPayChoice = false,
    this.payCardName = '',
    this.payCost = 0,
    this.compChips = 0,
    this.showChipSell = false,
    this.chipSellValue = 10,
    this.showItemPlay = false,
    this.itemOptions = const [],
    this.showItemMode = false,
    this.itemModeTitle = '',
    this.itemModeOptions = const [],
  });
}

/// The human's outcome for a just-finished hand (drives the result flash).
@immutable
class HandResult {
  final bool won;
  final bool folded; // human wasn't in the showdown
  final String detail; // e.g. "won 60 with a Flush" or "The Rogue won 40"
  const HandResult({
    required this.won,
    required this.folded,
    required this.detail,
  });
}

/// One playable Power Card offered to the human.
@immutable
class PowerOption {
  final String name;
  final String description;
  final String templateId;
  const PowerOption(this.name, this.description, this.templateId);
}

/// One opponent offered as a target.
@immutable
class TargetOption {
  final String name;
  final String subtitle;
  const TargetOption(this.name, this.subtitle);
}

/// One candidate Power Card offered in the deck-builder.
@immutable
class DeckCardInfo {
  final String templateId;
  final String name;
  final String description;
  final String group; // 'Neutral' | 'Class' | 'Court'
  final String timing; // 'Setup' | 'Round' | 'Showdown' | 'Counter'
  const DeckCardInfo(
    this.templateId,
    this.name,
    this.description,
    this.group,
    this.timing,
  );
}

/// A labelled section of the Power Deck viewer (In Hand / Draw Deck / …).
@immutable
class DeckSection {
  final String label;
  final List<DeckCardInfo> cards;
  const DeckSection(this.label, this.cards);
}

/// Single-player Medieval Poker (base variant) rendered with Flame. Owns the
/// [PokerGame] engine and drives the hand loop, pausing for animations and for
/// human input.
class MedievalPokerGame extends FlameGame {
  final PokerConfig config;
  final int opponentCount;
  final String humanName;
  final Random _rng;

  late PokerGame engine;
  late AiBrain _ai;

  final ValueNotifier<PokerViewState> view = ValueNotifier(
    const PokerViewState(banner: 'Shuffling up...'),
  );
  final ValueNotifier<List<String>> log = ValueNotifier(const []);

  /// Short label for the current stage (ante level / Sudden Death).
  final ValueNotifier<String> stage = ValueNotifier('');

  /// Seconds left in the current timed ante level (0 = no timer / Sudden Death).
  final ValueNotifier<int> levelClock = ValueNotifier(0);
  double _levelElapsed = 0;

  /// The human's current Power Card hand (for the fanned display).
  final ValueNotifier<List<PowerOption>> hand = ValueNotifier(const []);

  /// Transient PEEK reveal text (opponent hole cards, upcoming deck cards).
  final ValueNotifier<String> peek = ValueNotifier('');
  int _peekToken = 0;

  /// The most recent hand's result for the human (null = no flash showing).
  final ValueNotifier<HandResult?> handResult = ValueNotifier(null);

  /// Whether the in-game Power Deck viewer is open.
  final ValueNotifier<bool> showDeck = ValueNotifier(false);

  /// Whether the in-game rules Reference is open.
  final ValueNotifier<bool> showReference = ValueNotifier(false);

  final PokerCardAtlas _cardAtlas = PokerCardAtlas();
  late TableComponent _table;
  final List<SeatComponent> _seats = [];
  final List<CardComponent> _board = [];
  late TextComponent _potText;

  Completer<PokerAction>? _humanCompleter;
  Completer<int>? _powerCompleter;
  Completer<int>? _targetCompleter;
  Completer<int>? _classCompleter;
  Completer<int>? _courtCompleter;
  Completer<List<String>>? _deckCompleter;
  Completer<bool>? _payCompleter;
  Completer<bool>? _chipSellCompleter;
  Completer<int>? _itemCompleter;
  Completer<int>? _itemModeCompleter;

  /// The human's chosen deck (template ids), reused across restarts.
  List<String>? _humanDeck;
  bool _ready = false;

  static const _classOrder = [
    AiPersonality.rogue,
    AiPersonality.merchant,
    AiPersonality.warrior,
    AiPersonality.noble,
  ];
  static const _courtOrder = [
    CourtMember.jack,
    CourtMember.queen,
    CourtMember.king,
    CourtMember.joker,
  ];
  int _loopToken = 0;

  /// Debug: reveal every opponent's hole cards (sandbox testing).
  final bool revealAll;

  MedievalPokerGame({
    this.config = const PokerConfig(timedLevels: true),
    this.opponentCount = 3,
    this.humanName = 'You',
    this.revealAll = false,
    Random? rng,
  }) : _rng = rng ?? Random();

  @override
  Color backgroundColor() => const Color(0xFF14100A);

  @override
  void onRemove() {
    // Stop the hand loop and unblock any pending human turn on teardown.
    _loopToken++;
    final a = _humanCompleter;
    if (a != null && !a.isCompleted) {
      _humanCompleter = null;
      a.complete(const PokerAction.fold());
    }
    final pw = _powerCompleter;
    if (pw != null && !pw.isCompleted) {
      _powerCompleter = null;
      pw.complete(-1);
    }
    final tg = _targetCompleter;
    if (tg != null && !tg.isCompleted) {
      _targetCompleter = null;
      tg.complete(-1);
    }
    final cl = _classCompleter;
    if (cl != null && !cl.isCompleted) {
      _classCompleter = null;
      cl.complete(0);
    }
    final co = _courtCompleter;
    if (co != null && !co.isCompleted) {
      _courtCompleter = null;
      co.complete(0);
    }
    final dk = _deckCompleter;
    if (dk != null && !dk.isCompleted) {
      _deckCompleter = null;
      dk.complete(const []); // empty → auto-built deck stays
    }
    final pc = _payCompleter;
    if (pc != null && !pc.isCompleted) {
      _payCompleter = null;
      pc.complete(false);
    }
    final cs = _chipSellCompleter;
    if (cs != null && !cs.isCompleted) {
      _chipSellCompleter = null;
      cs.complete(false);
    }
    final it = _itemCompleter;
    if (it != null && !it.isCompleted) {
      _itemCompleter = null;
      it.complete(-1);
    }
    final im = _itemModeCompleter;
    if (im != null && !im.isCompleted) {
      _itemModeCompleter = null;
      im.complete(-1);
    }
    super.onRemove();
  }

  @override
  Future<void> onLoad() async {
    _ai = AiBrain(rng: _rng);
    _buildEngine();

    // Load card art (falls back to drawn cards if unavailable).
    await _cardAtlas.load();

    // Table felt — added first so it renders behind everything.
    _table = TableComponent();
    await add(_table);

    // Seats — one per player, created once and reused across hands.
    for (final p in engine.players) {
      final seat = SeatComponent(
        player: p,
        holeCardCount: config.holeCards,
        atlas: _cardAtlas,
        cardSize: p.isHuman ? Vector2(48, 66) : Vector2(40, 56),
      );
      _seats.add(seat);
      await add(seat);
    }

    // Community cards.
    for (int i = 0; i < 5; i++) {
      final c = CardComponent(size: Vector2(46, 64), atlas: _cardAtlas);
      _board.add(c);
      await add(c);
    }

    _potText = TextComponent(
      text: '',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFEDC169),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      anchor: Anchor.center,
    );
    await add(_potText);

    _ready = true;
    _layout();
    _setupAndStart();
  }

  /// Pre-match deck-building: the human chooses a class, opponents take the
  /// others, decks are built, then the hand loop begins.
  Future<void> _setupAndStart() async {
    view.value = const PokerViewState(
      banner: 'Choose your class',
      showClassSelect: true,
      classOptions: [
        TargetOption('The Rogue', 'Tight / Aggressive'),
        TargetOption('The Merchant', 'Adaptive / Midrange'),
        TargetOption('The Warrior', 'Loose / Aggressive'),
        TargetOption('The Noble', 'Tight / Control'),
      ],
    );
    final classIdx = await _awaitClassChoice();
    _assignHumanClass(_classOrder[classIdx.clamp(0, _classOrder.length - 1)]);

    view.value = const PokerViewState(
      banner: 'Choose your Court',
      showCourtSelect: true,
      courtOptions: [
        TargetOption('The Jack', 'Skill · aggression'),
        TargetOption('The Queen', 'Intellect · information'),
        TargetOption('The King', 'Wealth · Comp Chips'),
        TargetOption('The Joker', 'Craftiness · wild swaps'),
      ],
    );
    final courtIdx = await _awaitCourtChoice();
    _assignHumanCourt(_courtOrder[courtIdx.clamp(0, _courtOrder.length - 1)]);

    // Deck-building: the human chooses which Power Cards to run; opponents
    // auto-build from their full pool.
    engine.buildDecks();
    final human = engine.players.firstWhere((p) => p.isHuman);
    _publishDeckBuild(human);
    final chosen = await _awaitDeckChoice();
    _humanDeck = chosen;
    engine.buildDeckFor(human, chosen);

    await _cutForDeal();
    _startLoop();
  }

  /// "Cut for the deal": draw a card per player to seat the button, and reveal
  /// it briefly before the first hand.
  Future<void> _cutForDeal() async {
    final draws = engine.drawForButton();
    final dealer = engine.players[engine.buttonSeat];
    _appendLog('Cut for the deal:');
    for (final e in draws.entries) {
      _appendLog('  ${e.key.name}: ${e.value.label}');
    }
    _syncSeats(); // shows the D badge on the dealer
    view.value = PokerViewState(
      banner:
          '🂡 Cut for the deal — ${dealer.name} '
          '${dealer.isHuman ? 'deal' : 'deals'} first',
    );
    await _pause(2400);
  }

  static const Map<String, String> _timingLabel = {
    'setup': 'Setup',
    'round': 'Round',
    'showdown': 'Showdown',
    'counter': 'Counter',
  };

  void _publishDeckBuild(PokerPlayer human) {
    final neutralIds = PowerCards.standard.map((c) => c.templateId).toSet();
    final classIds = ClassCards.forClass(human.personality)
        .map((c) => c.templateId)
        .toSet();
    final pool = <DeckCardInfo>[
      for (final c in engine.deckCandidatesFor(human))
        DeckCardInfo(
          c.templateId,
          c.name,
          c.description,
          neutralIds.contains(c.templateId)
              ? 'Neutral'
              : classIds.contains(c.templateId)
              ? 'Class'
              : 'Court',
          _timingLabel[c.timing.name] ?? c.timing.name,
        ),
    ];
    view.value = PokerViewState(
      banner: 'Build your Power Deck',
      showDeckBuild: true,
      deckPool: pool,
      deckTarget: engine.deckSize,
    );
  }

  Future<List<String>> _awaitDeckChoice() {
    _deckCompleter = Completer<List<String>>();
    return _deckCompleter!.future;
  }

  /// Called by the overlay when the human confirms their deck.
  void submitDeckChoice(List<String> templateIds) {
    final c = _deckCompleter;
    if (c != null && !c.isCompleted) {
      _deckCompleter = null;
      c.complete(templateIds);
    }
  }

  void _assignHumanClass(AiPersonality chosen) {
    final others = _classOrder.where((c) => c != chosen).toList();
    var oi = 0;
    for (final p in engine.players) {
      p.personality = p.isHuman ? chosen : others[oi++ % others.length];
    }
  }

  void _assignHumanCourt(CourtMember chosen) {
    final others = _courtOrder.where((c) => c != chosen).toList();
    var oi = 0;
    for (final p in engine.players) {
      p.court = p.isHuman ? chosen : others[oi++ % others.length];
    }
  }

  Future<int> _awaitClassChoice() {
    _classCompleter = Completer<int>();
    return _classCompleter!.future;
  }

  Future<int> _awaitCourtChoice() {
    _courtCompleter = Completer<int>();
    return _courtCompleter!.future;
  }

  /// Called by the overlay when the human picks a class.
  void submitClassChoice(int index) {
    final c = _classCompleter;
    if (c != null && !c.isCompleted) {
      _classCompleter = null;
      c.complete(index);
    }
  }

  /// Called by the overlay when the human picks a Court.
  void submitCourtChoice(int index) {
    final c = _courtCompleter;
    if (c != null && !c.isCompleted) {
      _courtCompleter = null;
      c.complete(index);
    }
  }

  void _buildEngine() {
    final players = <PokerPlayer>[
      PokerPlayer(
        seat: 0,
        name: humanName,
        stack: config.startingStack,
        isHuman: true,
      ),
    ];
    const personalities = AiPersonality.values;
    for (int i = 0; i < opponentCount; i++) {
      final personality = personalities[i % personalities.length];
      players.add(
        PokerPlayer(
          seat: i + 1,
          name: personality.title,
          stack: config.startingStack,
          personality: personality,
        ),
      );
    }
    engine = PokerGame(
      config: config,
      players: players,
      rng: _rng,
      onLog: _appendLog,
      onPeek: _showPeek,
    );
  }

  void _appendLog(String message) {
    final next = [...log.value, message];
    log.value = next.length > 60 ? next.sublist(next.length - 60) : next;
  }

  /// Show a PEEK reveal for a few seconds, then clear it.
  void _showPeek(String message) {
    peek.value = message;
    final token = ++_peekToken;
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (_peekToken == token) peek.value = '';
    });
  }

  // ── Layout ────────────────────────────────────────────────────────────

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_ready) _layout();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_ready || !config.timedLevels || engine.inSuddenDeath) {
      if (levelClock.value != 0) levelClock.value = 0;
      return;
    }
    _levelElapsed += dt;
    final remaining = (config.levelDurationSeconds - _levelElapsed)
        .ceil()
        .clamp(0, 1 << 30);
    if (remaining != levelClock.value) levelClock.value = remaining;
    if (_levelElapsed >= config.levelDurationSeconds) {
      _levelElapsed = 0;
      engine.advanceLevel(); // ante rises next hand (or Sudden Death begins)
    }
  }

  void _layout() {
    final w = size.x;
    final h = size.y;

    // Table centre — biased slightly above the middle to leave room for the
    // human's seat and action bar at the bottom.
    final cx = w / 2;
    final cy = h * 0.42;

    // Felt oval.
    final fx = (w * 0.46).clamp(120.0, w / 2 - 8);
    final fy = (h * 0.24).clamp(90.0, h * 0.30);
    _table.position = Vector2(cx, cy);
    _table.size = Vector2(fx * 2, fy * 2);

    // Seats arranged around the rim: the human sits at the bottom (90°) and
    // the opponents are distributed evenly around the remaining arc. The
    // human is drawn onto the lower felt (rather than the outer rim) so their
    // hole cards clear the bottom overlays (action bar / power-card panel).
    final ringX = w * 0.37;
    final ringY = fy + 62;
    final t = _seats.length;
    const topReserve = 46.0;
    const bottomReserve = 92.0;

    final ring = SeatRing(
      centreX: cx,
      centreY: cy,
      radiusX: ringX,
      radiusY: ringY,
      viewerDrop: fy * 0.52, // lower-inner felt, above the bottom overlays
    );

    // Counted rather than derived from the seat index, so the layout does not
    // depend on the human being seat 0.
    final opponentTotal = _seats.where((s) => !s.player.isHuman).length;
    var opponentIndex = 0;

    for (int i = 0; i < t; i++) {
      final seat = _seats[i];
      final hw = seat.width / 2;
      final hh = seat.height / 2;
      final slot = seat.player.isHuman
          ? ring.viewer
          : ring.opponent(opponentIndex++, opponentTotal);
      seat.position = Vector2(
        slot.x.clamp(hw + 4, w - hw - 4),
        slot.y.clamp(topReserve + hh, h - bottomReserve - hh),
      );
    }

    // Community row + pot, centred on the felt.
    const gap = 6.0;
    final boardW = _board.length * 46 + (_board.length - 1) * gap;
    final startX = cx - boardW / 2;
    final boardY = cy - 32;
    for (int i = 0; i < _board.length; i++) {
      _board[i].position = Vector2(startX + i * (46 + gap), boardY);
    }
    _potText.position = Vector2(cx, cy + 46);
  }

  // ── Render sync ─────────────────────────────────────────────────────

  void _syncSeats({bool revealAll = false}) {
    for (final s in _seats) {
      s.isDealer = s.player.seat == engine.buttonSeat;
      s.isActing = identical(s.player, engine.actingPlayer);
      s.sync(revealAll: revealAll || this.revealAll);
    }
    _publishHand();
  }

  void _publishHand() {
    final human = engine.players.firstWhere((p) => p.isHuman);
    hand.value = [
      for (final c in human.powerHand)
        PowerOption(c.name, c.description, c.templateId),
    ];
  }

  void toggleDeckView() => showDeck.value = !showDeck.value;
  void toggleReference() => showReference.value = !showReference.value;

  /// A snapshot of the human's Power Deck, grouped by location. Draw-deck order
  /// is hidden (sorted by name) so it can't be used to see upcoming draws.
  List<DeckSection> powerDeckView() {
    final h = engine.players.firstWhere((p) => p.isHuman);
    DeckCardInfo info(PowerCard c) => DeckCardInfo(
      c.templateId,
      c.name,
      c.description,
      '',
      _timingLabel[c.timing.name] ?? c.timing.name,
    );
    List<DeckCardInfo> sorted(List<PowerCard> cs) =>
        cs.map(info).toList()..sort((a, b) => a.name.compareTo(b.name));
    return [
      DeckSection('In Hand', sorted(h.powerHand)),
      DeckSection('Draw Deck', sorted(h.powerDeck)),
      DeckSection('Discard', sorted(h.powerDiscard)),
      DeckSection('One-Shot', sorted(h.oneShotPile)),
    ];
  }

  void _syncBoard() {
    for (int i = 0; i < _board.length; i++) {
      final has = i < engine.community.length;
      _board[i].card = has ? engine.community[i] : null;
      _board[i].faceUp = has;
      _board[i].opacity = has ? 1.0 : 0.18;
    }
    _potText.text = 'Pot  ${engine.pot}';
  }

  // ── Game loop ────────────────────────────────────────────────────────

  void _startLoop() {
    final token = ++_loopToken;
    _runGame(token);
  }

  Future<void> _runGame(int token) async {
    while (token == _loopToken && !engine.isGameOver) {
      handResult.value = null; // clear the previous hand's win/lose flash
      engine.startHand();
      stage.value = engine.inSuddenDeath
          ? '⚔ SUDDEN DEATH  ${engine.suddenDeathHand}/${config.suddenDeathHands}'
          : 'Ante ${engine.ante}';
      _syncSeats();
      _syncBoard();
      _publishThinking();
      await _pause(
        engine.inSuddenDeath && engine.suddenDeathHand == 1 ? 1600 : 500,
      );
      if (token != _loopToken) return;

      await _setupWindow(token);
      if (token != _loopToken) return;

      await _playHand(token);
      if (token != _loopToken) return;

      await _pause(2600); // hold the win/lose flash before the next hand
    }
    if (token == _loopToken) _publishGameOver();
  }

  Future<void> _playHand(int token) async {
    while (token == _loopToken) {
      while (!engine.isBettingRoundComplete) {
        await _takeTurn(token);
        if (token != _loopToken) return;
      }
      if (engine.contenders.length <= 1) break;
      if (engine.street == Street.river) break;
      engine.advanceStreet();
      _syncBoard();
      _syncSeats();
      await _pause(600);
      await _boardCounterWindow(token);
      if (token != _loopToken) return;
    }

    // Run out the remaining board when players are all-in.
    while (engine.contenders.length > 1 && engine.community.length < 5) {
      engine.advanceStreet();
      _syncBoard();
      await _pause(600);
      await _boardCounterWindow(token);
      if (token != _loopToken) return;
    }

    // Showdown window (only when the pot is contested).
    if (engine.contenders.length > 1) {
      await _showdownWindow(token);
      if (token != _loopToken) return;
    }

    final awards = engine.settle();
    final winners = awards.isNotEmpty
        ? awards.first.winners.toSet()
        : <PokerPlayer>{};
    engine.resolveShowdown(winners);
    _syncSeats(revealAll: true);
    _syncBoard();
    _publishResult(awards);
  }

  Future<void> _takeTurn(int token) async {
    final p = engine.actingPlayer;
    if (p == null) return;
    _syncSeats();

    if (p.isHuman) {
      await _humanItemWindow(token); // play held Item cards (like Round cards)
      if (token != _loopToken) return;
      await _humanPowerWindow(PowerTiming.round, token);
    } else {
      _publishThinking();
      await _pause(500 + _rng.nextInt(400));
      if (token != _loopToken) return;
      for (final item in _ai.itemPlays(engine, p)) {
        if (token != _loopToken || p.folded) return;
        engine.playItem(p, item, mode: _ai.itemMode(engine, p, item));
        _syncSeats();
        await _pause(500);
      }
      await _playAiPower(_ai.roundPlays(engine, p), p, token);
    }
    if (token != _loopToken) return;

    // A Power Card (Cash Out / Re-Gain Composure) may have folded the player.
    PokerAction action;
    if (p.folded) {
      action = const PokerAction.fold();
    } else if (p.isHuman) {
      action = await _awaitHumanAction(p);
    } else {
      action = _ai.decide(engine, p);
    }
    if (token != _loopToken) return;

    engine.applyAction(action);
    _syncSeats();
    _syncBoard();
    await _pause(350);
  }

  // ── Power Card windows ──────────────────────────────────────────────

  Future<void> _setupWindow(int token) async {
    for (final p in engine.playersFromButton()) {
      if (token != _loopToken) return;
      if (p.isHuman) {
        await _humanChipSell(token); // Midas Crown: sell chips at Setup
        if (token != _loopToken) return;
        await _humanPowerWindow(PowerTiming.setup, token);
      } else {
        while (_ai.sellsChip(engine, p)) {
          engine.sellChip(p);
          _syncSeats();
          await _pause(300);
          if (token != _loopToken) return;
        }
        await _playAiPower(_ai.setupPlays(engine, p), p, token);
      }
    }
    _publishThinking();
  }

  /// Offer the human repeated chip sales while a Midas Crown is in play.
  Future<void> _humanChipSell(int token) async {
    final human = engine.players.firstWhere((p) => p.isHuman);
    while (token == _loopToken && engine.canSellChip(human)) {
      view.value = PokerViewState(
        pot: engine.pot,
        showChipSell: true,
        compChips: human.compChips,
        chipSellValue: engine.chipSellValue,
      );
      _chipSellCompleter = Completer<bool>();
      final sell = await _chipSellCompleter!.future;
      if (token != _loopToken) return;
      if (!sell) break;
      engine.sellChip(human);
      _syncSeats();
      await _pause(250);
    }
    _publishThinking();
  }

  /// Called by the overlay: true = sell a Comp Chip, false = done.
  void submitChipSell(bool sell) {
    final c = _chipSellCompleter;
    if (c != null && !c.isCompleted) {
      _chipSellCompleter = null;
      c.complete(sell);
    }
  }

  /// Offer the human their held Item cards to play (like Round cards).
  Future<void> _humanItemWindow(int token) async {
    final human = engine.players.firstWhere((p) => p.isHuman);
    while (token == _loopToken && human.inHand) {
      final items = engine.playableItems(human);
      if (items.isEmpty) break;
      view.value = PokerViewState(
        banner: 'Play a held Item?',
        pot: engine.pot,
        showItemPlay: true,
        itemOptions: [
          for (final it in items) PowerOption(it.name, it.description, it.id),
        ],
      );
      _itemCompleter = Completer<int>();
      final choice = await _itemCompleter!.future;
      if (token != _loopToken) return;
      if (choice < 0 || choice >= items.length) break;
      final item = items[choice];
      final modes = engine.itemModes(item);
      var mode = 0;
      if (modes.isNotEmpty) {
        mode = await _humanItemMode(item.name, modes);
        if (token != _loopToken) return;
        if (mode < 0) continue; // cancelled → back to item list
      }
      // Follow-up card pick (e.g. which card to discard / mulligan).
      int? pick;
      final needsPick = engine.itemPick(human, item, mode);
      if (needsPick != null) {
        pick = await _humanItemMode(needsPick.prompt, [
          ...needsPick.options,
          if (needsPick.optional) 'None',
        ]);
        if (token != _loopToken) return;
        // The trailing "None" option (optional picks) maps to a decline (-1).
        if (needsPick.optional && pick == needsPick.options.length) pick = -1;
        if (!needsPick.optional && pick < 0) continue; // cancelled
      }
      engine.playItem(human, item, mode: mode, pick: pick);
      _syncSeats();
      _syncBoard();
      await _pause(300);
    }
    _publishThinking();
  }

  Future<int> _humanItemMode(String name, List<String> modes) async {
    view.value = PokerViewState(
      pot: engine.pot,
      showItemMode: true,
      itemModeTitle: '$name — choose',
      itemModeOptions: modes,
    );
    _itemModeCompleter = Completer<int>();
    final m = await _itemModeCompleter!.future;
    _publishThinking();
    return m;
  }

  /// Called by the overlay: play the held item at [index], or < 0 to skip.
  void submitItemChoice(int index) {
    final c = _itemCompleter;
    if (c != null && !c.isCompleted) {
      _itemCompleter = null;
      c.complete(index);
    }
  }

  /// Called by the overlay: choose item mode [index], or < 0 to cancel.
  void submitItemMode(int index) {
    final c = _itemModeCompleter;
    if (c != null && !c.isCompleted) {
      _itemModeCompleter = null;
      c.complete(index);
    }
  }

  Future<void> _playAiPower(
    List<PowerCard> plays,
    PokerPlayer p,
    int token,
  ) async {
    for (final card in plays) {
      if (token != _loopToken || p.folded) return;
      await _playPowerCardWithCounters(p, card, token);
      await _pause(500);
    }
  }

  // ── Showdown + board-counter windows ────────────────────────────────

  Future<void> _showdownWindow(int token) async {
    for (final p in engine.playersFromButton()) {
      if (token != _loopToken) return;
      if (!p.inHand) continue;
      if (p.isHuman) {
        await _humanShowdownWindow(token);
      } else {
        for (final card in _ai.showdownPlays(engine, p)) {
          if (token != _loopToken) return;
          engine.proposeShowdown(p, card);
          _syncSeats();
          await _pause(550);
        }
      }
    }
    _publishThinking();
  }

  Future<void> _humanShowdownWindow(int token) async {
    final human = engine.players.firstWhere((p) => p.isHuman);
    while (token == _loopToken && human.inHand) {
      final options = engine.playableShowdown(human);
      if (options.isEmpty) break;
      view.value = PokerViewState(
        banner: 'Showdown — play a card?',
        pot: engine.pot,
        showPower: true,
        powerTitle: 'Showdown',
        powerDismissLabel: 'Done',
        powerOptions: [
          for (final c in options)
            PowerOption(c.name, c.description, c.templateId),
        ],
      );
      final choice = await _awaitPowerChoice();
      if (token != _loopToken) return;
      if (choice < 0 || choice >= options.length) break;
      engine.proposeShowdown(human, options[choice]);
      _syncSeats();
      await _pause(300);
    }
  }

  Future<void> _boardCounterWindow(int token) async {
    int guard = 0;
    while (token == _loopToken && guard++ < 12) {
      final responders = engine.boardCounterResponders();
      if (responders.isEmpty) break;
      bool responded = false;
      for (final r in responders) {
        if (token != _loopToken) return;
        final card = r.isHuman
            ? await _humanPickBoardCounter(token)
            : _ai.pickBoardCounter(engine, r);
        if (token != _loopToken) return;
        if (card != null) {
          engine.playBoardCounter(r, card);
          _syncSeats();
          _syncBoard();
          await _pause(750);
          responded = true;
          break;
        }
      }
      if (!responded) break;
    }
    _publishThinking();
  }

  Future<PowerCard?> _humanPickBoardCounter(int token) async {
    final human = engine.players.firstWhere((p) => p.isHuman);
    final options = engine.playableJustDealt(human);
    if (options.isEmpty) return null;
    view.value = PokerViewState(
      banner: 'A board card was just dealt — respond?',
      pot: engine.pot,
      showPower: true,
      powerTitle: 'Just Dealt',
      powerDismissLabel: 'Pass',
      powerOptions: [
        for (final c in options)
          PowerOption(c.name, c.description, c.templateId),
      ],
    );
    final choice = await _awaitPowerChoice();
    _publishThinking();
    if (choice < 0 || choice >= options.length) return null;
    return options[choice];
  }

  Future<void> _humanPowerWindow(PowerTiming timing, int token) async {
    final human = engine.players.firstWhere((p) => p.isHuman);
    while (token == _loopToken && human.inHand) {
      final options = engine.playablePower(human, timing);
      if (options.isEmpty) break;
      _publishPowerPrompt(timing, options);
      final choice = await _awaitPowerChoice();
      if (token != _loopToken) return;
      if (choice < 0 || choice >= options.length) break;
      await _playPowerCardWithCounters(human, options[choice], token);
      if (token != _loopToken) return;
    }
  }

  /// Play [card]: pick a target if needed, propose it, run the counter window
  /// (other players may respond, forming a LIFO chain), then resolve.
  Future<void> _playPowerCardWithCounters(
    PokerPlayer actor,
    PowerCard card,
    int token,
  ) async {
    PokerPlayer? target;
    if (engine.cardNeedsPlayerTarget(card)) {
      target = actor.isHuman
          ? await _humanPickTarget(card)
          : _ai.pickTarget(engine, actor, card);
      if (token != _loopToken) return;
    }

    // Comp Chip: offer to pay this card's cost with a chip instead of coins.
    if (engine.cardHasPayCost(card) && actor.compChips > 0) {
      final useChip = actor.isHuman
          ? await _humanPayChoice(card)
          : _ai.usesChipFor(engine, actor, card);
      if (token != _loopToken) return;
      engine.payWithChipFor = useChip ? actor : null;
    } else {
      engine.payWithChipFor = null;
    }

    engine.proposePower(actor, card, targetPlayer: target);
    _syncSeats();
    _syncBoard();
    await _pause(350);

    await _counterWindow(token);

    engine.resolveChain();
    engine.payWithChipFor = null;
    _syncSeats();
    _syncBoard();
    if (token != _loopToken) return;
    await _pause(300);
  }

  /// Ask the human whether to spend a Comp Chip for [card]'s pay cost.
  Future<bool> _humanPayChoice(PowerCard card) async {
    final human = engine.players.firstWhere((p) => p.isHuman);
    view.value = PokerViewState(
      pot: engine.pot,
      showPayChoice: true,
      payCardName: card.name,
      payCost: engine.payCostOf(card),
      compChips: human.compChips,
    );
    _payCompleter = Completer<bool>();
    final useChip = await _payCompleter!.future;
    _publishThinking();
    return useChip;
  }

  /// Called by the overlay: true = spend a Comp Chip, false = pay coins.
  void submitPayChoice(bool useChip) {
    final c = _payCompleter;
    if (c != null && !c.isCompleted) {
      _payCompleter = null;
      c.complete(useChip);
    }
  }

  /// Offer eligible players the chance to respond to the top of the chain with
  /// a Counter, repeating until a full pass yields no response.
  Future<void> _counterWindow(int token) async {
    int guard = 0;
    while (token == _loopToken && guard++ < 40) {
      final top = engine.chainTop;
      if (top == null) break;
      final responders = engine.counterRespondersFor(top);
      if (responders.isEmpty) break;

      bool responded = false;
      for (final r in responders) {
        if (token != _loopToken) return;
        final counter = r.isHuman
            ? await _humanPickCounter(top)
            : _ai.pickCounter(engine, r, top);
        if (token != _loopToken) return;
        if (counter != null) {
          engine.proposePower(r, counter, targetEntry: top);
          _syncSeats();
          await _pause(750);
          responded = true;
          break; // re-offer against the new top
        }
      }
      if (!responded) break;
    }
    _publishThinking();
  }

  Future<int> _awaitPowerChoice() {
    _powerCompleter = Completer<int>();
    return _powerCompleter!.future;
  }

  /// Called by the overlay: play the option at [index], or [index] < 0 to
  /// close the power / counter prompt.
  void submitPowerChoice(int index) {
    final c = _powerCompleter;
    if (c != null && !c.isCompleted) {
      _powerCompleter = null;
      c.complete(index);
    }
  }

  Future<PowerCard?> _humanPickCounter(ChainEntry top) async {
    final human = engine.players.firstWhere((p) => p.isHuman);
    final options = engine.playableCounters(human, top);
    if (options.isEmpty) return null;
    view.value = PokerViewState(
      banner: 'Respond to ${top.player.name}\'s ${top.card.name}?',
      pot: engine.pot,
      showPower: true,
      powerTitle: 'Counter — ${top.card.name}',
      powerDismissLabel: 'Pass',
      powerOptions: [
        for (final c in options)
          PowerOption(c.name, c.description, c.templateId),
      ],
    );
    final choice = await _awaitPowerChoice();
    _publishThinking();
    if (choice < 0 || choice >= options.length) return null;
    return options[choice];
  }

  Future<PokerPlayer?> _humanPickTarget(PowerCard card) async {
    final human = engine.players.firstWhere((p) => p.isHuman);
    final targets = engine.targetsFor(human, card);
    if (targets.isEmpty) return null;
    view.value = PokerViewState(
      banner: '${card.name} — choose a target',
      pot: engine.pot,
      showTarget: true,
      targetTitle: '${card.name} — choose an opponent',
      targetOptions: [
        for (final t in targets)
          TargetOption(
            t.name,
            '${t.stack} chips${t.tilted ? '  ·  Tilted' : ''}',
          ),
      ],
    );
    final idx = await _awaitTargetChoice();
    _publishThinking();
    if (idx < 0 || idx >= targets.length) return targets.first;
    return targets[idx];
  }

  Future<int> _awaitTargetChoice() {
    _targetCompleter = Completer<int>();
    return _targetCompleter!.future;
  }

  /// Called by the overlay when the human taps a target.
  void submitTargetChoice(int index) {
    final c = _targetCompleter;
    if (c != null && !c.isCompleted) {
      _targetCompleter = null;
      c.complete(index);
    }
  }

  // ── Human input ─────────────────────────────────────────────────────

  Future<PokerAction> _awaitHumanAction(PokerPlayer p) {
    _humanCompleter = Completer<PokerAction>();
    _publishActions(p);
    return _humanCompleter!.future;
  }

  /// Called by the Flutter overlay when the player picks an action.
  void submitHumanAction(PokerAction action) {
    final c = _humanCompleter;
    if (c != null && !c.isCompleted) {
      _humanCompleter = null;
      _publishThinking();
      c.complete(action);
    }
  }

  /// Restart the whole game with fresh stacks, keeping the chosen classes.
  void restart() {
    engine.resetGame();
    engine.buildDecks(); // rebuild decks (personalities/courts persist)
    if (_humanDeck != null) {
      final human = engine.players.firstWhere((p) => p.isHuman);
      engine.buildDeckFor(human, _humanDeck!); // reapply the chosen deck
    }
    log.value = const [];
    handResult.value = null;
    _levelElapsed = 0;
    levelClock.value = 0;
    _humanCompleter = null;
    _powerCompleter = null;
    _targetCompleter = null;
    _cutForDeal().then((_) => _startLoop());
  }

  // ── View publishing ─────────────────────────────────────────────────

  void _publishThinking() {
    final acting = engine.actingPlayer;
    final banner = acting == null
        ? ''
        : (acting.isHuman ? 'Your move' : '${acting.name} is thinking...');
    view.value = PokerViewState(banner: banner, pot: engine.pot);
  }

  void _publishPowerPrompt(PowerTiming timing, List<PowerCard> options) {
    view.value = PokerViewState(
      banner: '${timing.label} — play a Power Card?',
      pot: engine.pot,
      showPower: true,
      powerTitle: '${timing.label} Power Cards',
      powerOptions: [
        for (final c in options)
          PowerOption(c.name, c.description, c.templateId),
      ],
    );
  }

  void _publishActions(PokerPlayer p) {
    final callAmt = engine.callAmount(p);
    view.value = PokerViewState(
      banner: 'Your move',
      pot: engine.pot,
      showActions: true,
      canCheck: callAmt == 0,
      canCall: callAmt > 0,
      callAmount: callAmt,
      canRaise: engine.canRaise(p),
      minRaiseTo: engine.minRaiseTo(p),
      maxRaiseTo: engine.maxRaiseTo(p),
      humanRoundBet: p.roundBet,
    );
  }

  void _publishResult(List<PotAward> awards) {
    final text = awards
        .map(
          (a) => '${a.winners.map((w) => w.name).join(', ')} win ${a.amount}',
        )
        .join('   ·   ');
    view.value = PokerViewState(banner: text, pot: 0);

    // Prominent win/lose flash — only for hands the human contested to the end
    // (folding early shows nothing).
    final human = engine.players.firstWhere((p) => p.isHuman);
    if (!human.inHand) {
      handResult.value = null;
      return;
    }
    final main = awards.isNotEmpty ? awards.first : null;
    final humanWon = main != null && main.winners.contains(human);
    int humanTotalWon = 0;
    for (final a in awards) {
      if (a.winners.contains(human)) {
        humanTotalWon += a.amount ~/ a.winners.length;
      }
    }
    String detail;
    if (humanWon) {
      final hand = human.showdownHand?.toString();
      detail =
          'You won $humanTotalWon'
          '${hand != null ? ' with a $hand' : ''}';
    } else if (main != null) {
      detail =
          '${main.winners.map((w) => w.name).join(', ')} '
          'won the ${main.amount} pot';
    } else {
      detail = '';
    }
    handResult.value = HandResult(won: humanWon, folded: false, detail: detail);
  }

  void _publishGameOver() {
    final human = engine.players.firstWhere((p) => p.isHuman);
    final winner = engine.gameWinner;
    final won = winner != null && winner.isHuman;
    String text;
    if (won) {
      text = engine.inSuddenDeath
          ? 'Victory! You survived Sudden Death with the biggest stack.'
          : 'Victory! You have taken all the coins on the table.';
    } else if (human.eliminated) {
      text = 'Defeated. Your coffers are empty.';
    } else {
      text =
          '${winner?.name ?? 'A rival'} wins Sudden Death on the chip count.';
    }
    view.value = PokerViewState(gameOver: true, won: won, resultText: text);
  }

  Future<void> _pause(int ms) => Future.delayed(Duration(milliseconds: ms));
}
