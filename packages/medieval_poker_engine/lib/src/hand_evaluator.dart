import 'cards.dart';

/// Poker hand categories, ordered weakest (0) to strongest (8).
enum HandCategory {
  highCard,
  pair,
  twoPair,
  threeOfAKind,
  straight,
  flush,
  fullHouse,
  fourOfAKind,
  straightFlush,
}

extension HandCategoryLabel on HandCategory {
  String get label {
    switch (this) {
      case HandCategory.highCard:
        return 'High Card';
      case HandCategory.pair:
        return 'Pair';
      case HandCategory.twoPair:
        return 'Two Pair';
      case HandCategory.threeOfAKind:
        return 'Three of a Kind';
      case HandCategory.straight:
        return 'Straight';
      case HandCategory.flush:
        return 'Flush';
      case HandCategory.fullHouse:
        return 'Full House';
      case HandCategory.fourOfAKind:
        return 'Four of a Kind';
      case HandCategory.straightFlush:
        return 'Straight Flush';
    }
  }
}

/// The evaluated strength of a five-card hand. Comparable so hands can be
/// ranked directly. Equality (a tie) means an identical [score] vector.
class HandValue implements Comparable<HandValue> {
  final HandCategory category;

  /// The five cards that make up this hand (for display).
  final List<PlayingCard> cards;

  /// Lexicographically comparable strength vector: category index first,
  /// then tie-break ranks in descending significance.
  final List<int> score;

  const HandValue(this.category, this.cards, this.score);

  @override
  int compareTo(HandValue other) {
    final a = score;
    final b = other.score;
    final n = a.length < b.length ? a.length : b.length;
    for (int i = 0; i < n; i++) {
      if (a[i] != b[i]) return a[i].compareTo(b[i]);
    }
    return a.length.compareTo(b.length);
  }

  bool operator >(HandValue other) => compareTo(other) > 0;
  bool operator <(HandValue other) => compareTo(other) < 0;

  @override
  String toString() => category.label;
}

/// Evaluates poker hands. All methods are pure and side-effect free.
class HandEvaluator {
  /// Evaluate exactly five cards. If any card is a wild Joker, it is replaced
  /// with whatever concrete card produces the strongest hand.
  static HandValue evaluate5(List<PlayingCard> cards) {
    assert(cards.length == 5);

    final jokerIndex = cards.indexWhere((c) => c.isJoker);
    if (jokerIndex != -1) return _evaluateWild(cards, jokerIndex);

    final ranks = cards.map((c) => c.rank).toList()..sort((a, b) => b - a);
    final isFlush = cards.every((c) => c.suit == cards.first.suit);

    // Count occurrences of each rank.
    final counts = <int, int>{};
    for (final r in ranks) {
      counts[r] = (counts[r] ?? 0) + 1;
    }

    // Straight detection (including the A-2-3-4-5 "wheel").
    final distinct = counts.keys.toList()..sort((a, b) => b - a);
    int? straightHigh;
    if (distinct.length == 5) {
      if (distinct.first - distinct.last == 4) {
        straightHigh = distinct.first;
      } else if (distinct[0] == 14 &&
          distinct[1] == 5 &&
          distinct[2] == 4 &&
          distinct[3] == 3 &&
          distinct[4] == 2) {
        straightHigh = 5; // wheel: ace plays low
      }
    }

    // Ranks grouped by descending count, then descending rank. This drives
    // the tie-break vector for made hands (quads/trips/pairs first).
    final byCount = counts.keys.toList()
      ..sort((a, b) {
        final c = counts[b]!.compareTo(counts[a]!);
        return c != 0 ? c : b.compareTo(a);
      });
    final countPattern = byCount.map((r) => counts[r]!).toList();

    HandCategory category;
    List<int> tiebreak;

    if (isFlush && straightHigh != null) {
      category = HandCategory.straightFlush;
      tiebreak = [straightHigh];
    } else if (countPattern.first == 4) {
      category = HandCategory.fourOfAKind;
      tiebreak = byCount; // [quad, kicker]
    } else if (countPattern.length >= 2 &&
        countPattern[0] == 3 &&
        countPattern[1] == 2) {
      category = HandCategory.fullHouse;
      tiebreak = byCount; // [trip, pair]
    } else if (isFlush) {
      category = HandCategory.flush;
      tiebreak = ranks; // all five, descending
    } else if (straightHigh != null) {
      category = HandCategory.straight;
      tiebreak = [straightHigh];
    } else if (countPattern.first == 3) {
      category = HandCategory.threeOfAKind;
      tiebreak = byCount; // [trip, kicker, kicker]
    } else if (countPattern.length >= 2 &&
        countPattern[0] == 2 &&
        countPattern[1] == 2) {
      category = HandCategory.twoPair;
      tiebreak = byCount; // [highPair, lowPair, kicker]
    } else if (countPattern.first == 2) {
      category = HandCategory.pair;
      tiebreak = byCount; // [pair, kicker, kicker, kicker]
    } else {
      category = HandCategory.highCard;
      tiebreak = ranks;
    }

    return HandValue(category, List.of(cards), [category.index, ...tiebreak]);
  }

  /// Substitute the Joker at [jokerIndex] with the best legal concrete card.
  /// Recurses, so multiple Jokers are handled.
  static HandValue _evaluateWild(List<PlayingCard> cards, int jokerIndex) {
    final present = cards.where((c) => !c.isJoker).toSet();
    HandValue? best;
    for (final suit in Suit.values) {
      for (int rank = 2; rank <= 14; rank++) {
        final candidate = PlayingCard(rank, suit);
        if (present.contains(candidate)) continue;
        final sub = List<PlayingCard>.of(cards);
        sub[jokerIndex] = candidate;
        final v = evaluate5(sub);
        if (best == null || v > best) best = v;
      }
    }
    return best!;
  }

  /// Evaluate the best five-card hand from any 5+ cards (e.g. 3 hole cards +
  /// up to 5 community cards). Throws if fewer than five cards are provided.
  static HandValue evaluateBest(List<PlayingCard> cards) {
    // Item cards are not real poker cards — exclude them from the hand.
    final real = cards.where((c) => !c.isItem).toList();
    if (real.length < 5) {
      throw ArgumentError('Need at least 5 real cards to evaluate, got '
          '${real.length}');
    }
    if (real.length == 5) return evaluate5(real);

    HandValue? best;
    for (final combo in _combinations(real, 5)) {
      final v = evaluate5(combo);
      if (best == null || v > best) best = v;
    }
    return best!;
  }

  /// All k-sized combinations of [items].
  static Iterable<List<PlayingCard>> _combinations(
      List<PlayingCard> items, int k) sync* {
    final n = items.length;
    final indices = List<int>.generate(k, (i) => i);
    while (true) {
      yield [for (final i in indices) items[i]];
      int i = k - 1;
      while (i >= 0 && indices[i] == n - k + i) {
        i--;
      }
      if (i < 0) break;
      indices[i]++;
      for (int j = i + 1; j < k; j++) {
        indices[j] = indices[j - 1] + 1;
      }
    }
  }
}
