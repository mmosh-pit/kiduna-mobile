import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../config/kiduna_colors.dart';
import '../../../config/theme.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/realm_model.dart';
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
    this.showHoverDetails = false,
    this.apiRealms = const [],
  });

  final DesignPersona persona;
  final String currentRealmId;
  final String? selectedRealmId;
  final ValueChanged<FieldPlacement>? onSelect;
  final bool showHoverDetails;
  final List<RealmModel> apiRealms;

  @override
  Widget build(BuildContext context) {
    final realms = apiRealms.isNotEmpty
        ? apiRealms.map(atlasRealmFromModel).toList()
        : visibleChildren(currentRealmId, persona);
    final composition = fieldCompositionFor(currentRealmId, persona, realms);
    final colors = context.kiduna;

    if (composition.placements.isEmpty) {
      return Center(child: _EmptyRealmField(colors: colors));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        double dx(double leftPercent) => leftPercent / 100 * size.width;
        double dy(double topPercent) => topPercent / 100 * size.height;

        return Stack(
          clipBehavior: Clip.none,
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
              if (cluster.label.isNotEmpty &&
                  composition.placements.length >= 8)
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
        showHoverDetails: showHoverDetails,
        onTap: onSelect != null ? () => onSelect!(placement) : null,
      ),
    );
  }
}

class _EmptyRealmField extends StatelessWidget {
  const _EmptyRealmField({required this.colors});

  final KidunaColors colors;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.deep.withValues(alpha: 0.72),
            border: Border.all(color: colors.camel.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.noNestedRealmsVisible,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.displayFontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                  color: colors.cream,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                context.l10n.useNavigationOrAskKi,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 10,
                  color: colors.muted,
                ),
              ),
            ],
          ),
        ),
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
    case FieldClusterId.peopleCare:
      return colors.clusterPeopleCare;
    case FieldClusterId.societyJustice:
      return colors.clusterSocietyJustice;
    case FieldClusterId.culturePlay:
      return colors.clusterCulturePlay;
    case FieldClusterId.placePlanet:
      return colors.clusterPlacePlanet;
    case FieldClusterId.workWealth:
      return colors.clusterWorkWealth;
    case FieldClusterId.knowledgeFrontier:
      return colors.clusterKnowledgeFrontier;
    case FieldClusterId.branch:
      return colors.clusterBranch;
  }
}

class _RealmNode extends StatefulWidget {
  const _RealmNode({
    required this.placement,
    required this.crestSize,
    this.selected = false,
    this.showHoverDetails = false,
    this.onTap,
  });

  final FieldPlacement placement;
  final double crestSize;
  final bool selected;
  final bool showHoverDetails;
  final VoidCallback? onTap;

  @override
  State<_RealmNode> createState() => _RealmNodeState();
}

class _RealmNodeState extends State<_RealmNode> {
  bool _hovered = false;

  static const _animDuration = Duration(milliseconds: 260);
  static const _animCurve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final realm = widget.placement.realm;
    final band = widget.placement.band;
    final accent = _clusterColor(widget.placement.cluster, colors);
    final isActive = widget.selected || _hovered;
    final nameColor = isActive
        ? Color.lerp(accent, colors.cream, 0.76)!
        : Color.lerp(accent, colors.cream, 0.42)!;
    final isFar = band == FieldBand.far;
    final showLabels = !isFar || isActive;
    final nameFontSize = band == FieldBand.near ? 12.0 : 10.0;
    final effectiveOpacity = isFar && !isActive ? 0.62 : 1.0;
    final scale = widget.selected ? 1.09 : (_hovered ? 1.04 : 1.0);

    Widget node = GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        opacity: effectiveOpacity,
        duration: _animDuration,
        curve: _animCurve,
        child: AnimatedScale(
          scale: scale,
          duration: _animDuration,
          curve: _animCurve,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: widget.crestSize * 1.2,
                height: widget.crestSize * 1.2,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    if (widget.selected)
                      _SignalPulse(size: widget.crestSize, accent: accent),
                    _CrestOrbit(size: widget.crestSize, accent: accent),
                    if (widget.selected || _hovered)
                      _CrestEdge(size: widget.crestSize, accent: accent),
                    Container(
                      width: widget.crestSize,
                      height: widget.crestSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(
                              alpha: isActive ? 0.7 : 0.42,
                            ),
                            blurRadius: isActive ? 34 : 9,
                          ),
                          if (isActive)
                            BoxShadow(
                              color: accent.withValues(alpha: 0.25),
                              blurRadius: 34,
                            ),
                        ],
                      ),
                      child: ClipOval(
                        child: ColorFiltered(
                          colorFilter: widget.selected
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
                            width: widget.crestSize,
                            height: widget.crestSize,
                            fit: BoxFit.contain,
                            cacheWidth:
                                (widget.crestSize *
                                        MediaQuery.devicePixelRatioOf(context))
                                    .round(),
                            cacheHeight:
                                (widget.crestSize *
                                        MediaQuery.devicePixelRatioOf(context))
                                    .round(),
                          ),
                        ),
                      ),
                    ),
                    _CrestReflection(size: widget.crestSize),
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
                        blurRadius: isActive ? 12 : 8,
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
                    color: isActive ? colors.muted : colors.quiet,
                  ),
                ),
              if (widget.showHoverDetails && (_hovered || widget.selected))
                _HoverFacts(type: realm.type.label, colors: colors),
            ],
          ),
        ),
      ),
    );

    if (widget.showHoverDetails) {
      node = MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: node,
      );
    }

    return node;
  }

}

class _HoverFacts extends StatelessWidget {
  const _HoverFacts({required this.type, required this.colors});

  final String type;
  final KidunaColors colors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(minWidth: 132, maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF130C08).withValues(alpha: 0.96),
        border: Border.all(color: colors.sky.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(7),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.5),
            blurRadius: 34,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            type.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.32,
              color: colors.sky,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Catalyst',
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 8,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.32,
              color: colors.muted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            l10n.allyNoneStationed,
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 8,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.32,
              color: colors.muted,
            ),
          ),
        ],
      ),
    );
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
    if (composition.placements.length < 8) return;

    for (final cluster in composition.clusters) {
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
          ..strokeWidth = 1.5
          ..color = _clusterColor(cluster.id, colors).withValues(alpha: 0.28),
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
