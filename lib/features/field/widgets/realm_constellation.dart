import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../config/kiduna_colors.dart';
import '../../../config/theme.dart';
import '../../../core/extensions/context_extensions.dart';
import '../data/design_persona.dart';
import '../data/field_composition.dart';
import '../data/realm_atlas.dart';

/// The persona's anchor (Vital) Realm — the target of the gold current-path.
const Map<DesignPersona, String> _vitalRealm = {
  DesignPersona.alice: 'dunaversity',
  DesignPersona.bob: 'service-alliance',
  DesignPersona.carol: 'ceremony-machine',
  DesignPersona.danny: 'confluence-collective',
};

class RealmConstellation extends StatelessWidget {
  const RealmConstellation({
    super.key,
    this.persona = DesignPersona.alice,
    this.currentRealmId = 'kinship-duna',
    this.selectedRealmId,
    this.onSelect,
  });

  final DesignPersona persona;
  final String currentRealmId;
  final String? selectedRealmId;
  final ValueChanged<FieldPlacement>? onSelect;

  @override
  Widget build(BuildContext context) {
    final realms = visibleChildren(currentRealmId, persona);
    final composition = fieldCompositionFor(currentRealmId, persona, realms);
    final colors = context.kiduna;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        double dx(double leftPercent) => leftPercent / 100 * size.width;
        double dy(double topPercent) => topPercent / 100 * size.height;

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ConstellationPainter(
                  composition: composition,
                  colors: colors,
                  currentPathTargetId: _vitalRealm[persona],
                ),
              ),
            ),
            for (final cluster in composition.clusters)
              if (cluster.label.isNotEmpty)
                Positioned(
                  left: dx(cluster.left) - 90,
                  top: dy(cluster.top - cluster.radiusY) - 18,
                  width: 180,
                  child: Text(
                    cluster.label.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: context.kidunaText.eyebrowSmall.copyWith(
                      color: _clusterColor(
                        cluster.id,
                        colors,
                      ).withValues(alpha: 0.85),
                    ),
                  ),
                ),
            for (final placement in composition.placements)
              _positionedNode(context, placement, dx, dy),
          ],
        );
      },
    );
  }

  Widget _positionedNode(
    BuildContext context,
    FieldPlacement placement,
    double Function(double) dx,
    double Function(double) dy,
  ) {
    final crest = _crestSize(placement.band, placement.mass);
    final nodeW = _nodeWidth(placement.band);
    final isSelected = selectedRealmId == placement.realm.id;
    return Positioned(
      left: dx(placement.left) - nodeW / 2,
      top: dy(placement.top) - crest / 2,
      width: nodeW,
      child: _RealmNode(
        placement: placement,
        crestSize: crest,
        selected: isSelected,
        onTap: onSelect != null ? () => onSelect!(placement) : null,
      ),
    );
  }
}

double _crestSize(FieldBand band, int mass) {
  switch (band) {
    case FieldBand.near:
      return 82 + mass * 8;
    case FieldBand.middle:
      return 50 + mass * 6;
    case FieldBand.far:
      return 26 + mass * 3;
  }
}

double _nodeWidth(FieldBand band) {
  switch (band) {
    case FieldBand.near:
      return 152;
    case FieldBand.middle:
      return 118;
    case FieldBand.far:
      return 72;
  }
}

Color _clusterColor(FieldClusterId id, KidunaColors colors) {
  switch (id) {
    case FieldClusterId.formation:
      return colors.sky;
    case FieldClusterId.care:
      return const Color(0xFFCF6F58);
    case FieldClusterId.place:
      return colors.mint;
    case FieldClusterId.culture:
      return const Color(0xFF9A7DE8);
    case FieldClusterId.law:
      return colors.gold;
    case FieldClusterId.branch:
      return const Color(0xFF62A8DF);
  }
}

