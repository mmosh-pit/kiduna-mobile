import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/assets.dart';
import '../../core/extensions/context_extensions.dart';

// Header ground (prototype `.lab` — rgba(18,12,7,.97)); a one-off chrome value,
// not a theme token.
const Color _headerBg = Color.fromRGBO(18, 12, 7, 0.97);

/// The app's top bar — the Kiduna logo on a warm dark ground.
///
/// A shared, page-agnostic header meant to sit at the top of any screen. It
/// carries no feature-specific state, so every surface can reuse it directly.
/// (The prototype's Design Lab selectors — Surface/View/Persona/Stories/
/// Download — are intentionally omitted: the app ships a single View.)
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _headerBg,
        border: Border(
          bottom: BorderSide(
            color: context.kiduna.camel.withValues(alpha: 0.28),
          ),
        ),
      ),
      child: SvgPicture.asset(AppAssets.kidunaLogo, width: 138, height: 40),
    );
  }
}
