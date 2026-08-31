import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'flame/table_renderer.dart';
import 'session/card_zoom.dart';
import 'session/game_session.dart';
import 'session/paced_session.dart';
import 'session/remote_session.dart';
import 'session/session_hud.dart';

/// Full-screen host for an ONLINE Medieval Poker table. Connects a
/// [RemoteSession] to the authoritative game-service and renders it through the
/// shared snapshot [TableRenderer] + [SessionHud]. Empty/dropped seats are
/// filled by server-side AI, so the table plays even with a single human.
class MedievalPokerOnlineScreen extends StatefulWidget {
  /// Base WebSocket URL of the game-service, e.g. `ws://localhost:8080/game`.
  final String wsUrl;
  final String room;
  final int seat;

  /// Humans the service should await before starting (lobby-provided).
  final int? humans;

  /// Lobby-minted game ticket, forwarded on the socket (optional).
  final String? token;

  /// The room's timed-vs-hand-count level mode (from the lobby), if known.
  final bool? timedLevels;

  /// The local player's display name, stamped onto their seat so every player
  /// sees real names instead of "Seat N".
  final String? playerName;

  /// Called when the player exits the game. When the screen is rendered inline
  /// (via onGameLaunch), this replaces Navigator.pop so the parent can switch
  /// views instead of popping the wrong route.
  final VoidCallback? onExit;

  const MedievalPokerOnlineScreen({
    super.key,
    required this.wsUrl,
    this.room = 'default',
    this.seat = 0,
    this.humans,
    this.token,
    this.timedLevels,
    this.playerName,
    this.onExit,
  });

  @override
  State<MedievalPokerOnlineScreen> createState() =>
      _MedievalPokerOnlineScreenState();
}

class _MedievalPokerOnlineScreenState extends State<MedievalPokerOnlineScreen> {
  late final GameSession _session;
  late final TableRenderer _renderer;
  final CardZoomController _cardZoom = CardZoomController();

  @override
  void initState() {
    super.initState();
    // Pace the authoritative snapshot stream so AI-only runs are watchable
    // rather than flashing past; the renderer/HUD bind to the paced session.
    _session = PacedSession(RemoteSession.connect(
      wsUrl: widget.wsUrl,
      room: widget.room,
      seat: widget.seat,
      humans: widget.humans,
      token: widget.token,
      timedLevels: widget.timedLevels,
      name: widget.playerName,
    ));
    // Shared zoom controller: the table (Flame) sets it on a card tap, the HUD
    // renders the enlarged overlay.
    _renderer = TableRenderer(session: _session, cardZoom: _cardZoom);
  }

  @override
  void dispose() {
    _session.dispose();
    _cardZoom.dispose();
    super.dispose();
  }

  void _handleExit() {
    final cb = widget.onExit;
    if (cb != null) {
      cb();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleExit();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: GameWidget<TableRenderer>(
          game: _renderer,
          overlayBuilderMap: {
            'hud': (context, game) => SessionHud(
                session: _session, onExit: _handleExit, cardZoom: _cardZoom),
          },
          initialActiveOverlays: const ['hud'],
        ),
      ),
    );
  }
}