class _RealmNode extends StatelessWidget {
  const _RealmNode({
    required this.placement,
    required this.crestSize,
    this.selected = false,
    this.onTap,
  });

  final FieldPlacement placement;
  final double crestSize;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final realm = placement.realm;
    final band = placement.band;
    final accent = _clusterColor(placement.cluster, colors);
    final nameColor = selected
        ? Color.lerp(accent, colors.cream, 0.76)!
        : Color.lerp(accent, colors.cream, 0.42)!;
    final badgeSize = _motifBadgeSize(band);
    final isFar = band == FieldBand.far;
    final showLabels = !isFar || selected;
    final nameFontSize = band == FieldBand.near ? 12.0 : 10.0;
    final effectiveOpacity = isFar && !selected ? 0.62 : 1.0;
    final scale = selected ? 1.09 : 1.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: effectiveOpacity,
        child: Transform.scale(
          scale: scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: crestSize * 1.2,
                height: crestSize * 1.2,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    if (selected) _SignalPulse(size: crestSize, accent: accent),
                    _CrestOrbit(size: crestSize, accent: accent),
                    if (selected) _CrestEdge(size: crestSize, accent: accent),
                    Container(
                      width: crestSize,
                      height: crestSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(
                              alpha: selected ? 0.7 : 0.42,
                            ),
                            blurRadius: selected ? 34 : 9,
                          ),
                          if (selected)
                            BoxShadow(
                              color: accent.withValues(alpha: 0.25),
                              blurRadius: 34,
                            ),
                        ],
                      ),
                      child: ClipOval(
                        child: ColorFiltered(
                          colorFilter: selected
                              ? const ColorFilter.matrix(<double>[
                                  1.08,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0,
                                  1.08,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0,
                                  1.08,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0,
                                  1,
                                  0,
                                ])
                              : const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.dst,
                                ),
                          child: Image.asset(
                            'assets/images/realm-emblems/${realm.type.emblemKey}.jpg',
                            width: crestSize,
                            height: crestSize,
                            fit: BoxFit.contain,
                            cacheWidth:
                                (crestSize *
                                        MediaQuery.devicePixelRatioOf(context))
                                    .round(),
                            cacheHeight:
                                (crestSize *
                                        MediaQuery.devicePixelRatioOf(context))
                                    .round(),
                          ),
                        ),
                      ),
                    ),
                    _CrestReflection(size: crestSize),
                    if (realm.motif.isNotEmpty)
                      Positioned(
                        right: (crestSize * 1.2 - crestSize) / 2,
                        bottom:
                            (crestSize * 1.2 - crestSize) / 2 +
                            crestSize * 0.07,
                        child: Container(
                          constraints: BoxConstraints(minWidth: badgeSize),
                          height: badgeSize,
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color.lerp(accent, colors.cream, 0.3)!,
                            ),
                            color: colors.field,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.5),
                                blurRadius: 9,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            realm.motif,
                            style: TextStyle(
                              fontSize: badgeSize * 0.55,
                              height: 1,
                              color: colors.cream,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              if (showLabels)
                Text(
                  realm.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.displayFontFamily,
                    fontSize: nameFontSize,
                    height: 1,
                    fontWeight: FontWeight.w400,
                    color: nameColor,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 2),
                        blurRadius: selected ? 12 : 8,
                      ),
                    ],
                  ),
                ),
              if (showLabels)
                Text(
                  realm.type.label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 7,
                    letterSpacing: 0.56,
                    color: selected ? colors.muted : colors.quiet,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _motifBadgeSize(FieldBand band) {
    switch (band) {
      case FieldBand.near:
        return 18;
      case FieldBand.middle:
        return 15;
      case FieldBand.far:
        return 12;
    }
  }
}

/// Glowing edge ring visible only on the selected crest.
class _CrestEdge extends StatelessWidget {
  const _CrestEdge({required this.size, required this.accent});

  final double size;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 4,
      height: size + 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: context.kiduna.cream.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 10),
        ],
      ),
    );
  }
}

