import 'package:flame/game.dart';

import '../../../config/kiduna_colors.dart';
import 'components/comet_component.dart';
import 'components/galaxy_component.dart';
import 'components/ground_component.dart';
import 'components/nebula_component.dart';
import 'components/star_field_component.dart';
import 'components/vignette_component.dart';

/// Flame game that renders the deep Field background — the port of the former
/// `_DeepFieldPainter`.
///
/// Holds the live [palette] and [reduceMotion] flag pushed in from the widget
/// layer, and advances a single normalized [t] over a 16s loop that every
/// component reads. When motion is suppressed the loop is paused so an idle
/// background costs nothing, matching the old `prefers-reduced-motion` path.
class FieldGame extends FlameGame {
  FieldGame({required KidunaColors palette, required bool reduceMotion})
    : _palette = palette,
      _reduceMotion = reduceMotion;

  static const double _loopSeconds = 16;

  KidunaColors _palette;
  bool _reduceMotion;
  double _t = 0;

  /// Palette tokens the components paint with.
  KidunaColors get palette => _palette;

  /// Whether motion is suppressed (platform reduced-motion).
  bool get reduceMotion => _reduceMotion;

  /// Normalized loop position in `[0, 1)`.
  double get t => _t;

  @override
  Future<void> onLoad() async {
    await addAll([
      GroundComponent(),
      NebulaComponent.warm(),
      NebulaComponent.teal(),
      GalaxyComponent(),
      CometComponent(),
      StarFieldComponent(),
      VignetteComponent(),
    ]);
    if (_reduceMotion) {
      pauseEngine();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_reduceMotion) {
      _t = (_t + dt / _loopSeconds) % 1.0;
    }
  }

  /// Updates the palette when the app theme changes.
  void updatePalette(KidunaColors palette) {
    _palette = palette;
  }

  /// Updates the reduced-motion flag; pauses the loop when motion is off and
  /// resumes it when motion is allowed again.
  void updateReduceMotion(bool reduceMotion) {
    if (reduceMotion == _reduceMotion) {
      return;
    }
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _t = 0;
      pauseEngine();
    } else {
      resumeEngine();
    }
  }
}
