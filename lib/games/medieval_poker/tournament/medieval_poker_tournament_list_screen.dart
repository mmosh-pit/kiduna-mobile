import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../l10n/app_localizations.dart';
import 'tournament_client.dart';
import 'tournament_models.dart';
import 'widgets/tournament_card.dart';

/// Browse tournaments — open for registration, currently running, or done.
///
/// Creating one is deliberately here rather than behind a separate route: with
/// four-player brackets supported, a player who wants a tournament usually
/// wants to start one right now.
class MedievalPokerTournamentListScreen extends StatefulWidget {
  const MedievalPokerTournamentListScreen({
    super.key,
    required this.onOpen,
    this.client,
  });

  /// Called with the tournament the player picked.
  final void Function(String tournamentId) onOpen;

  /// Injected in tests; defaults to the real REST client.
  final TournamentClient? client;

  @override
  State<MedievalPokerTournamentListScreen> createState() =>
      _MedievalPokerTournamentListScreenState();
}

enum _Filter { open, running, finished }

class _MedievalPokerTournamentListScreenState
    extends State<MedievalPokerTournamentListScreen> {
  late final TournamentClient _client = widget.client ?? TournamentClient();

  _Filter _filter = _Filter.open;
  List<TournamentSummary> _tournaments = const [];
  String? _error;
  bool _loading = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _statusParam => switch (_filter) {
    _Filter.open => 'registering',
    _Filter.running => 'running',
    _Filter.finished => 'finished',
  };

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _client.list(status: _statusParam);
      if (!mounted) return;
      setState(() {
        _tournaments = rows;
        _loading = false;
      });
    } on TournamentException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _create(String name, int size) async {
    setState(() => _creating = true);
    try {
      final created = await _client.create(name: name, size: size);
      if (!mounted) return;
      setState(() => _creating = false);
      widget.onOpen(created.tournament.id);
    } on TournamentException catch (e) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _error = e.message;
      });
    }
  }

  Future<void> _openCreateSheet() async {
    final result = await showModalBottomSheet<(String, int)>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _CreateTournamentSheet(),
    );
    if (result != null) await _create(result.$1, result.$2);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      color: colors.field,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.tournamentsLabel,
                      style: text.h4.copyWith(color: colors.gold),
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : _load,
                    icon: Icon(Icons.refresh_rounded, color: colors.gold),
                    tooltip: l10n.retryLabel,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _FilterBar(
                filter: _filter,
                onChanged: (f) {
                  setState(() => _filter = f);
                  _load();
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _body()),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _creating ? null : _openCreateSheet,
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.createTournament),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.gold,
                  foregroundColor: colors.black,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = AppLocalizations.of(context)!;

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: colors.gold));
    }

    // A failure and an empty list are different things — saying "no
    // tournaments yet" when the request actually failed hides the problem.
    if (_error != null) {
      return _ErrorState(message: l10n.couldNotLoadTournaments, onRetry: _load);
    }

    if (_tournaments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 48,
                color: colors.gold.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noTournamentsYet,
                style: text.body.copyWith(color: colors.cream),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.noTournamentsYetDetail,
                textAlign: TextAlign.center,
                style: text.caption.copyWith(color: colors.muted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _tournaments.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TournamentCard(
          tournament: _tournaments[i],
          onTap: () => widget.onOpen(_tournaments[i].id),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.filter, required this.onChanged});

  final _Filter filter;
  final ValueChanged<_Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<_Filter>(
      segments: [
        ButtonSegment(value: _Filter.open, label: Text(l10n.openTournaments)),
        ButtonSegment(
          value: _Filter.running,
          label: Text(l10n.runningTournaments),
        ),
        ButtonSegment(
          value: _Filter.finished,
          label: Text(l10n.finishedTournaments),
        ),
      ],
      selected: {filter},
      showSelectedIcon: false,
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

/// Name + size, the only two things a tournament needs to exist.
class _CreateTournamentSheet extends StatefulWidget {
  const _CreateTournamentSheet();

  @override
  State<_CreateTournamentSheet> createState() => _CreateTournamentSheetState();
}

class _CreateTournamentSheetState extends State<_CreateTournamentSheet> {
  final _name = TextEditingController();
  int _size = 4;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.deep,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: colors.camel.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.createTournament,
              style: text.h5.copyWith(color: colors.gold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              autofocus: true,
              style: text.body.copyWith(color: colors.cream),
              decoration: InputDecoration(
                labelText: l10n.tournamentName,
                labelStyle: text.caption.copyWith(color: colors.muted),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: colors.camel.withValues(alpha: 0.4),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colors.gold),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.tournamentSize,
              style: text.caption.copyWith(color: colors.muted),
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 4, label: Text('4')),
                ButtonSegment(value: 8, label: Text('8')),
                ButtonSegment(value: 16, label: Text('16')),
              ],
              selected: {_size},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _size = s.first),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: colors.gold,
                foregroundColor: colors.black,
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(l10n.createTournament),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop((name, _size));
  }
}

/// Shown when a load genuinely failed, so it never reads as "nothing here".
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: colors.error),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: text.body.copyWith(color: colors.cream),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: colors.gold,
                foregroundColor: colors.black,
              ),
              child: Text(l10n.retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
