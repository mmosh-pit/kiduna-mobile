import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../medieval_poker_online_screen.dart';
import '../poker_palette.dart';
import '../session/lobby_client.dart';
import 'tournament_detail_screen.dart';
import 'tournament_list_screen.dart';
import 'tournament_models.dart';
import 'tournament_rest_source.dart';
import 'tournament_source.dart';

/// Tournaments, as hosted by the dashboard's Standings tab.
///
/// Owns the [TournamentSource] so it is disposed with the tab, and takes the
/// viewer from the signed-in user rather than a fixture — a table only offers
/// you a seat if the id matches one it seated.
class TournamentsPanel extends ConsumerStatefulWidget {
  const TournamentsPanel({super.key});

  @override
  ConsumerState<TournamentsPanel> createState() => _TournamentsPanelState();
}

class _TournamentsPanelState extends ConsumerState<TournamentsPanel> {
  late final TournamentSource _source;
  late final LobbyClient _lobby;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    // Tournaments live on kinship-backend, which is what authDio points at.
    _source = RestTournamentSource(dio: ApiClient.instance.authDio);
    _lobby = LobbyClient(dio: ApiClient.instance.authDio);
  }

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authControllerProvider).user?.id;

    if (userId == null) {
      return const _SignedOut();
    }

    return TournamentListScreen(
      source: _source,
      viewerId: userId,
      embedded: true,
      onOpen: (t) => _open(context, t, userId),
      // Open what you just scheduled — you are entered in it, so the next
      // thing you want is its countdown.
      onCreated: (t) => _open(context, t, userId),
    );
  }

  void _open(BuildContext context, TournamentSummary t, String userId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TournamentDetailScreen(
          source: _source,
          tournamentId: t.id,
          viewerId: userId,
          onEnterTable: (roomCode) => _takeSeat(context, roomCode),
        ),
      ),
    );
  }

  /// Sits the player down at their tournament table.
  ///
  /// Goes through the lobby's ordinary join: a tournament seat is pre-assigned
  /// with the player's id, and join is idempotent for someone already seated,
  /// so it returns *their* seat rather than claiming an open one. That keeps
  /// tournaments on the same path two-humans play already exercises, instead of
  /// a second way into a table.
  Future<void> _takeSeat(BuildContext context, String roomCode) async {
    if (_joining) return;
    setState(() => _joining = true);
    try {
      final ticket = await _lobby.joinRoom(roomCode);
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MedievalPokerOnlineScreen(
            wsUrl: ticket.wsUrl,
            room: ticket.room.code,
            seat: ticket.seat,
            // Everyone at a tournament table is a human the bracket seated.
            humans: ticket.room.seatCount,
            token: ticket.gameToken,
            timedLevels: ticket.room.timedLevels,
            playerName: _playerName(),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: kPokerPanel,
          content: Text(
            'Could not take your seat: $e',
            style: const TextStyle(color: kPokerDanger, fontFamily: 'Avenir'),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  String? _playerName() {
    final u = ref.read(authControllerProvider).user;
    final name = u?.username ?? u?.name;
    return (name != null && name.isNotEmpty) ? name : null;
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF14100A),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Sign in to enter tournaments.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 15,
              color: Colors.white38,
            ),
          ),
        ),
      ),
    );
  }
}
