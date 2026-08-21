import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;

import 'package:flame/components.dart';

import '../data/field_models.dart';
import '../widgets/nav_mode.dart';
import 'components/motion.dart';
import 'components/star_layer.dart';

class FieldTraverse {
  FieldTraverse(this.nav);

  final NavMode nav;
  int focus = 0;
  int page = 0;

  StarLayer? stars;

  int? travelToFocus;
  StaticStar? _starDestination;
  StaticStar? arrivedStar;
  bool _returning = false;
  double travelT = 0;
  double travelFade = 1;

  bool get isTraveling =>
      travelToFocus != null || _starDestination != null || _returning;

  double get contentFade {
    if (!isTraveling) {
      return 1.0;
    }
    final half = travelT < 0.5 ? travelT * 2 : (1 - travelT) * 2;
    return 1.0 - Verb.easeInOut(half.clamp(0.0, 1.0));
  }

  double get atlasFade {
    if (!isTraveling) {
      return 1.0;
    }
    if (travelT < 0.42) {
      return 1.0 - Verb.easeInOut((travelT / 0.42).clamp(0.0, 1.0));
    }
    if (travelT < 0.58) {
      return 0.0;
    }
    return Verb.easeInOut(((travelT - 0.58) / 0.42).clamp(0.0, 1.0));
  }

  double get starGlow {
    if (!isTraveling) {
      return 0.0;
    }
    if (travelT < 0.12) {
      return Verb.easeInOut((travelT / 0.12).clamp(0.0, 1.0)) * 0.6;
    }
    if (travelT < 0.22) {
      return 0.6;
    }
    if (travelT < 0.48) {
      return 0.6 *
          (1.0 - Verb.easeInOut(((travelT - 0.22) / 0.26).clamp(0.0, 1.0)));
    }
    return 0.0;
  }

  double get starFade {
    if (!isTraveling) {
      return 1.0;
    }
    if (travelT < 0.15) {
      return 1.0;
    }
    if (travelT < 0.48) {
      return 1.0 - Verb.easeInOut(((travelT - 0.15) / 0.33).clamp(0.0, 1.0));
    }
    if (travelT < 0.55) {
      return 0.0;
    }
    return Verb.easeInOut(((travelT - 0.55) / 0.35).clamp(0.0, 1.0));
  }

  double get cameraDrift {
    if (!isTraveling) {
      return 0.0;
    }
    if (travelT < 0.5) {
      return Verb.gather((travelT / 0.5).clamp(0.0, 1.0));
    }
    return 1.0 - Verb.easeOut(((travelT - 0.5) / 0.5).clamp(0.0, 1.0));
  }

  double miniNodeFade(int index, int total) {
    if (!isTraveling) {
      return 1.0;
    }
    if (travelT < 0.52) {
      return 0.0;
    }
    const fadeWindow = 0.48;
    final staggerDelay =
        total > 1 ? (index / (total - 1)) * 0.18 : 0.0;
    final localT = (travelT - 0.52 - staggerDelay) / (fadeWindow - 0.18);
    return Verb.easeOut(localT.clamp(0.0, 1.0));
  }

  double miniNodeSlide(int index, int total) {
    if (!isTraveling) {
      return 0.0;
    }
    if (travelT < 0.52) {
      return 12.0;
    }
    final staggerDelay =
        total > 1 ? (index / (total - 1)) * 0.18 : 0.0;
    final localT = (travelT - 0.52 - staggerDelay) / 0.30;
    return 12.0 * (1.0 - Verb.easeOut(localT.clamp(0.0, 1.0)));
  }

  double miniNodeFadeOut(int index, int total) {
    if (!isTraveling) {
      return 1.0;
    }
    if (travelT > 0.48) {
      return 0.0;
    }
    final reverseIndex = total > 1 ? (total - 1 - index) : 0;
    final staggerDelay =
        total > 1 ? (reverseIndex / (total - 1)) * 0.15 : 0.0;
    final localT = (travelT - staggerDelay) / (0.40 - 0.15);
    return 1.0 - Verb.easeInOut(localT.clamp(0.0, 1.0));
  }

  Vector2? starWorldPosition(Vector2 worldSize) {
    final star = _starDestination;
    if (star == null) {
      return null;
    }
    return Vector2(
      star.fractionX * worldSize.x,
      star.fractionY * worldSize.y,
    );
  }

  List<ClusterDef> activeClusters(FieldSnapshot? snapshot) {
    final all =
        snapshot?.clusters.where((c) => !c.isBranch).toList() ?? const [];
    if (nav != NavMode.traverse || all.length <= clustersPerView) {
      return all;
    }
    final start =
        focus.clamp(0, math.max(0, all.length - clustersPerView)).toInt();
    return all.skip(start).take(clustersPerView).toList();
  }

  List<ClusterDef> distantClusters(FieldSnapshot? snapshot) {
    if (nav != NavMode.traverse) {
      return const [];
    }
    final activeIds = activeClusters(snapshot).map((c) => c.id).toSet();
    return (snapshot?.clusters ?? const <ClusterDef>[])
        .where((c) => !c.isBranch && !activeIds.contains(c.id))
        .toList();
  }

