import 'package:medieval_poker_engine/medieval_poker_engine.dart';

import '../../../data/models/sentinel_rules_model.dart';

class SentinelViolation {
  final String rule;
  final String message;
  const SentinelViolation({required this.rule, required this.message});
}

abstract final class SentinelValidator {
  static SentinelViolation? validateAction(
    SentinelRules rules,
    PokerAction action,
    PokerPlayer player,
  ) {
    if (rules.isEmpty) return null;

    if (rules.allowFoldOnly == true && action.type != PlayerActionType.fold) {
      return const SentinelViolation(
        rule: 'allowFoldOnly',
        message: 'Only folding is allowed under these rules.',
      );
    }

    if (action.type == PlayerActionType.bet || action.type == PlayerActionType.raise) {
      final amount = action.amount;
      if (rules.maxBetAmount != null && amount > rules.maxBetAmount!) {
        return SentinelViolation(
          rule: 'maxBetAmount',
          message: 'Bet exceeds the maximum of ${rules.maxBetAmount}.',
        );
      }
      if (rules.minBetAmount != null && amount < rules.minBetAmount!) {
        if (amount < player.stack) {
          return SentinelViolation(
            rule: 'minBetAmount',
            message: 'Bet must be at least ${rules.minBetAmount}.',
          );
        }
      }
    }

    return null;
  }

  static SentinelViolation? validatePowerCard(
    SentinelRules rules,
    String cardName,
  ) {
    if (rules.isEmpty) return null;

    if (rules.enablePowerCards == false) {
      return const SentinelViolation(
        rule: 'enablePowerCards',
        message: 'Power cards are disabled in this cell.',
      );
    }

    if (rules.bannedPowerCards.contains(cardName)) {
      return SentinelViolation(
        rule: 'bannedPowerCards',
        message: '$cardName is banned in this cell.',
      );
    }

    return null;
  }

  static SentinelViolation? validateCourtMember(
    SentinelRules rules,
    String memberName,
  ) {
    if (rules.isEmpty) return null;

    if (rules.bannedCourtMembers.contains(memberName)) {
      return SentinelViolation(
        rule: 'bannedCourtMembers',
        message: '$memberName is banned in this cell.',
      );
    }

    return null;
  }

  static SentinelViolation? validatePlayerClass(
    SentinelRules rules,
    String className,
  ) {
    if (rules.isEmpty) return null;

    if (rules.allowedClasses != null && !rules.allowedClasses!.contains(className)) {
      return SentinelViolation(
        rule: 'allowedClasses',
        message: '$className is not allowed in this cell.',
      );
    }

    return null;
  }

  static List<SentinelViolation> validateAll(
    SentinelRules rules, {
    PokerAction? action,
    PokerPlayer? player,
    String? powerCardName,
    String? courtMemberName,
    String? playerClassName,
  }) {
    final violations = <SentinelViolation>[];

    if (action != null && player != null) {
      final v = validateAction(rules, action, player);
      if (v != null) violations.add(v);
    }

    if (powerCardName != null) {
      final v = validatePowerCard(rules, powerCardName);
      if (v != null) violations.add(v);
    }

    if (courtMemberName != null) {
      final v = validateCourtMember(rules, courtMemberName);
      if (v != null) violations.add(v);
    }

    if (playerClassName != null) {
      final v = validatePlayerClass(rules, playerClassName);
      if (v != null) violations.add(v);
    }

    return violations;
  }
}
