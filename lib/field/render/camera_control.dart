/// Camera maths for the Field.
///
/// > **Pan** — Direct 1:1 movement; the Field moves, chrome never does.
/// > **Zoom** — Cursor-centered, continuous, 0.7×–2.4×; labels resolve by
/// > distance.
///
/// — the Design Lab canon, https://www.kiduna.design/ §01
///
/// Pure functions, no Flame and no Flutter, so the behaviour is testable
/// without a running game loop.
library;

import 'dart:math' as math;

import 'package:flame/components.dart';

abstract final class Cam {
  /// Recommended scale range before context changes.
  static const minZoom = 0.7;
  static const maxZoom = 2.4;

  /// One notch of wheel or keyboard zoom.
  static const zoomStep = 1.12;

  /// Pixels moved per keyboard pan tick, at zoom 1.
  static const keyPanPerSecond = 620.0;

  /// How far past the Field's edge the camera may travel, as a fraction of the
  /// viewport. Enough to breathe; not enough to lose the Field entirely.
  static const overscroll = 0.5;

  static double clampZoom(double zoom) =>
      zoom.clamp(minZoom, maxZoom).toDouble();

  /// The viewfinder position that keeps [pointer] over the same world point
  /// while zoom changes from [fromZoom] to [toZoom].
  ///
  /// [position] is the world coordinate displayed at the viewport's top-left
  /// corner, and [pointer] is in screen pixels from that same corner. This is
  /// what makes zoom feel anchored to the cursor rather than to the centre.
  static Vector2 zoomAnchored({
    required Vector2 position,
    required double fromZoom,
    required double toZoom,
    required Vector2 pointer,
  }) {
    final world = position + pointer / fromZoom;
    return world - pointer / toZoom;
  }

  /// Keeps the Field reachable without pinning it rigidly to the viewport.
  ///
  /// [world] is the Field's size in world units; [viewport] the visible size in
  /// screen pixels.
  ///
  /// Slack is always allowed, including at 1× where the Field exactly fits.
  /// An earlier version pinned the camera to centre whenever the Field fitted,
  /// which silently swallowed every pan at rest zoom — the Field looked frozen
  /// and read as broken. Pan must always respond; it just cannot run away.
  static Vector2 clampPosition({
    required Vector2 position,
    required Vector2 world,
    required Vector2 viewport,
    required double zoom,
  }) {
    final visible = viewport / zoom;
    double axis(double value, double worldExtent, double visibleExtent) {
      final slack = visibleExtent * overscroll;
      if (visibleExtent >= worldExtent) {
        // The Field fits: let it move around its centred rest position.
        final centre = (worldExtent - visibleExtent) / 2;
        return value.clamp(centre - slack, centre + slack);
      }
      return value.clamp(-slack, worldExtent - visibleExtent + slack);
    }

    return Vector2(
      axis(position.x, world.x, visible.x),
      axis(position.y, world.y, visible.y),
    );
  }

  /// Pan is 1:1 in screen pixels, so the Field tracks the pointer exactly and
  /// never lags behind it.
  static Vector2 panned({
    required Vector2 position,
    required Vector2 screenDelta,
    required double zoom,
  }) =>
      position - screenDelta / zoom;

  /// Applies a zoom notch [times] steps in [direction] (+1 in, -1 out).
  static double stepZoom(double zoom, double direction, {double times = 1}) =>
      clampZoom(zoom * math.pow(zoomStep, direction * times).toDouble());
}
