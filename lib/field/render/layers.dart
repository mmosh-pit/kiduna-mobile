/// Render order for the Field.
///
/// The Design Lab canon gives this to us directly:
///
/// > **Ground → geometry → connection → object → signal**
///
/// — https://www.kiduna.design/ §01, "Composition order"
///
/// Note the singular in the last layer: *one* active glint or enamel pulse
/// reveals change, not many.
library;

import 'package:flame/components.dart';

import '../models.dart';

abstract final class Layer {
  /// Deep umber lacquer. No decorative wash, no grid.
  static const ground = 0;

  /// Quiet orbital scaffolding — the cluster halos that establish gravity.
  static const geometry = 10;

  /// Semantic paths joining anchored points. Never decorative.
  static const connection = 20;

  /// Ally, Realm, Element or Talisman occupying the Field.
  static const object = 30;

  /// One active glint or enamel pulse. Phase 4 lights this up.
  static const signal = 40;
}

/// Percent-of-Field → local pixels.
///
/// The mapping is **non-uniform**: `left` is a percentage of width and `top` a
/// percentage of height, exactly as the reference positions absolute elements
/// inside its container. Node *sizes* stay in fixed pixels and never stretch
/// with it — only the camera scales them, uniformly.
Vector2 project(FieldPoint point, Vector2 size) => Vector2(
      point.left / 100 * size.x,
      point.top / 100 * size.y,
    );
