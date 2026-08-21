import 'poker_engine.dart' show AiPersonality;
import 'power_cards.dart';

/// The four playable classes (mapped onto [AiPersonality]).
typedef PokerClass = AiPersonality;

/// The 48 Class Power Cards (12 per class).
///
/// NOTE: several printed effects rely on subsystems not yet built (a full
/// Item/Token economy, dice-driven betting rounds, double boards, bidding
/// wars, betting-integrated plays). Those are implemented here as faithful
/// *approximations* built from the engine's primitives (coins, status, draws,
/// hole-card and board manipulation, cancels, steals). The card descriptions
/// below reflect what the implementation actually does.
class ClassCards {
  // ── Rogue (tight / aggressive) ─────────────────────────────────────────
  static const _rogue = [
    PowerCard(
      templateId: 'rogue_dramatic_reversal',
      name: 'Dramatic Reversal',
      description: 'Search your deck for a Fire card. You\'re Heating Up!',
      timing: PowerTiming.round,
      oneShot: true,
      playableWhileTilted: true,
    ),
    PowerCard(
      templateId: 'rogue_back_alley_deal',
      name: 'Back Alley Deal',
      description: 'Give an opponent a hole card; steal 10 coins (15 if Tilted).',
      timing: PowerTiming.round,
      tableTalk: true,
    ),
    PowerCard(
      templateId: 'rogue_twist_of_fate',
      name: 'Twist of Fate',
      description:
          'Roll a die — mostly draw & Recover, sometimes gain a card & Heat, '
          'rarely Tilt yourself.',
      timing: PowerTiming.round,
      flex: true,
    ),
    PowerCard(
      templateId: 'rogue_sleight_of_hand',
      name: 'Sleight of Hand',
      description: 'Redraw your hole cards. Hot Streak: draw 2 Power Cards.',
      timing: PowerTiming.round,
      hotStreak: true,
    ),
    PowerCard(
      templateId: 'rogue_splash_the_pot',
      name: 'Splash the Pot',
      description: 'Tilt the last player to bet or raise, if they aren\'t hot.',
      timing: PowerTiming.round,
    ),
    PowerCard(
      templateId: 'rogue_hot_dice',
      name: 'Hot Dice',
      description: 'Roll the dice: usually gain coins and draw, sometimes Tilt.',
      timing: PowerTiming.round,
      fire: true,
    ),
    PowerCard(
      templateId: 'rogue_misdirection',
      name: 'Misdirection',
      description: 'Steal 15 coins from the chip leader.',
      timing: PowerTiming.counter,
      tableTalk: true,
    ),
    PowerCard(
      templateId: 'rogue_ambush',
      name: 'Ambush',
      description: 'Steal 20 coins from the chip leader.',
      timing: PowerTiming.counter,
      tableTalk: true,
      oneShot: true,
    ),
    PowerCard(
      templateId: 'rogue_bag_o_tricks',
      name: 'Bag O\' Tricks',
      description: 'Gain a hole card.',
      timing: PowerTiming.round,
      flex: true,
    ),
    PowerCard(
      templateId: 'rogue_dual_wielding',
      name: 'Dual Wielding',
      description: 'Gain an extra hole card this hand.',
      timing: PowerTiming.setup,
    ),
    PowerCard(
      templateId: 'rogue_stealth',
      name: 'Stealth',
      description: 'Draw 1. You\'re Stealthed — opponents can\'t target you.',
      timing: PowerTiming.setup,
      oneShot: true,
    ),
    PowerCard(
      templateId: 'rogue_ace_up_sleeve',
      name: 'Ace Up the Sleeve',
      description: 'Swap a hole card for an Ace. Win: Tilt all opponents.',
      timing: PowerTiming.showdown,
      oneShot: true,
      playableWhileTilted: true,
    ),
  ];

