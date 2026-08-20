import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/assets.dart';
import '../../core/extensions/context_extensions.dart';

const Color _headerBg = Color.fromRGBO(18, 12, 7, 0.97);

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
