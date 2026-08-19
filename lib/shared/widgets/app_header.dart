import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/assets.dart';
import '../../core/extensions/context_extensions.dart';

/// Header ground — rgba(18,12,7,.97) from the design kit `.lab` class.
const Color _headerBg = Color.fromRGBO(18, 12, 7, 0.97);

/// The app's single shared header — Kiduna logo + app name on a warm dark ground.
///
/// Drop `const AppHeader()` at the top of any screen. Never duplicate.
///
/// **Responsive:** logo shrinks slightly on mobile (<600).
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final isMobile = context.isMobile;

    return Container(
      height: 74,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      decoration: BoxDecoration(
        color: _headerBg,
        border: Border(
          bottom: BorderSide(color: colors.camel.withValues(alpha: 0.28)),
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 12),
            blurRadius: 38,
            color: const Color(0xFF0C0703).withValues(alpha: 0.42),
          ),
        ],
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            AppAssets.kidunaLogo,
            width: isMobile ? 118 : 138,
            height: isMobile ? 34 : 40,
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}