  // ── Warrior (loose / aggressive) ──────────────────────────────────────
  static const _warrior = [
    PowerCard(
      templateId: 'warrior_intimidate',
      name: 'Intimidate',
      description: 'Tilt the last bettor (Cool Off if they\'re Heating Up).',
      timing: PowerTiming.counter,
      flex: true,
    ),
    PowerCard(
      templateId: 'warrior_low_ball',
      name: 'Low Ball',
      description: 'Mulligan your face cards.',
      timing: PowerTiming.setup,
    ),
    PowerCard(
      templateId: 'warrior_honorable_combat',
      name: 'Honorable Combat',
      description: 'Draw 1 and gain a hole card.',
      timing: PowerTiming.counter,
    ),
    PowerCard(
      templateId: 'warrior_check_it_down',
      name: 'Check It Down',
      description: 'Draw 1 Power Card.',
      timing: PowerTiming.round,
    ),
    PowerCard(
      templateId: 'warrior_ready_to_rumble',
      name: 'Ready to Rumble',
      description:
          'Discard your hand, draw 3. You\'re Tilted. Hot Streak: cool all '
          'hot opponents.',
      timing: PowerTiming.round,
      hotStreak: true,
    ),
    PowerCard(
      templateId: 'warrior_training_montage',
      name: 'Training Montage',
      description: 'Gain a hole card. Draw 1.',
      timing: PowerTiming.round,
      oneShot: true,
    ),
    PowerCard(
      templateId: 'warrior_mad_money',
      name: 'Mad Money',
      description: 'Gain 20 coins (30 if Tilted). Tilt cold opponents.',
      timing: PowerTiming.round,
      flex: true,
    ),
    PowerCard(
      templateId: 'warrior_table_taunts',
      name: 'Table Taunts',
      description: 'Tilt an opponent and yourself. Draw 1.',
      timing: PowerTiming.round,
      tableTalk: true,
    ),
    PowerCard(
      templateId: 'warrior_inferno_strike',
      name: 'Inferno Strike!',
      description: 'Destroy 20 coins from an opponent (30 if hot). Cool Off.',
      timing: PowerTiming.round,
      fire: true,
    ),
    PowerCard(
      templateId: 'warrior_berserker_rage',
      name: 'Berserker Rage',
      description: 'Draw 2. You\'re Tilted.',
      timing: PowerTiming.showdown,
      flex: true,
    ),
    PowerCard(
      templateId: 'warrior_mighty_blow',
      name: 'Mighty Blow',
      description: 'Destroy a board card. You\'re Heating Up!',
      timing: PowerTiming.round,
      playableWhileTilted: true,
    ),
    PowerCard(
      templateId: 'warrior_show_of_strength',
      name: 'Show of Strength',
      description: 'An opponent discards a Power Card. You Recover.',
      timing: PowerTiming.round,
      playableWhileTilted: true,
    ),
  ];

  // ── Merchant (adaptive / midrange) ────────────────────────────────────
  static const _merchant = [
    PowerCard(
      templateId: 'merchant_fire_sale',
      name: 'Fire Sale',
      description: 'Gain 10 coins (15 if Heating Up).',
      timing: PowerTiming.round,
      oneShot: true,
      hotStreak: true,
    ),
    PowerCard(
      templateId: 'merchant_irresistible_offer',
      name: 'Irresistible Offer',
      description: 'Steal 10 coins from an opponent; give them a hole card.',
      timing: PowerTiming.round,
      flex: true,
    ),
    PowerCard(
      templateId: 'merchant_special_delivery',
      name: 'Special Delivery!',
      description: 'Draw 2 Power Cards.',
      timing: PowerTiming.round,
      hotStreak: true,
    ),
    PowerCard(
      templateId: 'merchant_bargain_bin',
      name: 'Bargain Bin',
      description: 'Pay 10 coins; gain 2 hole cards.',
      timing: PowerTiming.round,
    ),
    PowerCard(
      templateId: 'merchant_rotate_merchandise',
      name: 'Rotate Merchandise',
      description: 'Discard your hand, then draw 3 Power Cards.',
      timing: PowerTiming.showdown,
      tableTalk: true,
    ),
    PowerCard(
      templateId: 'merchant_wheel_and_deal',
      name: 'Wheel and Deal',
      description: 'Gain a hole card.',
      timing: PowerTiming.round,
    ),
    PowerCard(
      templateId: 'merchant_hidden_gems',
      name: 'Hidden Gems',
      description: 'Gain a hole card (win or lose).',
      timing: PowerTiming.showdown,
      flex: true,
    ),
    PowerCard(
      templateId: 'merchant_expansion_plans',
      name: 'Expansion Plans',
      description: 'Gain 10 coins.',
      timing: PowerTiming.setup,
      oneShot: true,
    ),
    PowerCard(
      templateId: 'merchant_mystical_wares',
      name: 'Mystical Wares',
      description: 'Gain 10 coins.',
      timing: PowerTiming.setup,
      oneShot: true,
    ),
    PowerCard(
      templateId: 'merchant_hot_tip',
      name: 'Hot Tip!',
      description: 'Search your deck for a Setup card. You\'re Heating Up!',
      timing: PowerTiming.setup,
      flex: true,
    ),
    PowerCard(
      templateId: 'merchant_deal_of_lifetime',
      name: 'Deal of a Lifetime',
      description: 'Pay up to 30 coins for up to 3 hole cards. Cool Off.',
      timing: PowerTiming.round,
      oneShot: true,
      fire: true,
    ),
    PowerCard(
      templateId: 'merchant_hired_muscle',
      name: 'Hired Muscle',
      description: 'Steal a hole card from an opponent. Recover.',
      timing: PowerTiming.round,
      playableWhileTilted: true,
    ),
  ];

