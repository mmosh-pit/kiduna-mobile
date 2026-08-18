import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../data/field_models.dart';
import '../../data/placement.dart';
import '../enamel_tokens.dart';
import '../field_typography.dart';
import 'motion.dart';

class RealmNodeMetrics {
  const RealmNodeMetrics(
    this.crest,
    this.nameSize,
    this.typeSize,
    this.showType,
    this.showName,
    this.bloomAlpha,
    this.showRim,
  );

  final double crest;
  final double nameSize;
  final double typeSize;
  final bool showType;
  final bool showName;
  final double bloomAlpha;
  final bool showRim;

  static const _byGravity = {
    Gravity.vital: RealmNodeMetrics(84, 13, 11, true, true, 0.24, true),
    Gravity.central: RealmNodeMetrics(64, 12, 10, true, true, 0.10, true),
    Gravity.relevant: RealmNodeMetrics(40, 10, 9, false, true, 0.0, true),
    Gravity.available: RealmNodeMetrics(24, 8, 0, false, false, 0.0, true),
    Gravity.quiet: RealmNodeMetrics(10, 0, 0, false, false, 0.0, false),
  };

  static RealmNodeMetrics of(Gravity gravity) => _byGravity[gravity]!;
}

class RealmPaintCache {
  late double r;
  late Offset centre;
  late Rect crestRect;
  late Paint bloomPaint;
  late Paint corePaint;
  late Paint rimPaint;
  late Paint innerRimPaint;
  late Paint highlightPaint;
  late Paint studFill;
  late Paint studRim;
  late Paint rolePaint;
  late Paint selectionPaint;
  late TextPainter namePainter;
  late TextPainter typePainter;
  TextPainter? motifPainter;
  late TextPainter _hoverType, _hoverName, _hoverMeta;
  TextPainter? _hoverPurpose;

