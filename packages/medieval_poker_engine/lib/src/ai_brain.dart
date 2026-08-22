import 'dart:math';

import 'cards.dart';
import 'hand_evaluator.dart';
import 'items.dart';
import 'poker_engine.dart';
import 'power_cards.dart';

/// Tunable behaviour weights for an AI archetype.
class _Profile {
  final double callThreshold; // min strength to continue facing a bet
  final double raiseThreshold; // min strength to bet/raise for value
  final double bluffChance; // probability of firing with a weak hand
  final double aggression; // 0..1, scales bet sizing and raise frequency
  const _Profile(
      this.callThreshold, this.raiseThreshold, this.bluffChance, this.aggression);
}

/// Simple heuristic opponent. Estimates hand strength, then chooses an action
/// weighted by its personality and the pot odds.
class AiBrain {
  final Random _rng;
  AiBrain({Random? rng}) : _rng = rng ?? Random();

  static const Map<AiPersonality, _Profile> _profiles = {
    AiPersonality.rogue: _Profile(0.55, 0.68, 0.08, 0.7),
    AiPersonality.merchant: _Profile(0.42, 0.62, 0.12, 0.5),
    AiPersonality.warrior: _Profile(0.30, 0.52, 0.28, 0.85),
    AiPersonality.noble: _Profile(0.52, 0.72, 0.05, 0.35),
  };

  PokerAction decide(PokerGame game, PokerPlayer p) {
    final profile = _profiles[p.personality]!;
    final toCall = game.callAmount(p);
    var strength = _strength(p.hole, game.community);
    // A little noise so the AI is not perfectly predictable.
    strength = (strength + (_rng.nextDouble() * 0.10 - 0.05)).clamp(0.0, 1.0);

    final canRaise = game.canRaise(p); // respects card-imposed lockouts

    // Not facing a bet: check or bet.
    if (toCall == 0) {
      final wantsValue = strength >= profile.raiseThreshold;
      final wantsBluff = _rng.nextDouble() < profile.bluffChance;
      if ((wantsValue || wantsBluff) && canRaise) {
        return PokerAction.bet(_betSize(game, p, profile, strength));
      }
      return const PokerAction.check();
    }

    // Facing a bet: fold, call, or raise.
    final potOdds = toCall / (game.pot + toCall);

    if (strength >= profile.raiseThreshold &&
        canRaise &&
        _rng.nextDouble() < profile.aggression) {
      return PokerAction.raise(_raiseSize(game, p, profile, strength));
    }
    if (strength >= profile.callThreshold || strength > potOdds + 0.05) {
      return const PokerAction.call();
    }
    // Occasional loose call (a "float") from aggressive types on cheap bets.
    if (toCall <= game.ante * 2 && _rng.nextDouble() < profile.bluffChance) {
      return const PokerAction.call();
    }
    return const PokerAction.fold();
  }

  /// Public, noise-free strength estimate (used for Power Card decisions).
  double handStrength(PokerGame game, PokerPlayer p) =>
      _strength(p.hole, game.community);

  PowerCard? _take(
      List<PowerCard> avail, List<PowerCard> chosen, String id) {
    for (final c in avail) {
      if (c.templateId == id && !chosen.contains(c)) return c;
    }
    return null;
  }

  /// Which Setup-window Power Cards the AI chooses to play, in order.
  List<PowerCard> setupPlays(PokerGame game, PokerPlayer p) {
    final avail = game.playablePower(p, PowerTiming.setup);
    final plays = <PowerCard>[];
    void add(String id) {
      final c = _take(avail, plays, id);
      if (c != null) plays.add(c);
    }

    add('add_on'); // free coins — always good
    if (p.heatingUp) add('run_the_table'); // Fire aggression
    if (p.stack >= 30) add('shopping_spree'); // pay 10 for a hole card + draw
    _addClassPlays(game, p, PowerTiming.setup, plays);
    return plays;
  }

  /// Which Round-window Power Cards the AI chooses to play, in order.
  /// [avail] already respects status (Fire needs Heating Up; Tilted players
  /// only see Flex / Tilted cards).
  List<PowerCard> roundPlays(PokerGame game, PokerPlayer p) {
    final s = handStrength(game, p);
    final facingBet = game.actingPlayer == p && game.facingBet;
    final avail = game.playablePower(p, PowerTiming.round);
    final plays = <PowerCard>[];
    void add(String id) {
      final c = _take(avail, plays, id);
      if (c != null) plays.add(c);
    }

    // Recover from Tilt: prefer Rock Solid (no fold) over Re-Gain Composure.
    if (p.tilted) {
      if (_take(avail, plays, 'rock_solid') != null) {
        add('rock_solid');
      } else if (s < 0.4) {
        add('regain_composure'); // folds, but worth it to recover a weak hand
      }
    }
    // Snap Call tilts the aggressor when facing a bet.
    if (facingBet && _rng.nextDouble() < 0.4) add('snap_call');
    // Aggressive classes tilt an opponent.
    if ((p.personality == AiPersonality.warrior ||
            p.personality == AiPersonality.rogue) &&
        _rng.nextDouble() < 0.35) {
      add('trash_talker');
    }
    // Bail on a hopeless hand for a small refund.
    if (facingBet && s < 0.18) add('cash_out');
    // Card advantage / Heating Up when the hand is thin.
    if (p.powerHand.length < 3) add('burst_of_confidence');
    _addClassPlays(game, p, PowerTiming.round, plays);
    return plays;
  }

