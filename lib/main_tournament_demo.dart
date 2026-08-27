import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'games/medieval_poker/poker_palette.dart';
import 'games/medieval_poker/tournament/tournament_detail_screen.dart';
import 'games/medieval_poker/tournament/tournament_list_screen.dart';
import 'games/medieval_poker/tournament/tournament_models.dart';
import 'games/medieval_poker/tournament/tournament_rest_source.dart';
import 'games/medieval_poker/tournament/tournament_source.dart';

/// A standalone harness for the tournament screens.
///
/// Not the app — `main.dart` is. This exists so the tournament flow can be run
/// and clicked before it is wired into the app's navigation, against either
/// source behind [TournamentSource]:
///
///   * **Simulated** — [FakeTournamentSource] runs whole tournaments in memory
///     on a real clock, using the same bracket the server uses. No backend.
///   * **Live API** — [RestTournamentSource] against a running backend.
///
/// Run:
///   flutter run -d chrome -t lib/main_tournament_demo.dart
///
/// Point it elsewhere with --dart-define:
///   --dart-define=API_BASE=http://127.0.0.1:6099
///   --dart-define=API_TOKEN=`<jwt>`
const _apiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://127.0.0.1:6099',
);
const _apiToken = String.fromEnvironment('API_TOKEN');

void main() => runApp(const TournamentDemoApp());

enum SourceKind { simulated, live }

class TournamentDemoApp extends StatefulWidget {
  const TournamentDemoApp({super.key});

  @override
  State<TournamentDemoApp> createState() => _TournamentDemoAppState();
}

class _TournamentDemoAppState extends State<TournamentDemoApp> {
  SourceKind _kind = SourceKind.simulated;
  TournamentSource? _source;

  @override
  void initState() {
    super.initState();
    _build();
  }

  void _build() {
    _source?.dispose();
    _source = switch (_kind) {
      SourceKind.simulated => FakeTournamentSource(
        viewerId: 'you',
        tableDuration: const Duration(seconds: 8),
      ),
      SourceKind.live => RestTournamentSource(
        dio: Dio(
          BaseOptions(
            baseUrl: _apiBase,
            headers: _apiToken.isEmpty
                ? null
                : {'Authorization': 'Bearer $_apiToken'},
          ),
        ),
      ),
    };
  }

  @override
  void dispose() {
    _source?.dispose();
    super.dispose();
  }

  void _switchTo(SourceKind kind) {
    if (kind == _kind) return;
    setState(() {
      _kind = kind;
      _build();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kiduna Tournaments',
      theme: ThemeData.dark(useMaterial3: true)
          .copyWith(scaffoldBackgroundColor: const Color(0xFF14100A)),
      home: _Home(
        key: ValueKey(_kind),
        source: _source!,
        kind: _kind,
        onSwitch: _switchTo,
      ),
    );
  }
}

class _Home extends StatelessWidget {
  final TournamentSource source;
  final SourceKind kind;
  final void Function(SourceKind) onSwitch;

  const _Home({
    super.key,
    required this.source,
    required this.kind,
    required this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SourceBar(kind: kind, onSwitch: onSwitch),
        Expanded(
          child: TournamentListScreen(
            source: source,
            viewerId: 'you',
            onOpen: (t) => _open(context, t),
          ),
        ),
      ],
    );
  }

  void _open(BuildContext context, TournamentSummary t) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TournamentDetailScreen(
          source: source,
          tournamentId: t.id,
          viewerId: 'you',
          onEnterTable: (roomCode) {
            // Taking a seat needs the WS handoff, which is not wired yet.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: kPokerPanel,
                content: Text(
                  'Would join room $roomCode — gameplay handoff not wired yet.',
                  style: const TextStyle(color: kPokerGold),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SourceBar extends StatelessWidget {
  final SourceKind kind;
  final void Function(SourceKind) onSwitch;
  const _SourceBar({required this.kind, required this.onSwitch});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0D0A06),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              const Text(
                'SOURCE',
                style: TextStyle(
                  fontFamily: 'IBMPlexSans',
                  fontSize: 10,
                  letterSpacing: 2,
                  color: kPokerMuted,
                ),
              ),
              const SizedBox(width: 12),
              _Pill(
                label: 'Simulated',
                selected: kind == SourceKind.simulated,
                onTap: () => onSwitch(SourceKind.simulated),
              ),
              const SizedBox(width: 8),
              _Pill(
                label: 'Live API',
                selected: kind == SourceKind.live,
                onTap: () => onSwitch(SourceKind.live),
              ),
              const Spacer(),
              if (kind == SourceKind.live)
                Flexible(
                  child: Text(
                    _apiBase,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'IBMPlexSans',
                      fontSize: 10,
                      color: Colors.white30,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? kPokerGold : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? kPokerGold : kPokerPanelBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'IBMPlexSans',
              fontSize: 11,
              color: selected ? kPokerInk : Colors.white60,
            ),
          ),
        ),
      ),
    );
  }
}
