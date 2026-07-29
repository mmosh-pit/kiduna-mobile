import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../config/assets.dart';
import '../../../core/extensions/context_extensions.dart';

// Enamel-core fill values from the prototype `.enamelIcon`; one-off painting
// values, not theme tokens.
const Color _enamelWarm = Color(0xFF5A4028);
const Color _enamelCore = Color(0xFF100B08);

/// Which enamel identity to render.
enum EnamelKind { ecosystem, ki }

/// A celestial-enamel identity medallion — a gold-rimmed disc for a Realm
/// [emblemAsset], or a sky-rimmed disc carrying the Kiduna mark for Ki.
class EnamelIcon extends StatelessWidget {
  const EnamelIcon({
    super.key,
    required this.kind,
    required this.size,
    this.emblemAsset,
  });

  final EnamelKind kind;
  final double size;
  final String? emblemAsset;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final isKi = kind == EnamelKind.ki;
    final rim = isKi ? colors.sky : colors.gold;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [colors.cream.withValues(alpha: 0.1), _enamelWarm],
          stops: const [0, 0.85],
        ),
        border: Border.all(color: rim.withValues(alpha: isKi ? 0.6 : 0.55)),
        boxShadow: [
          BoxShadow(color: rim.withValues(alpha: 0.12), blurRadius: 22),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _enamelCore,
          border: Border.all(color: colors.cream.withValues(alpha: 0.28)),
        ),
        child: ClipOval(
          child: Center(
            child: isKi
                ? SvgPicture.asset(AppAssets.kidunaMark, width: size * 0.6)
                : (emblemAsset == null
                      ? const SizedBox.shrink()
                      : Image.asset(
                          emblemAsset!,
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                        )),
          ),
        ),
      ),
    );
  }
}
