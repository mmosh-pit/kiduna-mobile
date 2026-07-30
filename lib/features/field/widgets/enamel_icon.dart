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
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheSize = (size * dpr).round();
    return Semantics(
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment(-0.6, -0.8),
                  end: Alignment(0.6, 0.8),
                  colors: [_enamelWarm, Color(0xFF1B100A)],
                  stops: [0, 0.63],
                ),
                border: Border.all(
                  color: rim.withValues(alpha: isKi ? 0.6 : 0.55),
                ),
                boxShadow: isKi
                    ? context.shadows.kiEnamelIcon
                    : context.shadows.enamelIcon,
              ),
            ),
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isKi
                        ? colors.sky.withValues(alpha: 0.38)
                        : colors.gold.withValues(alpha: 0.32),
                  ),
                ),
              ),
            ),
            _EnamelStud(
              color: colors.cream,
              size: size,
              position: _StudPos.top,
            ),
            _EnamelStud(
              color: colors.cream,
              size: size,
              position: _StudPos.right,
            ),
            _EnamelStud(
              color: colors.cream,
              size: size,
              position: _StudPos.bottom,
            ),
            _EnamelStud(
              color: colors.cream,
              size: size,
              position: _StudPos.left,
            ),
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _enamelCore,
                  border: Border.all(
                    color: colors.cream.withValues(alpha: 0.28),
                  ),
                ),
                foregroundDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colors.cream.withValues(alpha: 0.1),
                      const Color(0x00000000),
                    ],
                    stops: const [0, 0.58],
                  ),
                ),
                child: ClipOval(
                  child: isKi
                      ? Center(
                          child: SvgPicture.asset(
                            AppAssets.kidunaMark,
                            width: size * 0.6,
                          ),
                        )
                      : (emblemAsset == null
                            ? const SizedBox.shrink()
                            : SizedBox.expand(
                                child: Image.asset(
                                  emblemAsset!,
                                  fit: BoxFit.cover,
                                  cacheWidth: cacheSize,
                                  cacheHeight: cacheSize,
                                  semanticLabel: context.l10n.realmEmblem,
                                ),
                              )),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _StudPos { top, right, bottom, left }

class _EnamelStud extends StatelessWidget {
  const _EnamelStud({
    required this.color,
    required this.size,
    required this.position,
  });

  final Color color;
  final double size;
  final _StudPos position;

  static const double _stud = 4;

  @override
  Widget build(BuildContext context) {
    final half = size / 2 - _stud / 2;
    const edge = 3 - _stud / 2;
    final (double left, double top) = switch (position) {
      _StudPos.top => (half, edge),
      _StudPos.right => (size - 3 - _stud / 2, half),
      _StudPos.bottom => (half, size - 3 - _stud / 2),
      _StudPos.left => (edge, half),
    };
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: _stud,
        height: _stud,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 2),
          ],
        ),
      ),
    );
  }
}
