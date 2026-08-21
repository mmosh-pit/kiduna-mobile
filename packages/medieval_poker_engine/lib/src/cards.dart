import 'dart:math';

/// The four suits of a standard deck.
enum Suit { clubs, diamonds, hearts, spades }

extension SuitGlyph on Suit {
  /// Unicode glyph used when rendering a card face.
  String get glyph {
    switch (this) {
      case Suit.clubs:
        return '♣';
      case Suit.diamonds:
        return '♦';
      case Suit.hearts:
        return '♥';
      case Suit.spades:
        return '♠';
    }
  }

  /// Red suits are drawn in red, black suits in near-black.
  bool get isRed => this == Suit.hearts || this == Suit.diamonds;
}

/// A single playing card. Rank is 2..14 where 11=J, 12=Q, 13=K, 14=A.
/// A [PlayingCard.joker] is a wild card that the evaluator substitutes with
/// whatever concrete card yields the best hand.
class PlayingCard {
  final int rank;
  final Suit suit;
  final bool isJoker;

  /// When set, this is an Item card (from the Item/Token set), not a real
  /// poker card. Item cards are ignored by the hand evaluator and are played
  /// like a Round card.
  final String? itemId;

  const PlayingCard(this.rank, this.suit)
      : isJoker = false,
        itemId = null,
        assert(rank >= 2 && rank <= 14);

  /// The single wild Joker (rank/suit are placeholders and never used).
  const PlayingCard.joker()
      : rank = 0,
        suit = Suit.spades,
        isJoker = true,
        itemId = null;

  /// An Item card carrying an item id (rank/suit are placeholders).
  const PlayingCard.item(this.itemId)
      : rank = 0,
        suit = Suit.spades,
        isJoker = false;

  bool get isItem => itemId != null;

  /// Short rank label: "2".."9", "T", "J", "Q", "K", "A".
  String get rankLabel {
    if (isItem) return '◈';
    if (isJoker) return '★';
    switch (rank) {
      case 14:
        return 'A';
      case 13:
        return 'K';
      case 12:
        return 'Q';
      case 11:
        return 'J';
      case 10:
        return 'T';
      default:
        return '$rank';
    }
  }

  /// e.g. "A♠", "WILD" for the Joker, or "ITEM" for an Item card.
  String get label =>
      isItem ? 'ITEM' : (isJoker ? 'WILD' : '$rankLabel${suit.glyph}');

  @override
  bool operator ==(Object other) =>
      other is PlayingCard &&
      other.isJoker == isJoker &&
      other.itemId == itemId &&
      other.rank == rank &&
      other.suit == suit;

  @override
  int get hashCode => Object.hash(rank, suit, isJoker, itemId);

  @override
  String toString() => label;
}

/// A standard 52-card deck plus wild Jokers. Shuffle with an injectable
/// [Random] for deterministic tests.
class Deck {
  final List<PlayingCard> _cards = [];
  final Random _rng;
  final int jokerCount;

  Deck({Random? rng, this.jokerCount = 1}) : _rng = rng ?? Random() {
    reset();
  }

  int get remaining => _cards.length;

  /// Rebuild the deck: 52 cards plus [jokerCount] wild Jokers.
  void reset() {
    _cards.clear();
    for (final suit in Suit.values) {
      for (int rank = 2; rank <= 14; rank++) {
        _cards.add(PlayingCard(rank, suit));
      }
    }
    for (int i = 0; i < jokerCount; i++) {
      _cards.add(const PlayingCard.joker());
    }
  }

  void shuffle() => _cards.shuffle(_rng);

  /// Look at (without drawing) the top [n] cards that would be drawn next.
  List<PlayingCard> peek(int n) =>
      _cards.reversed.take(n.clamp(0, _cards.length)).toList();

  /// Look at the bottom [n] cards (used by Dealer's Favorite).
  List<PlayingCard> peekBottom(int n) =>
      _cards.take(n.clamp(0, _cards.length)).toList();

  /// Draw from the bottom of the deck.
  PlayingCard drawBottom() {
    if (_cards.isEmpty) throw StateError('Cannot draw from an empty deck');
    return _cards.removeAt(0);
  }

  /// Draw the top card. Throws if the deck is empty.
  PlayingCard draw() {
    if (_cards.isEmpty) {
      throw StateError('Cannot draw from an empty deck');
    }
    return _cards.removeLast();
  }

  /// Draw [count] cards.
  List<PlayingCard> drawMany(int count) =>
      List.generate(count, (_) => draw());
}
