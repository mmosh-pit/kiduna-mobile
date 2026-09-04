import 'package:medieval_poker_engine/medieval_poker_engine.dart';

import '../../../data/models/sentinel_rules_model.dart';

abstract final class SentinelConfigBuilder {
  static PokerConfig build(SentinelRules rules, [PokerConfig base = const PokerConfig()]) {
    return PokerConfig(
      startingStack: rules.startingStack ?? base.startingStack,
      anteLevels: rules.customAnteLevels ?? base.anteLevels,
      handsPerLevel: base.handsPerLevel,
      holeCards: rules.maxHoleCards ?? base.holeCards,
      enablePowerCards: rules.enablePowerCards ?? base.enablePowerCards,
      maxPowerHand: base.maxPowerHand,
      compChipsPerPlayer: rules.compChipsPerPlayer ?? base.compChipsPerPlayer,
      maxHoleCards: rules.maxHoleCards ?? base.maxHoleCards,
      suddenDeathAnte: base.suddenDeathAnte,
      suddenDeathHands: base.suddenDeathHands,
      powerDeckSize: rules.powerDeckSize ?? base.powerDeckSize,
      jokerCount: (rules.enableJokers == false) ? 0 : base.jokerCount,
      timedLevels: rules.timedLevels ?? base.timedLevels,
      levelDurationSeconds: rules.levelDurationSeconds ?? base.levelDurationSeconds,
    );
  }
}
