import 'dart:async';

import 'package:flutter/material.dart';

import 'package:medieval_poker_engine/protocol.dart';
import '../chips/chip_display.dart';
import 'card_zoom.dart';
import 'game_session.dart';

const _gold = Color(0xFFEDC169);
const _panel = Color(0xF21B140C);
const _panelBorder = Color(0xFF6B5533);
const _purple = Color(0xFF7A3E9D);
const _teal = Color(0xFF7FD0E0);

// On wide (desktop/web) windows, interactive panels and overlays cap their width
// and center — so buttons don't stretch across the screen — while on phones they
// still fill as before.
const _maxPanelWidth = 560.0;
const _maxOverlayWidth = 700.0;

/// Flutter overlay for an online table. Reads a [GameSession] and renders the
/// banner / stage / pot / log / power-hand from the current [TableSnapshot],
/// maps the active [PromptSpec] to the matching input panel, and answers via
/// [GameSession.answer]. It is transport-agnostic — the same HUD works for any
/// session implementation.
class SessionHud extends StatefulWidget {
  final GameSession session;
  final VoidCallback onExit;

  /// Offline only: restart the match. When null (online) no "Play Again" shows.
  final VoidCallback? onPlayAgain;

  /// Shared card-zoom controller (also driven by the Flame table so tapping a
  /// poker card on the felt zooms too). If null, the HUD owns a private one, so
  /// power-card zoom still works standalone — only table cards need the shared one.
  final CardZoomController? cardZoom;

  final bool isViewer;

  const SessionHud({
    super.key,
    required this.session,
    required this.onExit,
    this.onPlayAgain,
    this.cardZoom,
    this.isViewer = false,
  });

  @override
  State<SessionHud> createState() => _SessionHudState();
}

class _SessionHudState extends State<SessionHud> {
  // Drives the enlarged-card overlay. Tap any card art to zoom; tap to close.
  late final CardZoomController _zoom;
  late final bool _ownZoom;

  GameSession get session => widget.session;
  VoidCallback get onExit => widget.onExit;
  VoidCallback? get onPlayAgain => widget.onPlayAgain;

  @override
  void initState() {
    super.initState();
    _zoom = widget.cardZoom ?? CardZoomController();
    _ownZoom = widget.cardZoom == null;
  }

  @override
  void dispose() {
    if (_ownZoom) _zoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CardZoom(
      controller: _zoom,
      child: ListenableBuilder(
      listenable: Listenable.merge([
        session.phase,
        session.table,
        session.prompt,
        session.handResult,
        session.gameOver,
        session.peek,
        session.errorMessage,
      ]),
      builder: (context, _) {
        final table = session.table.value;
        final prompt = session.prompt.value;
        final over = session.gameOver.value;
        final phase = session.phase.value;

        final isViewer = widget.isViewer;
        final watchingName = isViewer && table != null
            ? table.seats
                .where((s) => s.seat == session.viewerSeat)
                .map((s) => s.name)
                .firstOrNull
            : null;

        return Stack(
          children: [
            _ExitButton(onExit: onExit, isViewer: isViewer),
            if (over == null) ...[
              if (table != null) _StageChip(table: table),
              if (table != null) _EventLog(lines: table.logTail),
              if (!isViewer && table != null && table.yourPowerHand.isNotEmpty)
                _PowerHandFan(cards: table.yourPowerHand),
              if (isViewer)
                _Banner(text: 'Watching ${watchingName ?? 'Player'}')
              else
                _Banner(text: _bannerText(table, prompt)),
              if (!isViewer) _PeekToast(text: session.peek.value),
              if (!isViewer && prompt != null) _promptPanel(context, prompt),
              _HandResultFlash(result: session.handResult.value),
            ],
            if (over != null)
              _GameOver(view: over, onExit: onExit, onPlayAgain: isViewer ? null : onPlayAgain),
            if (over == null && phase != SessionPhase.active)
              _ConnectionOverlay(
                  phase: phase,
                  message: session.errorMessage.value,
                  onExit: onExit),
            if (!isViewer) ...[
              _DeckOverlay(session: session, hidden: over != null),
              _RulesOverlay(hidden: over != null),
            ],
            _CardZoomOverlay(controller: _zoom),
          ],
        );
      },
      ),
    );
  }

  String _bannerText(TableSnapshot? t, PromptSpec? p) {
    if (p != null) {
      return p.kind == PromptKind.bettingAction ? 'Your move' : p.title;
    }
    if (t == null) return '';
    final acting = t.seats.where((s) => s.isActing);
    if (acting.isEmpty) return '';
    final a = acting.first;
    return a.seat == session.viewerSeat ? 'Your move' : '${a.name} is thinking…';
  }

