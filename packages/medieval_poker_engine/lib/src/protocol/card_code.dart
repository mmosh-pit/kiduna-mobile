import '../cards.dart';

/// Compact, JSON-friendly encoding of a card for the wire.
///
/// Formats:
///   real card → rank + suit, e.g. "As", "Kd", "Th", "9c", "2s"
///   wild joker → "WILD"
///   item card  → `I:<itemId>`  (e.g. "I:healing_potion")
///   hidden     → "??"          (an opponent's face-down card)
abstract final class CardCode {
  static const String hidden = '??';

  static const _rankToChar = {14: 'A', 13: 'K', 12: 'Q', 11: 'J', 10: 'T'};
  static const _charToRank = {'A': 14, 'K': 13, 'Q': 12, 'J': 11, 'T': 10};
  static const _suitToChar = {
    Suit.spades: 's',
    Suit.hearts: 'h',
    Suit.diamonds: 'd',
    Suit.clubs: 'c',
  };
  static const _charToSuit = {
    's': Suit.spades,
    'h': Suit.hearts,
    'd': Suit.diamonds,
    'c': Suit.clubs,
  };

  /// Encode a card to its wire code.
  static String encode(PlayingCard c) {
    if (c.isItem) return 'I:${c.itemId}';
    if (c.isJoker) return 'WILD';
    final r = _rankToChar[c.rank] ?? '${c.rank}';
    return '$r${_suitToChar[c.suit]}';
  }

  /// Decode a wire code back to a card. Returns null for [hidden] ("??").
  static PlayingCard? decode(String code) {
    if (code == hidden) return null;
    if (code == 'WILD') return const PlayingCard.joker();
    if (code.startsWith('I:')) return PlayingCard.item(code.substring(2));
    final rankPart = code.substring(0, code.length - 1);
    final suitPart = code.substring(code.length - 1);
    final rank = _charToRank[rankPart] ?? int.parse(rankPart);
    return PlayingCard(rank, _charToSuit[suitPart]!);
  }
}