  void build(
    RealmNodeMetrics metrics,
    Placement placement,
    Vector2 nodeSize,
  ) {
    r = metrics.crest / 2;
    centre = Offset(nodeSize.x / 2, r + 2);
    crestRect = Rect.fromCircle(center: centre, radius: r);
    final accent = placement.cluster.accent;
    final bandOpacity = placement.gravity.opacity;

    bloomPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withValues(alpha: metrics.bloomAlpha * bandOpacity),
          const Color(0x00000000),
        ],
      ).createShader(Rect.fromCircle(center: centre, radius: r * 1.5));

    if (metrics.showRim) {
      corePaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          colors: [
            Enamel.raisedWarmSurface.withValues(alpha: bandOpacity),
            Enamel.deepEspresso.withValues(alpha: bandOpacity),
          ],
        ).createShader(crestRect);
    } else {
      corePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Enamel.cream.withValues(alpha: 0.25),
            const Color(0x00000000),
          ],
        ).createShader(Rect.fromCircle(center: centre, radius: r))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    }

    rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = placement.realm.fixture ? 0.8 : 1.4
      ..color = accent.withValues(
        alpha: (placement.realm.fixture ? 0.42 : 0.86) * bandOpacity,
      );

    innerRimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = Enamel.sunGold.withValues(alpha: 0.30 * bandOpacity);

    highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Enamel.cream.withValues(alpha: 0.16 * bandOpacity);

    studFill = Paint()..color = Enamel.deepEspresso.withValues(alpha: 0.96);

    studRim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = accent.withValues(alpha: 0.78 * bandOpacity);

    rolePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = Enamel.sunGold.withValues(alpha: 0.22 * bandOpacity);

    selectionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Enamel.cream.withValues(alpha: 0.72);

    final namePaint = TextPaint(
      style: TextStyle(
        fontFamily: Type.realmName.fontFamily,
        fontSize: metrics.nameSize,
        height: 1.15,
        color: Color.lerp(accent, Enamel.cream, 0.30)!
            .withValues(alpha: bandOpacity),
        shadows: const [
          Shadow(color: Enamel.deepEspresso, blurRadius: 4),
          Shadow(color: Enamel.deepEspresso, blurRadius: 8),
        ],
      ),
    );
    final typePaint = TextPaint(
      style: TextStyle(
        fontFamily: Type.operational.fontFamily,
        fontWeight: FontWeight.w300,
        fontSize: metrics.typeSize,
        letterSpacing: 0.9,
        color: Enamel.camel.withValues(alpha: bandOpacity * 0.82),
        shadows: const [Shadow(color: Enamel.deepEspresso, blurRadius: 4)],
      ),
    );
    final motifTextPaint = TextPaint(
      style: TextStyle(
        fontFamily: 'Motif',
        fontSize: metrics.crest * 0.17,
        color: Enamel.cream.withValues(alpha: bandOpacity * 0.9),
      ),
    );
    final maxChars = metrics.nameSize > 0
        ? (nodeSize.x / (metrics.nameSize * 0.52)).floor()
        : 0;
    var name = placement.realm.name;
    if (name.length > maxChars && maxChars > 0) {
      name = '${name.substring(0, (maxChars - 1).clamp(1, name.length))}…';
    }

    namePainter = namePaint.toTextPainter(name);
    final typeLevel =
        '${placement.realm.typeName.toUpperCase()} · ${placement.gravity.label.toUpperCase()}';
    typePainter = typePaint.toTextPainter(typeLevel);
    motifPainter = placement.realm.motif.isEmpty
        ? null
        : motifTextPaint.toTextPainter(placement.realm.motif);
    _hoverType = TextPainter(
      text: TextSpan(
        text: typeLevel,
        style: TextStyle(
          fontFamily: Type.eyebrow.fontFamily,
          fontWeight: FontWeight.w800,
          fontSize: 8,
          letterSpacing: 1.4,
          color: accent,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    _hoverName = TextPainter(
      text: TextSpan(
        text: placement.realm.name,
        style: TextStyle(
          fontFamily: Type.realmName.fontFamily,
          fontSize: 12,
          height: 1.2,
          color: Color.lerp(accent, Enamel.cream, 0.30)!,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 140);
    final purpose = placement.realm.purpose;
    _hoverPurpose = purpose.isEmpty
        ? null
        : (TextPainter(
            text: TextSpan(
              text: purpose,
              style: TextStyle(
                fontFamily: Type.body.fontFamily,
                fontSize: 9.5,
                height: 1.3,
                color: Enamel.cream.withValues(alpha: 0.50),
              ),
            ),
            textDirection: TextDirection.ltr,
            maxLines: 2,
            ellipsis: '…',
          )..layout(maxWidth: 140));
    final meta = '${placement.role.label}'
        '${placement.ally != null ? ' · ${placement.ally!.name}' : ''}';
    _hoverMeta = TextPainter(
      text: TextSpan(
        text: meta,
        style: TextStyle(
          fontFamily: Type.body.fontFamily,
          fontSize: 9,
          height: 1.3,
          color: Enamel.camel.withValues(alpha: 0.82),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  void paintCrest(
    Canvas canvas,
    Placement placement,
    Sprite emblem,
    Motion motion,
    int index,
    bool selected,
    RealmNodeMetrics metrics,
  ) {
    if (metrics.bloomAlpha > 0) {
      canvas.drawCircle(centre, r * 1.5, bloomPaint);
    }
    canvas.drawCircle(centre, r, corePaint);

    if (metrics.showRim) {
      if (placement.realm.fixture) {
        const segments = 12;
        const sweep = math.pi * 2 / segments;
        for (var i = 0; i < segments; i++) {
          canvas.drawArc(crestRect, i * sweep, sweep * 0.55, false, rimPaint);
        }
      } else {
        canvas.drawCircle(centre, r, rimPaint);
        canvas.drawCircle(centre, r - 3, innerRimPaint);
      }
    }

    if (metrics.showRim) {
      final emblemSize = r * 1.44;
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: centre, radius: r - 2)),
      );
      emblem.render(
        canvas,
        position: Vector2(
          centre.dx - emblemSize / 2,
          centre.dy - emblemSize / 2,
        ),
        size: Vector2.all(emblemSize),
        overridePaint: Paint()
          ..colorFilter = ColorFilter.mode(
            const Color(0xFFFFFFFF)
                .withValues(alpha: placement.gravity.opacity),
            BlendMode.modulate,
          ),
      );
      canvas.restore();
    }

    if (placement.gravity.level >= 2 && placement.role != Role.guest) {
      final t = Verb.cycle(
        motion.elapsed,
        Verb.roleOrbitPeriod,
        phase: index * -2.1,
      );
      canvas.save();
      canvas.translate(centre.dx, centre.dy);
      canvas.rotate(Verb.roleOrbitTilt * math.pi / 180);
      canvas.scale(1, Verb.roleOrbitFlatten);
      canvas.drawCircle(Offset.zero, r * 1.22, rolePaint);
      final angle = t * math.pi * 2;
      canvas.drawCircle(
        Offset(math.cos(angle) * r * 1.22, math.sin(angle) * r * 1.22),
        1.7,
        Paint()
          ..color = Enamel.sunGold.withValues(
            alpha: 0.62 * placement.gravity.opacity,
          ),
      );
      canvas.restore();
    }

    if (selected) {
      canvas.drawCircle(centre, r + 3, selectionPaint);
    }

    if (metrics.showRim) {
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: r - 1),
        3.6,
        1.5,
        false,
        highlightPaint,
      );
    }

    final motif = motifPainter;
    if (motif != null && placement.gravity.level >= 2) {
      final stud = Offset(
        centre.dx + r * 0.70,
        centre.dy + r * 0.70,
      );
      final studR = (r * 2) * 0.155;
      canvas.drawCircle(stud, studR, studFill);
      canvas.drawCircle(stud, studR, studRim);
      motif.paint(
        canvas,
        Offset(stud.dx - motif.width / 2, stud.dy - motif.height / 2),
      );
    }
  }

  void paintLabel(
    Canvas canvas,
    RealmNodeMetrics metrics,
    Vector2 nodeSize,
    bool showType,
    bool isHovered,
    Color accent,
  ) {
    var y = centre.dy + r + 7;
    final showOnHover = !metrics.showName && isHovered && metrics.nameSize > 0;
    if (!metrics.showName && !showOnHover) return;

    if (showType || (metrics.showType && metrics.showName)) {
      typePainter.paint(
        canvas,
        Offset(nodeSize.x / 2 - typePainter.width / 2, y),
      );
      y += metrics.typeSize * 1.35;
    }

    namePainter.paint(
      canvas,
      Offset(nodeSize.x / 2 - namePainter.width / 2, y),
    );

    if (isHovered) {
      const px = 10.0;
      const py = 7.0;
      const cw = 160.0;
      const gap = 3.0;
      var ch = _hoverType.height + _hoverName.height
          + _hoverMeta.height + gap * 3;
      if (_hoverPurpose != null) ch += _hoverPurpose!.height + gap;
      final rect = Rect.fromLTWH(
        nodeSize.x / 2 - cw / 2, y + 20, cw, ch + py * 2,
      );
      final rrect = RRect.fromRectAndRadius(
        rect, const Radius.circular(6),
      );
      canvas.drawRRect(
        rrect,
        Paint()..color = Enamel.warmSurface.withValues(alpha: 0.96),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = accent.withValues(alpha: 0.40),
      );
      var cy = rect.top + py;
      _hoverType.paint(canvas, Offset(rect.left + px, cy));
      cy += _hoverType.height + gap;
      _hoverName.paint(canvas, Offset(rect.left + px, cy));
      cy += _hoverName.height + gap;
      if (_hoverPurpose != null) {
        _hoverPurpose!.paint(canvas, Offset(rect.left + px, cy));
        cy += _hoverPurpose!.height + gap;
      }
      canvas.drawCircle(
        Offset(rect.left + px + 4, cy + _hoverMeta.height / 2),
        3,
        Paint()..color = Enamel.mint,
      );
      _hoverMeta.paint(canvas, Offset(rect.left + px + 12, cy));
    }
  }
}