  // ── Noble (tight / control) ───────────────────────────────────────────
  static const _noble = [
    PowerCard(
      templateId: 'noble_curry_favor',
      name: 'Curry Favor',
      description: 'Pay a folded opponent 10; they Recover. Draw 2. Heating Up.',
      timing: PowerTiming.counter,
      tableTalk: true,
    ),
    PowerCard(
      templateId: 'noble_alms_for_the_poor',
      name: 'Alms for the Poor',
      description: 'Each poorer opponent gains a hole card; draw 1 per recipient.',
      timing: PowerTiming.round,
      tableTalk: true,
    ),
    PowerCard(
      templateId: 'noble_shiny_distraction',
      name: 'Shiny Distraction',
      description: 'Cancel a non-Fire Power Card; pay its owner 10 coins.',
      timing: PowerTiming.counter,
    ),
    PowerCard(
      templateId: 'noble_diplomatic_immunity',
      name: 'Diplomatic Immunity',
      description: 'Cancel a Power Card; its owner is Tilted instead.',
      timing: PowerTiming.counter,
    ),
    PowerCard(
      templateId: 'noble_trust_fund',
      name: 'Trust Fund',
      description: 'Gain 10 coins now and at the start of every Setup (Token).',
      timing: PowerTiming.setup,
    ),
    PowerCard(
      templateId: 'noble_bankroll_backer',
      name: 'Bankroll Backer',
      description: 'Fold. Draw 1 Power Card.',
      timing: PowerTiming.setup,
    ),
    PowerCard(
      templateId: 'noble_royal_decree',
      name: 'Royal Decree',
      description: 'You\'re Heating Up. Tilt cold opponents.',
      timing: PowerTiming.setup,
    ),
    PowerCard(
      templateId: 'noble_exquisite_bounty',
      name: 'Exquisite Bounty',
      description: 'Pay 20 coins; Tilt the chip leader.',
      timing: PowerTiming.setup,
    ),
    PowerCard(
      templateId: 'noble_tax_the_rich',
      name: 'Tax the Rich',
      description: 'Richer opponents each pay you 10. Gain 10. Heating Up.',
      timing: PowerTiming.round,
      tableTalk: true,
      flex: true,
    ),
    PowerCard(
      templateId: 'noble_powerful_friends',
      name: 'Powerful Friends',
      description: 'Re-deal a board card until a face/Wild; mulligan low hole cards.',
      timing: PowerTiming.round,
      fire: true,
    ),
    PowerCard(
      templateId: 'noble_inheritance',
      name: 'Inheritance',
      description: 'Gain 20 coins (put a Token into play).',
      timing: PowerTiming.round,
      oneShot: true,
      fire: true,
    ),
    PowerCard(
      templateId: 'noble_friendly_chop',
      name: 'Friendly Chop',
      description: 'Lose: you\'re Heating Up.',
      timing: PowerTiming.showdown,
      oneShot: true,
    ),
  ];

  static const Map<PokerClass, List<PowerCard>> byClass = {
    AiPersonality.rogue: _rogue,
    AiPersonality.warrior: _warrior,
    AiPersonality.merchant: _merchant,
    AiPersonality.noble: _noble,
  };

  static List<PowerCard> forClass(PokerClass c) => byClass[c] ?? const [];

  /// The set of card ids that cancel their target (handled in the chain).
  static const cancelCounters = {
    'feign_weakness',
    'noble_shiny_distraction',
    'noble_diplomatic_immunity',
  };
}