  Rect? activeBounds(FieldSnapshot? snapshot, Vector2 worldSize) {
    if (nav != NavMode.traverse) {
      return null;
    }
    final active = activeClusters(snapshot);
    if (active.isEmpty) {
      return null;
    }
    var rect = _clusterRect(active.first, worldSize);
    for (final c in active.skip(1)) {
      rect = rect.expandToInclude(_clusterRect(c, worldSize));
    }
    return rect.inflate(70);
  }

  Rect _clusterRect(ClusterDef c, Vector2 worldSize) => Rect.fromCenter(
        center: Offset(
          c.left / 100 * worldSize.x,
          c.top / 100 * worldSize.y,
        ),
        width: c.radiusX * 2 / 100 * worldSize.x,
        height: c.radiusY * 2 / 100 * worldSize.y,
      );

  int levelCount(FieldSnapshot? snapshot) {
    final total =
        snapshot?.clusters.where((c) => !c.isBranch).length ?? 0;
    if (total == 0) {
      return 1;
    }
    return ((total - 1) ~/ clustersPerView) + 1;
  }

  int get currentLevel => focus ~/ clustersPerView;

  int pageCount(FieldSnapshot? snapshot) {
    final total = snapshot?.clusters.length ?? 0;
    return total == 0 ? 1 : ((total - 1) ~/ clustersPerPage) + 1;
  }

  bool isCollapsed(double zoom) =>
      nav == NavMode.collapse && zoom < collapseBelowZoom;

  void beginTravel(int targetFocus, FieldSnapshot? snapshot) {
    if (travelToFocus != null) {
      return;
    }
    final all =
        snapshot?.clusters.where((c) => !c.isBranch).length ?? 0;
    final target =
        targetFocus.clamp(0, math.max(0, all - clustersPerView)).toInt();
    if (target == focus) {
      return;
    }
    travelToFocus = target;
    travelT = 0;
  }

  void beginStarTravel(StaticStar star) {
    if (isTraveling) {
      return;
    }
    _starDestination = star;
    travelT = 0;
  }

  void beginReturnTravel() {
    if (isTraveling || arrivedStar == null) {
      return;
    }
    _returning = true;
    travelT = 0;
  }

  void travelTo(ClusterDef cluster, FieldSnapshot? snapshot) {
    final all =
        snapshot?.clusters.where((c) => !c.isBranch).toList() ?? const [];
    final index = all.indexWhere((c) => c.id == cluster.id);
    if (index >= 0) {
      beginTravel(index, snapshot);
    }
  }

  void travelToLevel(int level, FieldSnapshot? snapshot) =>
      beginTravel(level * clustersPerView, snapshot);

  bool onCurrentPage(String clusterId, FieldSnapshot? snapshot) {
    if (nav == NavMode.traverse) {
      return activeClusters(snapshot).any((c) => c.id == clusterId);
    }
    if (nav != NavMode.page) {
      return true;
    }
    final ids = snapshot?.clusters.map((c) => c.id).toList() ?? const [];
    final start = page * clustersPerPage;
    return ids.indexOf(clusterId) >= start &&
        ids.indexOf(clusterId) < start + clustersPerPage;
  }

  Set<String>? visibleClusterIds(FieldSnapshot? snapshot) {
    if (nav == NavMode.traverse) {
      return activeClusters(snapshot).map((c) => c.id).toSet();
    }
    if (nav != NavMode.page) {
      return null;
    }
    final ids = snapshot?.clusters.map((c) => c.id).toList() ?? const [];
    final start = page * clustersPerPage;
    return ids.skip(start).take(clustersPerPage).toSet();
  }

  bool tickTravel(
    double dt,
    Motion motion,
    void Function(int newFocus) onMidpoint,
    void Function() onComplete,
  ) {
    if (!isTraveling) {
      return false;
    }

    final was = travelT;
    travelT += dt / (motion.reduced ? 0.0001 : traverseTravelSeconds);

    if (was < 0.5 && travelT >= 0.5) {
      if (travelToFocus != null) {
        focus = travelToFocus!;
        onMidpoint(travelToFocus!);
      }
      if (_starDestination != null) {
        arrivedStar = _starDestination;
      }
      if (_returning) {
        arrivedStar = null;
        onMidpoint(focus);
      }
    }

    if (travelT >= 1) {
      travelToFocus = null;
      _starDestination = null;
      _returning = false;
      travelT = 0;
      travelFade = 1;
      stars?.opacity = 1;
      onComplete();
      return true;
    }

    final t = travelT;
    final half = t < 0.5 ? t * 2 : (1 - t) * 2;
    final fade = Verb.easeInOut(half.clamp(0.0, 1.0));
    travelFade = 0.06 + 0.94 * (1 - (1 - fade) * (1 - fade));
    stars?.opacity = starFade;
    return false;
  }

  Vector2 worldCentreOf(ClusterDef c, Vector2 worldSize) => Vector2(
        c.left / 100 * worldSize.x,
        c.top / 100 * worldSize.y,
      );
}