/// Expanding signal pulse that plays while a node is selected.
class _SignalPulse extends StatefulWidget {
  const _SignalPulse({required this.size, required this.accent});

  final double size;
  final Color accent;

  @override
  State<_SignalPulse> createState() => _SignalPulseState();
}

class _SignalPulseState extends State<_SignalPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        final scale = 0.72 + (2.1 - 0.72) * t;
        final opacity = t < 0.72 ? 0.72 * (1 - t / 0.72) : 0.0;
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.accent.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The accent-coloured elliptical orbit ring behind the crest.
class _CrestOrbit extends StatelessWidget {
  const _CrestOrbit({required this.size, required this.accent});

  final double size;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final orbitSize = size * 1.2;
    return Transform.rotate(
      angle: -18 * math.pi / 180,
      child: Transform(
        transform: Matrix4.diagonal3Values(1.0, 0.56, 1.0),
        alignment: Alignment.center,
        child: Container(
          width: orbitSize,
          height: orbitSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: 0.42)),
            boxShadow: [
              BoxShadow(color: accent.withValues(alpha: 0.11), blurRadius: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// A subtle cream reflection arc at the top of the crest.
class _CrestReflection extends StatelessWidget {
  const _CrestReflection({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: (size * 1.2 - size) / 2 + size * 0.09,
      left: (size * 1.2 - size) / 2 + size * 0.20,
      child: Transform.rotate(
        angle: -17 * math.pi / 180,
        child: Opacity(
          opacity: 0.68,
          child: Container(
            width: size * 0.44,
            height: size * 0.24,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.elliptical(100, 100)),
              border: Border(
                top: BorderSide(color: Color.fromRGBO(255, 246, 213, 0.35)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  _ConstellationPainter({
    required this.composition,
    required this.colors,
    required this.currentPathTargetId,
  });

  final FieldComposition composition;
  final KidunaColors colors;
  final String? currentPathTargetId;

  Offset _at(double leftPercent, double topPercent, Size size) =>
      Offset(leftPercent / 100 * size.width, topPercent / 100 * size.height);

  @override
  void paint(Canvas canvas, Size size) {
    for (final cluster in composition.clusters) {
      if (cluster.label.isEmpty) {
        continue;
      }
      final center = _at(cluster.left, cluster.top, size);
      final rect = Rect.fromCenter(
        center: center,
        width: cluster.radiusX / 100 * size.width * 2,
        height: cluster.radiusY / 100 * size.height * 2,
      );
      canvas.drawOval(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = _clusterColor(cluster.id, colors).withValues(alpha: 0.12),
      );
    }

    for (var i = 0; i < composition.placements.length - 1; i++) {
      final a = composition.placements[i];
      final b = composition.placements[i + 1];
      if (a.cluster != b.cluster) {
        continue;
      }
      final start = _at(a.left, a.top, size);
      final end = _at(b.left, b.top, size);
      final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2 - 10);
      canvas.drawPath(
        Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = _clusterColor(a.cluster, colors).withValues(alpha: 0.2),
      );
    }

    FieldPlacement? target;
    for (final placement in composition.placements) {
      if (placement.realm.id == currentPathTargetId) {
        target = placement;
        break;
      }
    }
    if (target != null) {
      final origin = _at(0, 15, size);
      final end = _at(target.left, target.top, size);
      final control = Offset(
        origin.dx + (end.dx - origin.dx) * 0.35,
        end.dy - 40,
      );
      final path = Path()
        ..moveTo(origin.dx, origin.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      _drawDashed(
        canvas,
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = colors.gold.withValues(alpha: 0.7),
      );
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dash = 6.0;
    const gap = 6.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0.0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter oldDelegate) =>
      oldDelegate.composition != composition ||
      oldDelegate.colors != colors ||
      oldDelegate.currentPathTargetId != currentPathTargetId;
}