  Widget _promptPanel(BuildContext context, PromptSpec p) {
    switch (p.kind) {
      case PromptKind.bettingAction:
        return _bottom(_ActionBar(spec: p, session: session));
      case PromptKind.setupWindow:
      case PromptKind.roundWindow:
      case PromptKind.showdownWindow:
        return _bottom(_CardChoicePanel(
          title: p.title,
          borderColor: _purple,
          options: p.options,
          dismissLabel: 'Done',
          onPick: (id) => session.answer(GameActionKind.playPower, {'cardId': id}),
          onDismiss: () => session.answer(GameActionKind.pass),
        ));
      case PromptKind.counterWindow:
        return _bottom(_CardChoicePanel(
          title: p.title,
          borderColor: _purple,
          options: p.options,
          dismissLabel: 'Pass',
          onPick: (id) => session.answer(GameActionKind.counter, {'cardId': id}),
          onDismiss: () => session.answer(GameActionKind.pass),
        ));
      case PromptKind.boardCounter:
        return _bottom(_CardChoicePanel(
          title: p.title,
          borderColor: _purple,
          options: p.options,
          dismissLabel: 'Pass',
          onPick: (id) =>
              session.answer(GameActionKind.boardCounter, {'cardId': id}),
          onDismiss: () => session.answer(GameActionKind.pass),
        ));
      case PromptKind.itemPlay:
        return _bottom(_CardChoicePanel(
          title: p.title,
          borderColor: _teal,
          options: p.options,
          dismissLabel: 'Continue',
          onPick: (id) => session.answer(GameActionKind.playItem, {'itemId': id}),
          onDismiss: () => session.answer(GameActionKind.pass),
        ));
      case PromptKind.itemMode:
        return _bottom(_ListChoicePanel(
          title: p.title,
          borderColor: _teal,
          options: p.options,
          onPick: (i) => session.answer(null, {'index': i}),
        ));
      case PromptKind.itemPick:
        return _bottom(_ListChoicePanel(
          title: p.title,
          borderColor: _teal,
          options: p.options,
          optional: p.optional,
          skipLabel: 'None',
          onPick: (i) => session.answer(null, {'index': i}),
          onSkip: () => session.answer(null, {'index': -1}),
        ));
      case PromptKind.targetPick:
        return _bottom(_TargetPanel(
          title: p.title,
          options: p.options,
          onPick: (id) =>
              session.answer(GameActionKind.targetPick, {'seat': int.parse(id)}),
        ));
      case PromptKind.payChoice:
        return _bottom(_PayChoicePanel(
          title: p.title,
          onCoins: () => session.answer(GameActionKind.payChoice, {'useChip': false}),
          onChip: () => session.answer(GameActionKind.payChoice, {'useChip': true}),
        ));
      case PromptKind.chipSell:
        return _bottom(_TwoButtonPanel(
          title: p.title,
          leftLabel: 'Keep',
          rightLabel: 'Sell ◉',
          onLeft: () => session.answer(GameActionKind.sellChip, {'sell': false}),
          onRight: () => session.answer(GameActionKind.sellChip, {'sell': true}),
        ));
      case PromptKind.classPick:
        return _ChoiceOverlay(
          title: 'Choose Your Class',
          subtitle: 'Your class adds cards to your Power Deck.',
          options: p.options,
          onPick: (i) => session.answer(GameActionKind.classPick, {'index': i}),
        );
      case PromptKind.courtPick:
        return _ChoiceOverlay(
          title: 'Choose Your Court',
          subtitle: 'Your Court adds cards to your Power Deck.',
          options: p.options,
          onPick: (i) => session.answer(GameActionKind.courtPick, {'index': i}),
        );
      case PromptKind.deckBuild:
        return _DeckBuilder(
          spec: p,
          onConfirm: (ids) =>
              session.answer(GameActionKind.deckBuild, {'cardIds': ids}),
        );
    }
  }

  Widget _bottom(Widget child) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxPanelWidth),
          child: child,
        ),
      );
}

// ── Card zoom (tap any card art to enlarge; tap anywhere to close) ──────────

/// Exposes the shared [CardZoomController] to card thumbnails deep in the HUD
/// without threading it through every widget. [_ZoomableThumb] looks it up.
class _CardZoom extends InheritedWidget {
  final CardZoomController controller;
  const _CardZoom({required this.controller, required super.child});
  static CardZoomController? maybeOf(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<_CardZoom>()?.controller;
  @override
  bool updateShouldNotify(_CardZoom old) => old.controller != controller;
}

/// A [_PowerThumb] that enlarges its card when tapped (via the [_CardZoom]
/// scope). Falls back to a plain thumb if no scope is present.
class _ZoomableThumb extends StatelessWidget {
  final String id;
  final String title;
  final String? subtitle;
  final double w;
  final double h;
  const _ZoomableThumb({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.w,
    required this.h,
  });

