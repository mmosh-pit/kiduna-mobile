import 'dart:math';

/// When during a hand a Power Card may be played.
enum PowerTiming { setup, round, showdown, counter }

extension PowerTimingLabel on PowerTiming {
  String get label {
    switch (this) {
      case PowerTiming.setup:
        return 'Setup';
      case PowerTiming.round:
        return 'Round';
      case PowerTiming.showdown:
        return 'Showdown';
      case PowerTiming.counter:
        return 'Counter';
    }
  }
}

/// A Power Card. Instances are shared const templates; a player's deck/hand
/// holds references to them (duplicates are interchangeable).
class PowerCard {
  final String templateId;
  final String name;
  final String description;
  final PowerTiming timing;

  // ── Keywords / abilities ───────────────────────────────────────────────
  final bool fire; // playable only while Heating Up
  final bool flex; // playable even while Tilted
  final bool playableWhileTilted; // a "Tilted card" (diagonal design)
  final bool hotStreak; // extra effect while Heating Up
  final bool oneShot; // goes to the One Shot pile when played
  final bool justDealt; // Counter that responds to a just-dealt board card
  final bool tableTalk; // may only be played after folding
  final bool promo; // not part of the standard deck

  const PowerCard({
    required this.templateId,
    required this.name,
    required this.description,
    required this.timing,
    this.fire = false,
    this.flex = false,
    this.playableWhileTilted = false,
    this.hotStreak = false,
    this.oneShot = false,
    this.justDealt = false,
    this.tableTalk = false,
    this.promo = false,
  });

  List<String> get keywords => [
        if (fire) 'Fire',
        if (flex) 'Flex',
        if (playableWhileTilted) 'Tilted',
        if (hotStreak) 'Hot Streak',
        if (oneShot) 'One Shot',
        if (justDealt) 'Just Dealt',
        if (tableTalk) 'Table Talk',
      ];
}

/// The full official Neutral Power Card set (21 cards). Effects are faithful to
/// the printed cards where the engine supports them; a few are approximated
/// (see the engine's effect resolver comments) and one promo ("Know When to
/// Hold") is defined but kept out of the standard deck.
class PowerCards {
  // ── Setup ──────────────────────────────────────────────────────────────
  static const shoppingSpree = PowerCard(
    templateId: 'shopping_spree',
    name: 'Shopping Spree',
    description: 'Pay 10 coins: gain a hole card and draw a Power Card.',
    timing: PowerTiming.setup,
    oneShot: true,
  );
  static const runTheTable = PowerCard(
    templateId: 'run_the_table',
    name: 'Run the Table',
    description: 'Fire: you are Heating Up and gain a hole card.',
    timing: PowerTiming.setup,
    oneShot: true,
    fire: true,
  );
  static const addOn = PowerCard(
    templateId: 'add_on',
    name: 'Add On',
    description: 'Add 20 coins to your stack. Hot Streak: add 30 instead.',
    timing: PowerTiming.setup,
    hotStreak: true,
  );

  // ── Round ──────────────────────────────────────────────────────────────
  static const trashTalker = PowerCard(
    templateId: 'trash_talker',
    name: 'Trash Talker',
    description: 'Tilt an opponent who isn\'t Heating Up.',
    timing: PowerTiming.round,
    tableTalk: true,
    flex: true, // changelog 7.21.2026: added FLEX (playable while Tilted)
  );
  static const cashOut = PowerCard(
    templateId: 'cash_out',
    name: 'Cash Out',
    description: 'Fold. Gain 10 coins. Hot Streak: draw a Power Card.',
    timing: PowerTiming.round,
    hotStreak: true,
  );
  static const snapCall = PowerCard(
    templateId: 'snap_call',
    name: 'Snap Call',
    description:
        'Tilt the last player to bet/raise (Cool Off if they were hot). '
        'Hot Streak: draw 1.',
    timing: PowerTiming.round,
    hotStreak: true,
  );
  static const rockSolid = PowerCard(
    templateId: 'rock_solid',
    name: 'Rock Solid',
    description: 'If Heating Up: Cool Off, draw 2. If Tilted: Recover, draw 1.',
    timing: PowerTiming.round,
    flex: true,
  );
  static const burstOfConfidence = PowerCard(
    templateId: 'burst_of_confidence',
    name: 'Burst of Confidence',
    description: 'Draw 1 Power Card. You\'re Heating Up!',
    timing: PowerTiming.round,
  );
  static const knowWhenToHold = PowerCard(
    templateId: 'know_when_to_hold',
    name: 'Know When to Hold',
    description: 'Go all-in. You\'re Heating Up. Tilt all opponents.',
    timing: PowerTiming.round,
    oneShot: true,
    flex: true,
    promo: true,
  );
  static const regainComposure = PowerCard(
    templateId: 'regain_composure',
    name: 'Re-Gain Composure',
    description: 'Fold. Recover. Return a Setup from your discard to hand.',
    timing: PowerTiming.round,
    playableWhileTilted: true,
  );

