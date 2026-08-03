/// Screen-size breakpoints in logical pixels, shared across every Surface.
///
/// The Kiduna Field is a desktop-first design; [desktop] mirrors the prototype's
/// `min-width: 1024px` at and above which the Field–Ki split is shown.
abstract class Breakpoints {
  const Breakpoints._();

  /// At and above this width a tablet arrangement is appropriate.
  static const double tablet = 600;

  /// At and above this width the full desktop Field–Ki split is shown.
  static const double desktop = 1024;
}

/// Coarse screen-size class derived from an available width.
enum ScreenClass { mobile, tablet, desktop }

/// Resolves a [ScreenClass] for a given [width] using [Breakpoints].
ScreenClass screenClassForWidth(double width) {
  if (width >= Breakpoints.desktop) {
    return ScreenClass.desktop;
  }
  if (width >= Breakpoints.tablet) {
    return ScreenClass.tablet;
  }
  return ScreenClass.mobile;
}