  static bool _isClass(String id) =>
      id.startsWith('rogue_') ||
      id.startsWith('warrior_') ||
      id.startsWith('merchant_') ||
      id.startsWith('noble_') ||
      id.startsWith('jack_') ||
      id.startsWith('queen_') ||
      id.startsWith('king_') ||
      id.startsWith('joker_');

  /// Class/Court cards the AI avoids auto-playing (self-harmful / situational).
  static const _skipClass = {
    'noble_bankroll_backer', // folds the hand
    'warrior_table_taunts', // tilts the player too
    'jack_tactical_retreat', // folds the hand
    'queen_sick_laydown', // folds the hand
    'joker_drunken_boxing', // only useful while Tilted
  };

  /// Append beneficial class cards for [timing] (up to [max]).
  void _addClassPlays(PokerGame game, PokerPlayer p, PowerTiming timing,
      List<PowerCard> plays,
      {int max = 2}) {
    int added = 0;
    for (final c in game.playablePower(p, timing)) {
      if (added >= max) break;
      if (!_isClass(c.templateId) || plays.contains(c)) continue;
      if (_skipClass.contains(c.templateId)) continue;
      if (c.templateId == 'warrior_ready_to_rumble' && !p.heatingUp) continue;
      plays.add(c);
      added++;
    }
  }

  /// Which Showdown-window cards the AI plays (all available — each is a
  /// win/lose upside at the end of the hand).
  List<PowerCard> showdownPlays(PokerGame game, PokerPlayer p) {
    final avail = game.playableShowdown(p);
    final plays = <PowerCard>[];
    for (final c in avail) {
      if (!plays.contains(c)) plays.add(c);
    }
    return plays;
  }

  /// Whether the AI plays a "Just Dealt" board counter (rarely — board value
  /// is hard to judge).
  PowerCard? pickBoardCounter(PokerGame game, PokerPlayer p) {
    final options = game.playableJustDealt(p);
    if (options.isEmpty) return null;
    return _rng.nextDouble() < 0.12 ? options.first : null;
  }

  /// Choose an opponent to target (e.g. Trash Talker): the wealthiest
  /// non-tilted opponent, falling back to the wealthiest.
  PokerPlayer? pickTarget(PokerGame game, PokerPlayer actor, PowerCard card) {
    final targets = game.targetsFor(actor, card);
    if (targets.isEmpty) return null;
    return targets.reduce((a, b) => a.stack >= b.stack ? a : b);
  }

  static const _cancelIds = {
    'feign_weakness',
    'noble_shiny_distraction',
    'noble_diplomatic_immunity',
    'queen_royal_charm',
    'joker_life_of_party',
  };

  /// Decide whether [responder] plays a Counter in response to [top]. Prefers a
  /// cancel counter; otherwise a value counter (steal/tilt). Returns null to pass.
  PowerCard? pickCounter(PokerGame game, PokerPlayer responder, ChainEntry top) {
    final options = game.playableCounters(responder, top);
    if (options.isEmpty) return null;
    final profile = _profiles[responder.personality]!;

    double chance = 0.22;
    if (identical(top.targetPlayer, responder)) {
      chance = 0.85; // they're targeting me — swat it down
    } else if (top.card.fire) {
      chance = 0.5; // Fire cards are dangerous
    } else if (const {
      'add_on',
      'shopping_spree',
      'burst_of_confidence',
      'run_the_table',
    }.contains(top.card.templateId)) {
      chance = 0.35;
    }
    chance *= (0.7 + profile.aggression * 0.5);
    if (_rng.nextDouble() >= chance) return null;

    for (final c in options) {
      if (_cancelIds.contains(c.templateId)) return c; // prefer a cancel
    }
    return options.first; // value counter (steal / tilt)
  }

  /// Whether the AI spends a Comp Chip to cover [card]'s pay cost (does so when
  /// coins are tight relative to the cost and the coming antes).
  bool usesChipFor(PokerGame game, PokerPlayer p, PowerCard card) {
    if (p.compChips <= 0) return false;
    final cost = game.payCostOf(card);
    return p.stack < cost + game.ante * 4;
  }

  /// Whether the AI sells a Comp Chip at Setup (only when nearly out of coins,
  /// since a chip is worth more spent on a "pay" cost than 10 coins).
  bool sellsChip(PokerGame game, PokerPlayer p) =>
      game.canSellChip(p) && p.stack < game.ante * 2;

