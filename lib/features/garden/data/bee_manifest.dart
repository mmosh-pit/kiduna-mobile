import 'package:flutter/foundation.dart';

/// Definition of a bee type with its sigil and sprite sheet.
@immutable
class BeeType {
  const BeeType({
    required this.id,
    required this.sigil,
    required this.spriteSheet,
    required this.frameWidth,
    required this.frameHeight,
    required this.columns,
    required this.totalFrames,
    required this.loopEnd,
    required this.fps,
    this.renderSize = 480,
  });

  final String id;
  final String sigil;

  /// Path to the sprite sheet PNG (relative to assets — no 'assets/' prefix).
  final String spriteSheet;

  final int frameWidth;
  final int frameHeight;
  final int columns;
  final int totalFrames;

  /// Last frame index for the loop (frames 0..loopEnd).
  final int loopEnd;
  final int fps;
  final int renderSize;
}

/// Registry of all bee types and their category mappings.
abstract class BeeManifest {
  const BeeManifest._();

  /// Available bee types with generated sprite sheets.
  /// Only bee_01 and bee_02 have sprite sheets right now.
  /// Others fall back to bee_01 until their sheets are generated.
  static const compassStar = BeeType(
    id: 'bee_01_compass_star',
    sigil: 'compass star',
    spriteSheet: 'assets/images/sprites/bee_01_compass_star_crawl.png',
    frameWidth: 256,
    frameHeight: 256,
    columns: 5,
    totalFrames: 25,
    loopEnd: 21,
    fps: 11,
    renderSize: 480,
  );

  static const serpentHook = BeeType(
    id: 'bee_02_serpent_hook',
    sigil: 'serpent hook',
    spriteSheet: 'assets/images/sprites/bee_02_serpent_hook_crawl.png',
    frameWidth: 256,
    frameHeight: 256,
    columns: 5,
    totalFrames: 25,
    loopEnd: 21,
    fps: 11,
    renderSize: 480,
  );

  /// All registered bee types.
  static const List<BeeType> all = [compassStar, serpentHook];

  /// Map task category strings to bee types.
  /// Categories without a dedicated sprite sheet fall back to compassStar.
  static BeeType forCategory(String category) {
    return switch (category.toLowerCase()) {
      'compass' => compassStar,
      'shield' => serpentHook,
      'spark' => compassStar, // TODO: bee_04 lightning_path when ready
      'loom' => serpentHook, // TODO: bee_05 radiant_eye when ready
      'portal' => compassStar, // TODO: bee_06 four_point_star when ready
      'wind' => serpentHook, // TODO: bee_07 five_point_star when ready
      'flower' => compassStar, // TODO: bee_10 spiral_flower when ready
      'eye' => serpentHook, // TODO: bee_03 spiral_eye when ready
      _ => compassStar,
    };
  }
}