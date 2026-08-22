import 'power_cards.dart';

/// The four Court members a player may add to their Power Deck.
enum CourtMember { jack, queen, king, joker }

extension CourtMemberLabel on CourtMember {
  String get title {
    switch (this) {
      case CourtMember.jack:
        return 'The Jack';
      case CourtMember.queen:
        return 'The Queen';
      case CourtMember.king:
        return 'The King';
      case CourtMember.joker:
        return 'The Joker';
    }
  }

  String get trait {
    switch (this) {
      case CourtMember.jack:
        return 'Skill · aggression';
      case CourtMember.queen:
        return 'Intellect · information';
      case CourtMember.king:
        return 'Wealth · Comp Chips';
      case CourtMember.joker:
        return 'Craftiness · wild swaps';
    }
  }
}

/// The 36 Court Power Cards (9 per member: 5 ability cards + 4 character/token
/// cards). As with the Class cards, effects that rely on unbuilt subsystems
/// (PEEK reveals, persistent Token triggers, betting-integrated plays, item
/// economy) are faithful *approximations* from the engine's primitives; the
/// descriptions reflect what the implementation actually does.
class CourtCards {
  static const _jack = [
    PowerCard(
      templateId: 'jack_double_attack',
      name: 'Double Attack',
      description: 'Return up to 2 Round cards from your discard to your hand.',
      timing: PowerTiming.round,
      flex: true,
      oneShot: true,
    ),
    PowerCard(
      templateId: 'jack_tactical_retreat',
      name: 'Tactical Retreat',
      description: 'Fold. Heating Up. Search for a Table-Talk card.',
      timing: PowerTiming.round,
      tableTalk: true,
    ),
    PowerCard(
      templateId: 'jack_royal_skill',
      name: 'Royal Skill',
      description: 'Duelist: gain an extra hole card.',
      timing: PowerTiming.setup,
    ),
    PowerCard(
      templateId: 'jack_adaptive_playstyle',
      name: 'Adaptive Playstyle',
      description: 'Play a Power Card from an opponent\'s discard (draw 1).',
      timing: PowerTiming.round,
      flex: true,
    ),
    PowerCard(
      templateId: 'jack_hit_the_flop',
      name: 'Hit the Flop',
      description: 'Destroy a board card. Duelist: mulligan your hole cards.',
      timing: PowerTiming.counter,
      fire: true,
    ),
    PowerCard(
      templateId: 'jack_bachelor',
      name: 'Eligible Bachelor',
      description: 'Search for a Table-Talk card. You\'re Heating Up!',
      timing: PowerTiming.round,
      tableTalk: true,
    ),
    PowerCard(
      templateId: 'jack_guerrilla',
      name: 'Guerrilla Tactics',
      description: 'Steal 10 coins from the chip leader (30 if Duelist).',
      timing: PowerTiming.counter,
      tableTalk: true,
    ),
    PowerCard(
      templateId: 'jack_mithril',
      name: 'Mithril Armaments',
      description: 'Draw 1 Power Card (Token).',
      timing: PowerTiming.round,
    ),
    PowerCard(
      templateId: 'jack_press',
      name: 'Press the Advantage',
      description: 'You\'re Heating Up! (Token)',
      timing: PowerTiming.setup,
    ),
  ];

  static const _queen = [
    PowerCard(
      templateId: 'queen_spot_the_tell',
      name: 'Spot the Tell',
      description: 'The chip leader Cools Off.',
      timing: PowerTiming.round,
    ),
    PowerCard(
      templateId: 'queen_brilliant_strategist',
      name: 'Brilliant Strategist',
      description: 'Draw 1 Power Card (arrange your fate).',
      timing: PowerTiming.round,
    ),
    PowerCard(
      templateId: 'queen_sick_laydown',
      name: 'Sick Laydown',
      description: 'Fold. You\'re Heating Up! Draw 1.',
      timing: PowerTiming.round,
    ),
    PowerCard(
      templateId: 'queen_royal_charm',
      name: 'Royal Charm',
      description: 'Cancel a non-Fire card. You\'re Heating Up!',
      timing: PowerTiming.counter,
      oneShot: true,
    ),
    PowerCard(
      templateId: 'queen_table_flirt',
      name: 'Table Flirt',
      description: 'You\'re Heating Up and draw 1. Other opponents Cool Off.',
      timing: PowerTiming.counter,
      tableTalk: true,
      flex: true,
    ),
    PowerCard(
      templateId: 'queen_adored',
      name: 'Adored by All',
      description: 'Gain a hole card (Token).',
      timing: PowerTiming.setup,
    ),
    PowerCard(
      templateId: 'queen_favorite',
      name: 'Dealer\'s Favorite',
      description: 'Mulligan a hole card (Token).',
      timing: PowerTiming.setup,
    ),
    PowerCard(
      templateId: 'queen_analytical',
      name: 'Analytical Fighter',
      description: 'Draw 1 Power Card (Token).',
      timing: PowerTiming.setup,
    ),
    PowerCard(
      templateId: 'queen_ring',
      name: 'Future Sight Ring',
      description: 'Hot Streak: draw 1 Power Card (Token).',
      timing: PowerTiming.setup,
      hotStreak: true,
    ),
  ];

