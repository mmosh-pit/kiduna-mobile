import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../game/field_game.dart';

/// The deep Field ground: a warm near-black gradient with sparse living light —
/// stars, nebulae, a distant galaxy, and a comet.
///
/// Rendered by [FieldGame] on the Flame engine. The palette and reduced-motion
/// flag are read from the widget layer and pushed into the game; motion runs on
/// the game loop and is suppressed (loop paused) when the platform requests
/// reduced motion, matching the prototype's `prefers-reduced-motion` behaviour.
class FieldBackground extends StatefulWidget {
  const FieldBackground({super.key});

  @override
  State<FieldBackground> createState() => _FieldBackgroundState();
}

class _FieldBackgroundState extends State<FieldBackground> {
  FieldGame? _game;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final palette = context.kiduna;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final game = _game;
    if (game == null) {
      _game = FieldGame(palette: palette, reduceMotion: reduceMotion);
    } else {
      game
        ..updatePalette(palette)
        ..updateReduceMotion(reduceMotion);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: GameWidget(game: _game!));
  }
}
