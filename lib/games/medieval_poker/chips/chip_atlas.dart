import 'package:flame/cache.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';

import 'chip_model.dart';

/// Loads and caches the chip art as Flame sprites for rendering on canvas.
class ChipAtlas {
  final Images _images = Images(prefix: 'assets/images/chips/');
  final Map<ChipType, Sprite> _sprites = {};
  bool loaded = false;

  static const Map<ChipType, String> _files = {
    ChipType.gold: 'chip_gold.png',
    ChipType.sapphire: 'chip_sapphire.png',
    ChipType.onyx: 'chip_onyx.png',
    ChipType.emerald: 'chip_emerald.png',
    ChipType.ruby: 'chip_ruby.png',
    ChipType.opal: 'chip_opal.png',
  };

  Future<void> load() async {
    try {
      for (final entry in _files.entries) {
        _sprites[entry.key] = Sprite(await _images.load(entry.value));
      }
      loaded = true;
    } catch (e) {
      loaded = false;
      debugPrint('[ChipAtlas] chip art unavailable, using drawn fallback: $e');
    }
  }

  /// The sprite for a chip type, or null if art is unavailable.
  Sprite? spriteFor(ChipType type) => _sprites[type];
}
