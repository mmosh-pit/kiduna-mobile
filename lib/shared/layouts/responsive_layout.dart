import 'package:flutter/widgets.dart';

import '../../core/utils/responsive.dart';

/// Chooses a builder based on the available width.
///
/// Uses [LayoutBuilder] so it responds to the space it is actually given.
/// [tablet] falls back to [desktop] when omitted.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    required this.desktop,
    this.tablet,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder desktop;
  final WidgetBuilder? tablet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        switch (screenClassForWidth(constraints.maxWidth)) {
          case ScreenClass.desktop:
            return desktop(context);
          case ScreenClass.tablet:
            return (tablet ?? desktop)(context);
          case ScreenClass.mobile:
            return mobile(context);
        }
      },
    );
  }
}