  // ── Showdown ─────────────────────────────────────────────────────────
  static const rideTheWave = PowerCard(
    templateId: 'ride_the_wave',
    name: 'Ride the Wave',
    description:
        'Draw 1. Win: gain a Fire card + Heating Up. Lose: gain a Tilted '
        'card + Tilted.',
    timing: PowerTiming.showdown,
    oneShot: true,
    flex: true,
    fire: true,
  );
  static const poorWinner = PowerCard(
    templateId: 'poor_winner',
    name: 'Poor Winner',
    description:
        'Win: if short stack, +20 coins and Tilt all opponents. Lose: '
        'Tilted, draw 1.',
    timing: PowerTiming.showdown,
  );
  static const pocketProtector = PowerCard(
    templateId: 'pocket_protector',
    name: 'Pocket Protector',
    description:
        'Win: if you hold a pair/trips, draw 1. Lose: if you hold a '
        'pair/trips, +30 coins.',
    timing: PowerTiming.showdown,
  );
  static const topUp = PowerCard(
    templateId: 'top_up',
    name: 'Top Up',
    description: 'Win: draw 1, Heating Up. Lose: +30 coins, Recover.',
    timing: PowerTiming.showdown,
    flex: true,
  );
  static const oneToughCookie = PowerCard(
    templateId: 'one_tough_cookie',
    name: 'One Tough Cookie',
    description:
        'Gain a Fire card. Win: Heating Up. Lose: return a card from discard.',
    timing: PowerTiming.showdown,
    flex: true,
    fire: true,
  );

  // ── Counter ────────────────────────────────────────────────────────────
  static const showMercy = PowerCard(
    templateId: 'show_mercy',
    name: 'Show Mercy',
    description: 'Pay a folded opponent 10 coins; they Recover. Draw 1.',
    timing: PowerTiming.counter,
    tableTalk: true,
  );
  static const riverRat = PowerCard(
    templateId: 'river_rat',
    name: 'River Rat',
    description: 'Re-deal the card that was just dealt. Draw 1.',
    timing: PowerTiming.counter,
    justDealt: true,
  );
  static const monkey = PowerCard(
    templateId: 'monkey',
    name: 'Monkey!',
    description: 'Re-deal the just-dealt board card until it is a face or Wild.',
    timing: PowerTiming.counter,
    justDealt: true,
  );
  static const counterplay = PowerCard(
    templateId: 'counterplay',
    name: 'Counterplay',
    description: 'Return a Counter or Round from your discard to hand. Recover.',
    timing: PowerTiming.counter,
    oneShot: true,
    flex: true,
  );
  static const runGood = PowerCard(
    templateId: 'run_good',
    name: 'Run Good',
    description: 'Re-deal the just-dealt board card (up to twice).',
    timing: PowerTiming.counter,
    justDealt: true,
    fire: true,
  );
  static const feignWeakness = PowerCard(
    templateId: 'feign_weakness',
    name: 'Feign Weakness',
    description: 'Cancel a non-Fire Power Card. Recover. Draw 1.',
    timing: PowerTiming.counter,
    playableWhileTilted: true,
  );

  /// All 21 Neutral cards (including the promo).
  static const all = [
    shoppingSpree, runTheTable, addOn, // setup
    trashTalker, cashOut, snapCall, rockSolid, burstOfConfidence,
    knowWhenToHold, regainComposure, // round
    rideTheWave, poorWinner, pocketProtector, topUp, oneToughCookie, // showdown
    showMercy, riverRat, monkey, counterplay, runGood, feignWeakness, // counter
  ];

  /// Cards used to build a starter deck (excludes promos).
  static List<PowerCard> get standard =>
      all.where((c) => !c.promo).toList();

  /// A shuffled starter deck: two copies of each standard Neutral.
  static List<PowerCard> starterDeck(Random rng) {
    final deck = <PowerCard>[
      for (final t in standard) ...[t, t],
    ];
    deck.shuffle(rng);
    return deck;
  }
}