  /// Held Items the AI actively plays on its turn — beneficial ones (skips the
  /// self-folding Smoke Bomb and Fool's Gold, which it keeps for value).
  List<GameItem> itemPlays(PokerGame game, PokerPlayer p) => game
      .playableItems(p)
      .where((it) => it.id != 'smoke_bomb' && it.id != 'fools_gold')
      .toList();

  /// The mode the AI picks for a multi-mode item (0 if single-mode).
  int itemMode(PokerGame game, PokerPlayer p, GameItem item) {
    switch (item.id) {
      case 'monkey_paw':
        if (p.stack < game.ante * 3) return 2; // broke → grab 30 coins
        if (p.powerHand.length < 2) return 1; // thin hand → draw 2
        return 0; // otherwise gain a hole card
      case 'grappling_hook':
        final canSteal = game.players.any((o) =>
            !identical(o, p) && o.inHand && o.tilted && o.hole.isNotEmpty);
        return canSteal ? 1 : 0;
      default:
        return 0;
    }
  }

  int _betSize(
      PokerGame game, PokerPlayer p, _Profile profile, double strength) {
    // Very strong hands sometimes shove.
    if (strength > 0.9 && _rng.nextDouble() < profile.aggression) {
      return game.maxRaiseTo(p);
    }
    final fraction = 0.4 + profile.aggression * 0.4;
    var size = (game.pot * fraction).round();
    if (size < game.ante) size = game.ante;
    // Clamp between a minimal raise and the player's whole stack. A short
    // stack that can't cover a full min-bet simply moves all-in for less.
    final lo = p.roundBet + 1;
    final hi = game.maxRaiseTo(p);
    return (p.roundBet + size).clamp(lo, hi < lo ? lo : hi).toInt();
  }

  int _raiseSize(
      PokerGame game, PokerPlayer p, _Profile profile, double strength) {
    final fraction = 0.5 + profile.aggression * 0.5;
    final raiseBy = (game.pot * fraction).round();
    var target = game.currentBet + max(raiseBy, game.minRaiseSize);
    if (strength > 0.92) target = game.maxRaiseTo(p);
    return target.clamp(game.minRaiseTo(p), game.maxRaiseTo(p)).toInt();
  }

  // ── Strength estimation ─────────────────────────────────────────────

  /// Returns a 0..1 estimate of how strong the holding is. Jokers are stripped
  /// for this heuristic (with a flat bonus) to avoid the expensive wild-card
  /// substitution — the real showdown still evaluates wilds exactly.
  double _strength(List<PlayingCard> hole, List<PlayingCard> community) {
    final all = [...hole, ...community].where((c) => !c.isItem);
    final jokers = all.where((c) => c.isJoker).length;
    final jokerBonus = jokers * 0.18;
    final concrete = [
      for (final c in all)
        if (!c.isJoker) c
    ];
    if (community.isEmpty || concrete.length < 5) {
      return (_preflopStrength(
                  hole.where((c) => !c.isJoker && !c.isItem).toList()) +
              jokerBonus)
          .clamp(0.0, 1.0);
    }
    final value = HandEvaluator.evaluateBest(concrete);
    final base = value.category.index / HandCategory.values.length; // 0..~0.9
    final topRank = value.score.length > 1 ? value.score[1] : 2;
    final rankBonus = ((topRank - 2) / 12) * (1 / HandCategory.values.length);
    return (base + rankBonus + jokerBonus).clamp(0.0, 1.0);
  }

  double _preflopStrength(List<PlayingCard> hole) {
    if (hole.isEmpty) return 0;
    final ranks = hole.map((c) => c.rank).toList()..sort((a, b) => b - a);
    final counts = <int, int>{};
    for (final r in ranks) {
      counts[r] = (counts[r] ?? 0) + 1;
    }
    final maxCount = counts.values.reduce(max);
    final pairRank =
        counts.entries.where((e) => e.value >= 2).fold(0, (m, e) => max(m, e.key));

    double score = (ranks.first - 2) / 12 * 0.35; // high-card component

    if (maxCount >= 3) {
      score += 0.75; // three of a kind in the hole is huge
    } else if (maxCount == 2) {
      score += 0.35 + (pairRank / 14) * 0.25; // a pocket pair
    }

    // Suited / connected bonuses.
    final suits = hole.map((c) => c.suit).toList();
    final suitCounts = <Suit, int>{};
    for (final s in suits) {
      suitCounts[s] = (suitCounts[s] ?? 0) + 1;
    }
    if (suitCounts.values.any((c) => c >= 2)) score += 0.06;
    if (suitCounts.values.any((c) => c >= 3)) score += 0.06;

    final gaps = <int>[];
    for (int i = 0; i < ranks.length - 1; i++) {
      gaps.add(ranks[i] - ranks[i + 1]);
    }
    if (gaps.any((g) => g == 1)) score += 0.05;

    return score.clamp(0.0, 1.0);
  }
}
