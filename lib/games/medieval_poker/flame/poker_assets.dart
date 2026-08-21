import 'package:flame/cache.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';

import 'package:medieval_poker_engine/medieval_poker_engine.dart';

/// Loads and caches the Medieval Poker card art. If loading fails for any
/// reason the game falls back to drawn cards (see [CardComponent]).
class PokerCardAtlas {
  final Images _images = Images(prefix: 'assets/medieval_poker/cards/');
  final Map<String, Sprite> _faces = {};
  Sprite? back;
  Sprite? joker;
  bool loaded = false;

  static const Map<Suit, String> _suitName = {
    Suit.clubs: 'clubs',
    Suit.diamonds: 'diamonds',
    Suit.hearts: 'hearts',
    Suit.spades: 'spades',
  };

  static String _rankToken(int rank) {
    switch (rank) {
      case 14:
        return 'A';
      case 13:
        return 'K';
      case 12:
        return 'Q';
      case 11:
        return 'J';
      default:
        return '$rank';
    }
  }

  static String _key(Suit suit, int rank) =>
      '${_suitName[suit]}_${_rankToken(rank)}';

  /// The card-art asset key for a card (e.g. `hearts_K`), for callers that need
  /// to load the same art outside the atlas (the zoom overlay).
  static String assetKeyForCard(PlayingCard card) => _key(card.suit, card.rank);

  Future<void> load() async {
    try {
      for (final suit in Suit.values) {
        for (int rank = 2; rank <= 14; rank++) {
          final key = _key(suit, rank);
          _faces[key] = Sprite(await _images.load('$key.png'));
        }
      }
      joker = Sprite(await _images.load('joker.png'));
      back = Sprite(await _images.load('back.png'));
      loaded = true;
    } catch (e) {
      // Missing/undeclared assets — keep drawn-card fallback.
      loaded = false;
      debugPrint('[PokerCardAtlas] card art unavailable, using drawn cards: $e');
    }
  }

  /// The face sprite for [card], or null if art is unavailable.
  Sprite? faceFor(PlayingCard card) {
    if (card.isJoker) return joker;
    return _faces[_key(card.suit, card.rank)];
  }
}