  @override
  Widget build(BuildContext context) {
    final controller = _CardZoom.maybeOf(context);
    final thumb = _PowerThumb(id: id, w: w, h: h);
    if (controller == null) return thumb;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => controller.show(CardZoomTarget(
        assets: [
          'assets/medieval_poker/power/$id.png',
          'assets/medieval_poker/items/$id.png',
        ],
        title: title,
        subtitle: subtitle,
        fallback: '★',
      )),
      child: thumb,
    );
  }
}

/// Full-screen enlarged-card overlay. Shows the tapped card's full face
/// (uncropped) plus its name/description; a tap anywhere dismisses it. Serves
/// both power cards (from the HUD) and poker cards (tapped on the Flame felt).
class _CardZoomOverlay extends StatelessWidget {
  final CardZoomController controller;
  const _CardZoomOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CardZoomTarget?>(
      valueListenable: controller,
      builder: (context, target, _) {
        if (target == null) return const SizedBox.shrink();
        final size = MediaQuery.sizeOf(context);
        final cardW = (size.width * 0.62).clamp(180.0, 300.0);
        final cardH = cardW * 5 / 3; // card art is 3:5
        return Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: controller.clear,
            child: Container(
              color: Colors.black.withValues(alpha: 0.86),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                builder: (context, t, child) => Transform.scale(
                  scale: 0.85 + 0.15 * t.clamp(0.0, 1.0),
                  child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Container(
                        width: cardW,
                        height: cardH,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 30),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: _CardFace(
                              assets: target.assets, fallback: target.fallback),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: cardW + 60),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(target.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontFamily: 'GoudyHeavyface',
                                  fontSize: 22,
                                  color: _gold)),
                          if (target.subtitle != null &&
                              target.subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(target.subtitle!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    height: 1.35)),
                          ],
                          const SizedBox(height: 14),
                          const Text('tap anywhere to close',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The full card face — tries each asset in [assets] (power→item, or a single
/// poker-card art), shown uncropped; if none load, shows [fallback] big.
class _CardFace extends StatelessWidget {
  final List<String> assets;
  final String fallback;
  const _CardFace({required this.assets, required this.fallback});

  @override
  Widget build(BuildContext context) => _tryAsset(0);

  Widget _tryAsset(int i) {
    if (i >= assets.length) {
      return Center(
        child: Text(fallback,
            style: const TextStyle(color: Color(0xFFC79BE6), fontSize: 64)),
      );
    }
    return Image.asset(
      assets[i],
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) => _tryAsset(i + 1),
    );
  }
}

// ── Chrome ────────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  final String text;
  const _Banner({required this.text});
  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    final top = MediaQuery.paddingOf(context).top + 6;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _panelBorder),
          ),
          child: Text(text,
              style: const TextStyle(
                  color: _gold, fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _StageChip extends StatelessWidget {
  final TableSnapshot table;
  const _StageChip({required this.table});
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 4;
    final sudden = table.inSuddenDeath;
    final secs = table.levelSecondsLeft ?? 0;
    final clock = (!sudden && secs > 0)
        ? '  ${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}'
        : '';
    final label = sudden
        ? '⚔ SUDDEN DEATH  ${table.suddenDeathHand}'
        : 'Ante ${table.ante}$clock';
    return Positioned(
      top: top,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: sudden ? const Color(0xFFB3261E) : _panelBorder),
        ),
        child: Text(label,
            style: TextStyle(
                color: sudden ? const Color(0xFFF3A0A0) : _gold,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _EventLog extends StatelessWidget {
  final List<String> lines;
  const _EventLog({required this.lines});
  @override
  Widget build(BuildContext context) {
    final recent = lines.length > 9 ? lines.sublist(lines.length - 9) : lines;
    if (recent.isEmpty) return const SizedBox.shrink();
    final top = MediaQuery.paddingOf(context).top + 42;
    // Half-width on a phone, but capped so it doesn't sprawl on a desktop window.
    final width = (MediaQuery.sizeOf(context).width * 0.5).clamp(0.0, 340.0);
    return Positioned(
      left: 6,
      top: top,
      width: width,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < recent.length; i++)
                Text(recent[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: i == recent.length - 1
                          ? _gold
                          : Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                      height: 1.35,
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeekToast extends StatelessWidget {
  final String text;
  const _PeekToast({required this.text});
  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: const Alignment(0, -0.35),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xF22A1F33),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _purple, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔮  ', style: TextStyle(fontSize: 16)),
            Flexible(
              child: Text(text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFFC79BE6),
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The viewer's Power Card hand, fanned along the bottom.
class _PowerHandFan extends StatelessWidget {
  final List<PowerCardView> cards;
  const _PowerHandFan({required this.cards});

  static const _cardW = 44.0;
  static const _cardH = 66.0;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 66;
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom,
      height: 96,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final n = cards.length;
          final mid = (n - 1) / 2.0;
          final spacing =
              n <= 1 ? 0.0 : ((w - _cardW - 24) / (n - 1)).clamp(16.0, 30.0);
          final center = w / 2;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < n; i++)
                _fanned(cards[i], i - mid, mid == 0 ? 1 : mid, center, spacing),
            ],
          );
        },
      ),
    );
  }

  Widget _fanned(PowerCardView card, double off, double span, double center,
      double spacing) {
    final x = center + off * spacing - _cardW / 2;
    final angle = (off / span) * 0.18;
    final dip = (off * off) / (span * span) * 14.0;
    return Positioned(
      left: x,
      top: 20 + dip,
      child: Transform.rotate(
        angle: angle,
        alignment: Alignment.bottomCenter,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: _ZoomableThumb(
              id: card.templateId,
              title: card.name,
              subtitle: card.description,
              w: _cardW,
              h: _cardH),
        ),
      ),
    );
  }
}

class _HandResultFlash extends StatefulWidget {
  final HandResultView? result;
  const _HandResultFlash({required this.result});
  @override
  State<_HandResultFlash> createState() => _HandResultFlashState();
}

class _HandResultFlashState extends State<_HandResultFlash> {
  Timer? _timer;
  HandResultView? _showing;

  @override
  void didUpdateWidget(covariant _HandResultFlash old) {
    super.didUpdateWidget(old);
    // Every new result shows for a beat then self-dismisses, so the flash is
    // visible even when snapshots arrive back-to-back. Shown to all players —
    // winner, showdown loser, and folder alike — not just the winner.
    if (!identical(widget.result, old.result) && widget.result != null) {
      _showing = widget.result;
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => _showing = null);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = _showing;
    if (r == null) return const SizedBox.shrink();
    final win = r.won;
    final color = win ? const Color(0xFF3FA96A) : const Color(0xFFB3261E);
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, -0.15),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          builder: (context, t, child) => Transform.scale(
            scale: 0.8 + 0.2 * t.clamp(0.0, 1.0),
            child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xF21B140C),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 22),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(win ? '🏆' : '🥀', style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 6),
                Text(
                  win ? 'You Win the Hand' : 'You Lose the Hand',
                  style: TextStyle(
                    fontFamily: 'GoudyHeavyface',
                    fontSize: 26,
                    color: win
                        ? const Color(0xFF7FE0A6)
                        : const Color(0xFFF3A0A0),
                  ),
                ),
                if (r.detail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(r.detail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Input panels ────────────────────────────────────────────────────────

class _ActionBar extends StatefulWidget {
  final PromptSpec spec;
  final GameSession session;
  const _ActionBar({required this.spec, required this.session});
  @override
  State<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends State<_ActionBar> {
  bool _raiseOpen = false;
  double _raiseTo = 0;

  @override
  Widget build(BuildContext context) {
    final s = widget.spec;
    final callAmt = s.callAmount ?? 0;
    final canCheck = callAmt == 0;
    final canRaise = s.canRaise;
    final isBet = callAmt == 0;
    final min = (s.minRaiseTo ?? 0).toDouble();
    final max = (s.maxRaiseTo ?? 0).toDouble();
    final canSlide = max > min;
    final target = _raiseTo.clamp(min, max).round();
    final bottom = MediaQuery.paddingOf(context).bottom + 12;

    void answer(GameActionKind k, [Map<String, dynamic> p = const {}]) =>
        widget.session.answer(k, p);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom, left: 12, right: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_raiseOpen && canRaise)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _panelBorder),
              ),
              child: Row(
                children: [
                  Text('${isBet ? 'Bet' : 'Raise to'}  $target',
                      style: const TextStyle(color: _gold, fontSize: 14)),
                  Expanded(
                    child: Slider(
                      value: target.toDouble().clamp(min, max),
                      min: min,
                      max: max,
                      activeColor: _gold,
                      inactiveColor: Colors.white24,
                      onChanged: canSlide
                          ? (v) => setState(() => _raiseTo = v)
                          : null,
                    ),
                  ),
                  _MiniButton(
                    label: 'Confirm',
                    onTap: () {
                      answer(isBet ? GameActionKind.bet : GameActionKind.raise,
                          {'to': target});
                      setState(() => _raiseOpen = false);
                    },
                  ),
                ],
              ),
            ),
          Row(
            children: [
              if (!canCheck)
                Expanded(
                  child: _ActionButton(
                    label: 'Fold',
                    color: const Color(0xFF7A2E2E),
                    onTap: () => answer(GameActionKind.fold),
                  ),
                ),
              if (!canCheck) const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: canCheck ? 'Check' : 'Call $callAmt',
                  color: const Color(0xFF2E5A44),
                  onTap: () => answer(
                      canCheck ? GameActionKind.check : GameActionKind.call),
                ),
              ),
              if (canRaise) const SizedBox(width: 8),
              if (canRaise)
                Expanded(
                  child: _ActionButton(
                    label: isBet ? 'Bet' : 'Raise',
                    color: const Color(0xFF9A6B1E),
                    onTap: () => setState(() {
                      _raiseOpen = !_raiseOpen;
                      _raiseTo = min;
                    }),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A card-list prompt (power windows, counters, item-play) with a dismiss.
class _CardChoicePanel extends StatelessWidget {
  final String title;
  final Color borderColor;
  final List<PromptOption> options;
  final String dismissLabel;
  final void Function(String id) onPick;
  final VoidCallback onDismiss;
  const _CardChoicePanel({
    required this.title,
    required this.borderColor,
    required this.options,
    required this.dismissLabel,
    required this.onPick,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 12;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom, left: 12, right: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Color(0xFFC79BE6),
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(height: 8),
            for (final o in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _CardTile(option: o, onTap: () => onPick(o.id)),
              ),
            const SizedBox(height: 2),
            _ActionButton(
                label: dismissLabel,
                color: const Color(0xFF2E5A44),
                onTap: onDismiss),
          ],
        ),
      ),
    );
  }
}

/// A plain labelled-list prompt (item modes / picks).
class _ListChoicePanel extends StatelessWidget {
  final String title;
  final Color borderColor;
  final List<PromptOption> options;
  final void Function(int index) onPick;
  final bool optional;
  final String? skipLabel;
  final VoidCallback? onSkip;
  const _ListChoicePanel({
    required this.title,
    required this.borderColor,
    required this.options,
    required this.onPick,
    this.optional = false,
    this.skipLabel,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 12;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom, left: 12, right: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Color(0xFFCFEAF2),
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(height: 8),
            for (int i = 0; i < options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _PlainTile(
                    label: options[i].label, onTap: () => onPick(i)),
              ),
            if (optional && onSkip != null)
              _ActionButton(
                  label: skipLabel ?? 'Skip',
                  color: const Color(0xFF2E5A44),
                  onTap: onSkip!),
          ],
        ),
      ),
    );
  }
}

