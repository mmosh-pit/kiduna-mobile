/// Screen-size breakpoints in logical pixels.
abstract class Breakpoints {
  const Breakpoints._();

  static const double tablet = 600;
  static const double desktop = 1024;
}

enum ScreenClass { mobile, tablet, desktop }

ScreenClass screenClassForWidth(double width) {
  if (width >= Breakpoints.desktop) {
    return ScreenClass.desktop;
  }
  if (width >= Breakpoints.tablet) {
    return ScreenClass.tablet;
  }
  return ScreenClass.mobile;
}
