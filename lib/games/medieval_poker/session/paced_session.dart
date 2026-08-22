import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:medieval_poker_engine/protocol.dart';
import 'game_session.dart';

/// A [GameSession] decorator that makes an online table *readable*.
///
/// The authoritative server emits a fresh snapshot after every micro-step, so
/// AI-only runs (opponent actions, board deals, showdown resolution) arrive
/// back-to-back in milliseconds and would blur past. [PacedSession] buffers the
/// wrapped session's `table` snapshots and releases them one at a time, no
/// faster than [minInterval], so each visible change lingers a beat — while:
///
/// - **never delaying the human**: when a `prompt` arrives it flushes the queue
///   to the latest snapshot immediately, so the player always acts on current
///   information;
/// - **fast-forwarding** when it falls too far behind (caps the backlog so the
///   view can't lag the real game indefinitely);
/// - **holding the beat** at a hand's end: the win/lose flash and the game-over
///   panel are withheld until the queued run-out has been shown, then held for
///   [resultHold] so the outcome reads clearly.
///
/// Everything except `table`/`handResult`/`gameOver` passes straight through to
/// the wrapped session. Reusable for any session (e.g. a future LocalSession).
class PacedSession implements GameSession {
  final GameSession _inner;
  final Duration minInterval;
  final Duration resultHold;
  final int backlogCap;
  final DateTime Function() _clock;

  final _table = ValueNotifier<TableSnapshot?>(null);
  final _handResult = ValueNotifier<HandResultView?>(null);
  final _gameOver = ValueNotifier<GameOverView?>(null);

  final List<TableSnapshot> _queue = [];
  HandResultView? _pendingResult;
  GameOverView? _pendingGameOver;

  Timer? _timer;
  DateTime _lastRelease = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _holdUntil = DateTime.fromMillisecondsSinceEpoch(0);
  bool _disposed = false;

  PacedSession(
    this._inner, {
    this.minInterval = const Duration(milliseconds: 350),
    this.resultHold = const Duration(milliseconds: 2400),
    this.backlogCap = 6,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _inner.table.addListener(_onInnerTable);
    _inner.prompt.addListener(_onInnerPrompt);
    _inner.handResult.addListener(_onInnerResult);
    _inner.gameOver.addListener(_onInnerGameOver);
    // Adopt any state already present.
    final t = _inner.table.value;
    if (t != null) _enqueue(t);
  }

  // ── GameSession ──────────────────────────────────────────────────────────
  @override
  int get viewerSeat => _inner.viewerSeat;
  @override
  ValueListenable<SessionPhase> get phase => _inner.phase;
  @override
  ValueListenable<PromptSpec?> get prompt => _inner.prompt;
  @override
  ValueListenable<String> get peek => _inner.peek;
  @override
  ValueListenable<String?> get errorMessage => _inner.errorMessage;
  @override
  ValueListenable<TableSnapshot?> get table => _table;
  @override
  ValueListenable<HandResultView?> get handResult => _handResult;
  @override
  ValueListenable<GameOverView?> get gameOver => _gameOver;

  @override
  void answer(GameActionKind? kind, [Map<String, dynamic> payload = const {}]) =>
      _inner.answer(kind, payload);

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    _inner.table.removeListener(_onInnerTable);
    _inner.prompt.removeListener(_onInnerPrompt);
    _inner.handResult.removeListener(_onInnerResult);
    _inner.gameOver.removeListener(_onInnerGameOver);
    _inner.dispose();
    _table.dispose();
    _handResult.dispose();
    _gameOver.dispose();
  }

  // ── Inner → paced ─────────────────────────────────────────────────────────
  void _onInnerTable() {
    final t = _inner.table.value;
    if (t != null) _enqueue(t);
  }

  void _onInnerPrompt() {
    // A decision is being asked → the player must see the current table now.
    if (_inner.prompt.value != null) _flushTable();
  }

  void _onInnerResult() {
    final r = _inner.handResult.value;
    if (r == null) return;
    _pendingResult = r; // shown once the queued run-out has drained
    _scheduleRelease();
  }

  void _onInnerGameOver() {
    final g = _inner.gameOver.value;
    if (g == null) return;
    _pendingGameOver = g;
    _scheduleRelease();
  }

  // ── Queue mechanics ────────────────────────────────────────────────────────
  void _enqueue(TableSnapshot s) {
    _queue.add(s);
    if (_queue.length > backlogCap) {
      // Fell too far behind → drop stale intermediate frames, keep the recent.
      _queue.removeRange(0, _queue.length - backlogCap);
    }
    _scheduleRelease();
  }

  void _scheduleRelease() {
    if (_disposed || _timer != null) return;
    if (_queue.isEmpty && _pendingResult == null && _pendingGameOver == null) {
      return;
    }
    final now = _clock();
    var earliest = _lastRelease.add(minInterval);
    if (_holdUntil.isAfter(earliest)) earliest = _holdUntil;
    final wait = earliest.difference(now);
    _timer = Timer(wait.isNegative ? Duration.zero : wait, _release);
  }

  void _release() {
    _timer = null;
    if (_disposed) return;

    if (_queue.isNotEmpty) {
      _table.value = _queue.removeAt(0);
      _lastRelease = _clock();
    }

    // Only reveal a hand's outcome once its run-out has finished playing.
    if (_queue.isEmpty) {
      if (_pendingResult != null) {
        _handResult.value = _pendingResult;
        _pendingResult = null;
        _holdUntil = _clock().add(resultHold); // let the flash breathe
      }
      if (_pendingGameOver != null) {
        _gameOver.value = _pendingGameOver;
        _pendingGameOver = null;
      }
    }

    if (_queue.isNotEmpty || _pendingResult != null || _pendingGameOver != null) {
      _scheduleRelease();
    }
  }

  void _flushTable() {
    if (_disposed || _queue.isEmpty) return;
    _timer?.cancel();
    _timer = null;
    _table.value = _queue.removeLast(); // jump to the newest
    _queue.clear();
    _lastRelease = _clock();
    // A pending result/gameOver (if any) can now surface on the next tick.
    if (_pendingResult != null || _pendingGameOver != null) _scheduleRelease();
  }
}
