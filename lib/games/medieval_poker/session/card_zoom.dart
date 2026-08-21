import 'package:flutter/foundation.dart';

/// A card to show enlarged in the zoom overlay: one or more asset paths to try
/// (first that loads wins), plus its [title]/[subtitle] and a text [fallback]
/// shown if none of the art loads.
@immutable
class CardZoomTarget {
  /// Full asset paths, tried in order (e.g. power art → item art).
  final List<String> assets;
  final String title;
  final String? subtitle;

  /// Shown big if no asset in [assets] loads (e.g. "K♥", "★").
  final String fallback;

  const CardZoomTarget({
    required this.assets,
    required this.title,
    this.subtitle,
    this.fallback = '★',
  });
}

/// Drives the card-zoom overlay. Shared by the Flame table (tapping a poker card
/// on the felt) and the Flutter HUD (tapping a power card), so a single overlay
/// serves both. The owning screen creates one and passes it to both; tapping any
/// card sets [value], the overlay renders it, and a tap anywhere clears it.
class CardZoomController extends ValueNotifier<CardZoomTarget?> {
  CardZoomController() : super(null);
  void show(CardZoomTarget target) => value = target;
  void clear() => value = null;
}