class _TargetPanel extends StatelessWidget {
  final String title;
  final List<PromptOption> options;
  final void Function(String id) onPick;
  const _TargetPanel(
      {required this.title, required this.options, required this.onPick});
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 12;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom, left: 12, right: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFB3401E)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Color(0xFFF3C0A0),
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(height: 8),
            for (final o in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _TargetTile(option: o, onTap: () => onPick(o.id)),
              ),
          ],
        ),
      ),
    );
  }
}

class _PayChoicePanel extends StatelessWidget {
  final String title;
  final VoidCallback onCoins;
  final VoidCallback onChip;
  const _PayChoicePanel(
      {required this.title, required this.onCoins, required this.onChip});
  @override
  Widget build(BuildContext context) =>
      _TwoButtonPanel(
        title: title,
        leftLabel: 'Pay coins',
        rightLabel: '◉ Comp Chip',
        onLeft: onCoins,
        onRight: onChip,
      );
}

class _TwoButtonPanel extends StatelessWidget {
  final String title;
  final String leftLabel;
  final String rightLabel;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  const _TwoButtonPanel({
    required this.title,
    required this.leftLabel,
    required this.rightLabel,
    required this.onLeft,
    required this.onRight,
  });
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 12;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom, left: 12, right: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _teal),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Color(0xFFCFEAF2),
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _ActionButton(
                        label: leftLabel,
                        color: const Color(0xFF2E5A44),
                        onTap: onLeft)),
                const SizedBox(width: 8),
                Expanded(
                    child: _ActionButton(
                        label: rightLabel,
                        color: const Color(0xFF1E5A6E),
                        onTap: onRight)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen class/court picker.
class _ChoiceOverlay extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<PromptOption> options;
  final void Function(int index) onPick;
  const _ChoiceOverlay({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.onPick,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.78),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: _maxPanelWidth),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _panelBorder, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontFamily: 'GoudyHeavyface',
                      fontSize: 26,
                      color: _gold)),
              const SizedBox(height: 4),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 14),
              for (int i = 0; i < options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TargetTile(
                      option: options[i], onTap: () => onPick(i)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen deck-builder driven by the [PromptSpec] card pool.
class _DeckBuilder extends StatefulWidget {
  final PromptSpec spec;
  final void Function(List<String> cardIds) onConfirm;
  const _DeckBuilder({required this.spec, required this.onConfirm});
  @override
  State<_DeckBuilder> createState() => _DeckBuilderState();
}

class _DeckBuilderState extends State<_DeckBuilder> {
  late final Set<String> _selected;
  int get _target => widget.spec.deckTarget ?? widget.spec.options.length;
  List<PromptOption> get _pool => widget.spec.options;

  @override
  void initState() {
    super.initState();
    _selected = _pool.take(_target).map((c) => c.id).toSet();
  }

  void _toggle(String id) => setState(() {
        if (_selected.contains(id)) {
          _selected.remove(id);
        } else if (_selected.length < _target) {
          _selected.add(id);
        }
      });

  void _autoFill() => setState(() {
        for (final c in _pool) {
          if (_selected.length >= _target) break;
          _selected.add(c.id);
        }
      });

  Widget _groupHeader(String g) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4, left: 4),
        child: Text(g,
            style: const TextStyle(
                color: _gold, fontWeight: FontWeight.w800, fontSize: 13)),
      );

  @override
  Widget build(BuildContext context) {
    final ready = _selected.length == _target;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      color: Colors.black.withValues(alpha: 0.86),
      padding: EdgeInsets.only(top: top + 8, bottom: bottom + 8),
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxOverlayWidth),
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              children: [
                const Text('Build Your Power Deck',
                    style: TextStyle(
                        fontFamily: 'GoudyHeavyface',
                        fontSize: 24,
                        color: _gold)),
                const SizedBox(height: 2),
                Text('Tap cards to add or remove. Choose $_target.',
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final g in const ['Neutral', 'Class', 'Court']) ...[
                  if (_pool.any((c) => c.group == g)) ...[
                    _groupHeader('$g Cards'),
                    for (final c in _pool.where((c) => c.group == g))
                      _DeckRow(
                        option: c,
                        selected: _selected.contains(c.id),
                        atCap: _selected.length >= _target,
                        onTap: () => _toggle(c.id),
                      ),
                  ],
                ],
                if (_pool.any((c) => c.group == null))
                  for (final c in _pool.where((c) => c.group == null))
                    _DeckRow(
                      option: c,
                      selected: _selected.contains(c.id),
                      atCap: _selected.length >= _target,
                      onTap: () => _toggle(c.id),
                    ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: Row(
              children: [
                Text('${_selected.length} / $_target',
                    style: TextStyle(
                        color: ready ? const Color(0xFF7FE0A6) : _gold,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
                const Spacer(),
                if (_selected.length < _target)
                  TextButton(
                    onPressed: _autoFill,
                    child: const Text('Auto-fill',
                        style: TextStyle(color: Color(0xFFC79BE6))),
                  ),
                const SizedBox(width: 6),
                FilledButton(
                  onPressed: ready
                      ? () => widget.onConfirm(_selected.toList())
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white24,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 12),
                  ),
                  child: const Text('Play',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _DeckRow extends StatelessWidget {
  final PromptOption option;
  final bool selected;
  final bool atCap;
  final VoidCallback onTap;
  const _DeckRow({
    required this.option,
    required this.selected,
    required this.atCap,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final dim = !selected && atCap;
    return Opacity(
      opacity: dim ? 0.45 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Material(
          color: selected ? const Color(0xFF2E2140) : const Color(0xFF1B140C),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFC79BE6)
                      : const Color(0xFF4A3A28),
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Row(
                children: [
                  _ZoomableThumb(
                      id: option.id,
                      title: option.label,
                      subtitle: option.subtitle,
                      w: 46,
                      h: 74),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(option.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                            ),
                            if (option.badge != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF33291C),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: _panelBorder),
                                ),
                                child: Text(option.badge!,
                                    style: const TextStyle(
                                        color: _gold, fontSize: 9)),
                              ),
                            ],
                          ],
                        ),
                        if (option.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(option.subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_outline_rounded,
                    color: selected
                        ? const Color(0xFF7FE0A6)
                        : Colors.white38,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tiles / buttons / art ──────────────────────────────────────────────

class _CardTile extends StatelessWidget {
  final PromptOption option;
  final VoidCallback onTap;
  const _CardTile({required this.option, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2A1F33),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _purple),
          ),
          child: Row(
            children: [
              _ZoomableThumb(
                  id: option.id,
                  title: option.label,
                  subtitle: option.subtitle,
                  w: 46,
                  h: 74),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    if (option.subtitle != null)
                      Text(option.subtitle!,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.play_arrow_rounded,
                  color: Color(0xFFC79BE6), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlainTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PlainTile({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E3A4A),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _teal),
          ),
          child: Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
      ),
    );
  }
}

class _TargetTile extends StatelessWidget {
  final PromptOption option;
  final VoidCallback onTap;
  const _TargetTile({required this.option, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF33241C),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFB3401E)),
          ),
          child: Row(
            children: [
              const Icon(Icons.gps_fixed_rounded,
                  color: Color(0xFFF3C0A0), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    if (option.subtitle != null)
                      Text(option.subtitle!,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Power/Item card-art thumbnail (power art → item art → ★ fallback).
class _PowerThumb extends StatelessWidget {
  final String id;
  final double w;
  final double h;
  const _PowerThumb({required this.id, required this.w, required this.h});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(
        'assets/medieval_poker/power/$id.png',
        width: w,
        height: h,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => Image.asset(
          'assets/medieval_poker/items/$id.png',
          width: w,
          height: h,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => SizedBox(
            width: w,
            height: h,
            child: const Center(
              child: Text('★',
                  style: TextStyle(color: Color(0xFFC79BE6), fontSize: 18)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MiniButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: _gold,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(label,
              style: const TextStyle(
                  color: Color(0xFF1B140C), fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

class _GameOver extends StatelessWidget {
  final GameOverView view;
  final VoidCallback onExit;
  final VoidCallback? onPlayAgain;
  const _GameOver({required this.view, required this.onExit, this.onPlayAgain});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      alignment: Alignment.center,
      child: Container(
        constraints: const BoxConstraints(maxWidth: _maxPanelWidth),
        margin: const EdgeInsets.all(28),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _panelBorder, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(view.youWon ? 'Victory' : 'Defeat',
                style: TextStyle(
                    fontFamily: 'GoudyHeavyface',
                    fontSize: 34,
                    color: view.youWon ? _gold : const Color(0xFFB3261E))),
            const SizedBox(height: 12),
            Text(view.detail,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 15)),
            if (view.standings.isNotEmpty) ...[
              const SizedBox(height: 14),
              for (final s in view.standings)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('${s.label}  ·  ',
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ChipDisplay(total: s.stack, chipSize: 16, compact: true),
                  ]),
                ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onPlayAgain != null) ...[
                  _MiniButton(label: 'Play Again', onTap: onPlayAgain!),
                  const SizedBox(width: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: onExit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _panelBorder),
                        ),
                        child: const Text('Leave',
                            style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                  ),
                ] else
                  _MiniButton(label: 'Leave', onTap: onExit),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Self-contained Power Deck viewer: a top-right button plus a full-screen
/// overlay grouping the viewer's own deck (In Hand / Draw Deck / Discard /
/// One-Shot) from the current snapshot. Draw-deck order is hidden server-side.
class _DeckOverlay extends StatefulWidget {
  final GameSession session;
  final bool hidden;
  const _DeckOverlay({required this.session, required this.hidden});
  @override
  State<_DeckOverlay> createState() => _DeckOverlayState();
}

class _DeckOverlayState extends State<_DeckOverlay> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final t = widget.session.table.value;
    final sections = <(String, List<PowerCardView>)>[
      ('In Hand', t?.yourPowerHand ?? const []),
      ('Draw Deck', t?.yourDrawDeck ?? const []),
      ('Discard', t?.yourDiscard ?? const []),
      ('One-Shot', t?.yourOneShot ?? const []),
    ];
    final total = sections.fold<int>(0, (n, s) => n + s.$2.length);

    return Stack(
      children: [
        if (!widget.hidden)
          Positioned(
            top: top + 64,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _open = true),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _panel,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _panelBorder),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🂠', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 5),
                    Text('Deck',
                        style: TextStyle(
                            color: _gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        if (_open)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _open = false),
              child: Container(
                color: Colors.black.withValues(alpha: 0.88),
                padding: EdgeInsets.only(top: top + 8, bottom: bottom + 8),
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: _maxOverlayWidth),
                  child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
                      child: Row(
                        children: [
                          const Text('Your Power Deck',
                              style: TextStyle(
                                  fontFamily: 'GoudyHeavyface',
                                  fontSize: 22,
                                  color: _gold)),
                          const SizedBox(width: 10),
                          Text('$total cards',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 12)),
                          const Spacer(),
                          IconButton(
                            onPressed: () => setState(() => _open = false),
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          for (final s in sections)
                            if (s.$2.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 10, bottom: 4, left: 4),
                                child: Text('${s.$1}  ·  ${s.$2.length}',
                                    style: const TextStyle(
                                        color: _gold,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13)),
                              ),
                              for (final c in s.$2) _DeckViewRow(card: c),
                            ],
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DeckViewRow extends StatelessWidget {
  final PowerCardView card;
  const _DeckViewRow({required this.card});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          _ZoomableThumb(
              id: card.templateId,
              title: card.name,
              subtitle: card.description,
              w: 40,
              h: 60),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(card.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF33291C),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: _panelBorder),
                      ),
                      child: Text(card.timing,
                          style: const TextStyle(color: _gold, fontSize: 9)),
                    ),
                  ],
                ),
                Text(card.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Self-contained Rules reference: a top-right button plus a full-screen,
/// swipeable viewer of the physical reference cards. Placed last in the HUD
/// stack so the viewer overlays everything.
class _RulesOverlay extends StatefulWidget {
  final bool hidden;
  const _RulesOverlay({required this.hidden});
  @override
  State<_RulesOverlay> createState() => _RulesOverlayState();
}

class _RulesOverlayState extends State<_RulesOverlay> {
  bool _open = false;

  static const _pages = [
    ('Hand Rankings', 'assets/medieval_poker/reference/hand_rankings.png'),
    ('Poker Terms', 'assets/medieval_poker/reference/poker_terms.png'),
    ('Game Terms', 'assets/medieval_poker/reference/game_terms.png'),
    ('Abilities', 'assets/medieval_poker/reference/abilities.png'),
  ];

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Stack(
      children: [
        if (!widget.hidden)
          Positioned(
            top: top + 34,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _open = true),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _panel,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _panelBorder),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('❔', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 5),
                    Text('Rules',
                        style: TextStyle(
                            color: _gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        if (_open)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.9),
              padding: EdgeInsets.only(top: top + 8, bottom: bottom + 8),
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxOverlayWidth),
                child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
                    child: Row(
                      children: [
                        const Text('Rules Reference',
                            style: TextStyle(
                                fontFamily: 'GoudyHeavyface',
                                fontSize: 22,
                                color: _gold)),
                        const Spacer(),
                        IconButton(
                          onPressed: () => setState(() => _open = false),
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      itemCount: _pages.length,
                      itemBuilder: (context, i) {
                        final (title, path) = _pages[i];
                        return Column(
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    color: Color(0xFFC79BE6),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Expanded(
                              child: InteractiveViewer(
                                minScale: 1,
                                maxScale: 4,
                                child: Image.asset(path,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => const Center(
                                          child: Text('Reference unavailable',
                                              style: TextStyle(
                                                  color: Colors.white54)),
                                        )),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('Swipe for more  ·  pinch to zoom',
                        style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ),
                ],
              ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ConnectionOverlay extends StatelessWidget {
  final SessionPhase phase;
  final String? message;
  final VoidCallback onExit;
  const _ConnectionOverlay(
      {required this.phase, this.message, required this.onExit});
  @override
  Widget build(BuildContext context) {
    final connecting = phase == SessionPhase.connecting;
    // Prefer a specific server-supplied reason (seat taken, server restart, …)
    // over the generic phase text — but never while actively (re)connecting.
    final specific = (!connecting && message != null && message!.isNotEmpty)
        ? message
        : null;
    final msg = specific ??
        switch (phase) {
          SessionPhase.connecting => 'Connecting to the table…',
          SessionPhase.disconnected => 'Disconnected from the table.',
          SessionPhase.error => 'Could not reach the table.',
          SessionPhase.active => '',
        };
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (connecting)
            const CircularProgressIndicator(color: _gold)
          else
            const Icon(Icons.wifi_off_rounded, color: Colors.white54, size: 40),
          const SizedBox(height: 14),
          Text(msg,
              style: const TextStyle(color: Colors.white70, fontSize: 15)),
          if (!connecting) ...[
            const SizedBox(height: 18),
            _MiniButton(label: 'Leave', onTap: onExit),
          ],
        ],
      ),
    );
  }
}

class _ExitButton extends StatelessWidget {
  final VoidCallback onExit;
  final bool isViewer;
  const _ExitButton({required this.onExit, this.isViewer = false});

  Future<void> _confirmLeave(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _panelBorder, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Leave the game?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'GoudyHeavyface',
                      fontSize: 24,
                      color: _gold)),
              const SizedBox(height: 10),
              const Text(
                "You'll forfeit your seat and your progress in this match.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniButton(
                    label: 'Keep Playing',
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => Navigator.of(context).pop(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _panelBorder),
                        ),
                        child: const Text('Leave',
                            style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (leave == true) onExit();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Positioned(
      top: topPadding + 2,
      left: 4,
      child: GestureDetector(
        onTap: () => isViewer ? onExit() : _confirmLeave(context),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}
