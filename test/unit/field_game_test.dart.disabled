import 'dart:ui';

import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kiduna/config/kiduna_colors.dart';
import 'package:kiduna/features/field/game/components/comet_component.dart';
import 'package:kiduna/features/field/game/components/galaxy_component.dart';
import 'package:kiduna/features/field/game/components/ground_component.dart';
import 'package:kiduna/features/field/game/components/nebula_component.dart';
import 'package:kiduna/features/field/game/components/star_field_component.dart';
import 'package:kiduna/features/field/game/components/vignette_component.dart';
import 'package:kiduna/features/field/game/field_game.dart';

FieldGame _game({bool reduceMotion = false}) =>
    FieldGame(palette: KidunaColors.standard, reduceMotion: reduceMotion);

void main() {
  testWithGame<FieldGame>('adds every deep-field layer on load', _game, (
    game,
  ) async {
    expect(game.children.whereType<GroundComponent>().length, 1);
    expect(game.children.whereType<NebulaComponent>().length, 2);
    expect(game.children.whereType<GalaxyComponent>().length, 1);
    expect(game.children.whereType<CometComponent>().length, 1);
    expect(game.children.whereType<StarFieldComponent>().length, 1);
    expect(game.children.whereType<VignetteComponent>().length, 1);
  });

  testWithGame<FieldGame>(
    'advances the loop over time when motion is allowed',
    _game,
    (game) async {
      expect(game.t, 0);
      game.update(8);
      expect(game.t, closeTo(0.5, 1e-9));
      game.update(8);
      expect(game.t, closeTo(0, 1e-9));
    },
  );

  testWithGame<FieldGame>(
    'freezes the loop and pauses when reduced motion is requested',
    () => _game(reduceMotion: true),
    (game) async {
      game.update(8);
      expect(game.t, 0);
      expect(game.paused, isTrue);
    },
  );

  testWithGame<FieldGame>(
    'toggling reduced motion pauses, resets, and resumes the loop',
    _game,
    (game) async {
      game.update(4);
      expect(game.paused, isFalse);

      game.updateReduceMotion(true);
      expect(game.paused, isTrue);
      expect(game.t, 0);

      game.updateReduceMotion(false);
      expect(game.paused, isFalse);
    },
  );

  testWithGame<FieldGame>('updatePalette swaps the active palette', _game, (
    game,
  ) async {
    final KidunaColors next = KidunaColors.standard.copyWith(
      cream: const Color(0xFFFFFFFF),
    );
    game.updatePalette(next);
    expect(game.palette.cream, const Color(0xFFFFFFFF));
  });

  testWithGame<FieldGame>('renders every layer without error', _game, (
    game,
  ) async {
    final PictureRecorder recorder = PictureRecorder();
    game.render(Canvas(recorder));
    recorder.endRecording().dispose();
    expect(game.size.x, 800);
    expect(game.size.y, 600);
  });
}