  static const _king = [
    PowerCard(
      templateId: 'king_iou',
      name: 'I.O.U.',
      description: 'Gain 10 coins (paid in Comp Chips).',
      timing: PowerTiming.round,
      fire: true,
    ),
    PowerCard(
      templateId: 'king_tip_the_dealer',
      name: 'Tip the Dealer',
      description: 'Pay 10 coins; gain 2 hole cards. Hot Streak: +1 Comp Chip.',
      timing: PowerTiming.round,
      hotStreak: true,
    ),
    PowerCard(
      templateId: 'king_royal_rebuy',
      name: 'Royal Re-Buy',
      description: 'Gain 100 coins and draw 3 (re-buy back in).',
      timing: PowerTiming.counter,
      oneShot: true,
      flex: true,
    ),
    PowerCard(
      templateId: 'king_vip',
      name: 'V.I.P. Treatment',
      description: 'Add a Comp Chip + 10 coins; gain a hole card; draw 1.',
      timing: PowerTiming.setup,
    ),
    PowerCard(
      templateId: 'king_bomb_pot',
      name: 'Bomb Pot',
      description: 'Add 20 coins to the pot from the bank. Draw 1.',
      timing: PowerTiming.setup,
    ),
    PowerCard(
      templateId: 'king_midas',
      name: 'Midas Crown',
      description: 'Gain 2 Comp Chips (Token).',
      timing: PowerTiming.setup,
    ),
    PowerCard(
      templateId: 'king_gold_for_gifts',
      name: 'Gold For Gifts',
      description: 'Gain 10 coins.',
      timing: PowerTiming.counter,
    ),
    PowerCard(
      templateId: 'king_match_might',
      name: 'Match Their Might',
      description: 'Draw 1 Power Card. +1 Comp Chip.',
      timing: PowerTiming.counter,
      flex: true,
    ),
    PowerCard(
      templateId: 'king_stimulus',
      name: 'Stimulus Package',
      description: 'Every player gains a Comp Chip and 10 coins.',
      timing: PowerTiming.counter,
      tableTalk: true,
    ),
  ];

  static const _joker = [
    PowerCard(
      templateId: 'joker_highlander',
      name: 'Highlander Poker',
      description: 'Gain a hole card. Draw 1.',
      timing: PowerTiming.setup,
    ),
    PowerCard(
      templateId: 'joker_split_personality',
      name: 'Split Personality',
      description: 'Tilted: Recover + gain a Tilted card. Hot: gain a Fire card.',
      timing: PowerTiming.round,
      flex: true,
      playableWhileTilted: true,
    ),
    PowerCard(
      templateId: 'joker_quick_change',
      name: 'Quick Change Artist',
      description: 'Swap one of your hole cards with a board card.',
      timing: PowerTiming.round,
      fire: true,
    ),
    PowerCard(
      templateId: 'joker_royal_wild',
      name: 'Royal Wild',
      description: 'Turn a board card into a Joker Wild.',
      timing: PowerTiming.round,
      oneShot: true,
    ),
    PowerCard(
      templateId: 'joker_fire_juggler',
      name: 'Fire Juggler',
      description: 'You\'re Heating Up! The chip leader Cools Off.',
      timing: PowerTiming.counter,
      tableTalk: true,
    ),
    PowerCard(
      templateId: 'joker_game_of_chance',
      name: 'Game of Chance',
      description: 'Roll the dice: often gain a hole card and draw.',
      timing: PowerTiming.round,
    ),
    PowerCard(
      templateId: 'joker_drunken_boxing',
      name: 'Drunken Boxing',
      description: 'Tilted: mulligan a hole card and dig a Power Card (Token).',
      timing: PowerTiming.setup,
      playableWhileTilted: true,
    ),
    PowerCard(
      templateId: 'joker_life_of_party',
      name: 'Life of the Party',
      description: 'Cancel a Table-Talk card.',
      timing: PowerTiming.counter,
      tableTalk: true,
    ),
    PowerCard(
      templateId: 'joker_trading_up',
      name: 'Trading Up',
      description: 'Gain a hole card (Token).',
      timing: PowerTiming.setup,
    ),
  ];

  static const Map<CourtMember, List<PowerCard>> byMember = {
    CourtMember.jack: _jack,
    CourtMember.queen: _queen,
    CourtMember.king: _king,
    CourtMember.joker: _joker,
  };

  static List<PowerCard> forMember(CourtMember? m) =>
      m == null ? const [] : (byMember[m] ?? const []);

  /// Court counters that cancel their target (handled in the chain).
  static const cancelCounters = {'queen_royal_charm', 'joker_life_of_party'};
}
