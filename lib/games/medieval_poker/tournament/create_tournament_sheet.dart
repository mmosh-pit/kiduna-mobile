import 'package:flutter/material.dart';

import '../poker_palette.dart';
import 'tournament_models.dart';
import 'tournament_source.dart';

/// Schedules a tournament.
///
/// The start time is entered as a delay rather than a wall-clock time, because
/// a tournament starts on a clock and the only thing that matters when creating
/// one is how long people have to enter. Absolute times bring time zones with
/// them for no gain here.
class CreateTournamentSheet extends StatefulWidget {
  final TournamentSource source;

  const CreateTournamentSheet({super.key, required this.source});

  /// Opens the sheet and returns the created tournament, or null if cancelled.
  static Future<TournamentDetail?> show(
    BuildContext context,
    TournamentSource source,
  ) {
    return showModalBottomSheet<TournamentDetail>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateTournamentSheet(source: source),
    );
  }

  @override
  State<CreateTournamentSheet> createState() => _CreateTournamentSheetState();
}

class _CreateTournamentSheetState extends State<CreateTournamentSheet> {
  final _name = TextEditingController(text: 'New Tournament');
  int _startsInMinutes = 5;
  int _maxTables = 4;
  int _seatsPerTable = 4;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  int get _capacity => _maxTables * _seatsPerTable;

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give it a name.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final created = await widget.source.create(
        name: name,
        startsAt: DateTime.now().add(Duration(minutes: _startsInMinutes)),
        maxTables: _maxTables,
        seatsPerTable: _seatsPerTable,
      );
      if (mounted) Navigator.of(context).pop(created);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF14100A),
          border: Border(top: BorderSide(color: kPokerPanelBorder, width: 1.5)),
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kPokerPanelBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Schedule a tournament',
                style: TextStyle(
                  fontFamily: 'GoudyHeavyface',
                  fontSize: 24,
                  color: kPokerGold,
                ),
              ),
              const SizedBox(height: 18),

              const _Label('Name'),
              const SizedBox(height: 6),
              TextField(
                controller: _name,
                style: const TextStyle(
                  fontFamily: 'Avenir',
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: kPokerPanel,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: kPokerPanelBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: kPokerGold),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              const _Label('Starts in'),
              const SizedBox(height: 6),
              _Choices<int>(
                values: const [1, 5, 15, 30, 60],
                selected: _startsInMinutes,
                labelOf: (m) => m < 60 ? '$m min' : '1 hr',
                onChanged: (v) => setState(() => _startsInMinutes = v),
              ),
              const SizedBox(height: 18),

              const _Label('Tables'),
              const SizedBox(height: 6),
              _Choices<int>(
                values: const [2, 3, 4],
                selected: _maxTables,
                labelOf: (n) => '$n',
                onChanged: (v) => setState(() => _maxTables = v),
              ),
              const SizedBox(height: 18),

              const _Label('Seats per table'),
              const SizedBox(height: 6),
              _Choices<int>(
                // A table cannot seat fewer than the tables it must absorb —
                // every table sends one winner to the final, so the final needs
                // a seat for each.
                values: const [2, 3, 4],
                selected: _seatsPerTable,
                labelOf: (n) => '$n',
                onChanged: (v) => setState(() {
                  _seatsPerTable = v;
                  if (_maxTables > v) _maxTables = v;
                }),
              ),
              const SizedBox(height: 16),

              Text(
                'Seats up to $_capacity players. Starts on the clock with '
                'whoever is present — 2 is enough to run, and tables go '
                'short-handed rather than waiting.',
                style: const TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 12.5,
                  height: 1.45,
                  color: Colors.white38,
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 13,
                    color: kPokerDanger,
                  ),
                ),
              ],

              const SizedBox(height: 20),
              Material(
                color: kPokerGold,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _busy ? null : _create,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    alignment: Alignment.center,
                    child: Text(
                      _busy ? 'Scheduling…' : 'Schedule',
                      style: const TextStyle(
                        fontFamily: 'Avenir',
                        fontWeight: FontWeight.w800,
                        color: kPokerInk,
                      ),
                    ),
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontFamily: 'IBMPlexSans',
      fontSize: 10.5,
      letterSpacing: 1.8,
      color: kPokerMuted,
    ),
  );
}

class _Choices<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  const _Choices({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          Material(
            color: v == selected ? kPokerGold : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onChanged(v),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: v == selected ? kPokerGold : kPokerPanelBorder,
                  ),
                ),
                child: Text(
                  labelOf(v),
                  style: TextStyle(
                    fontFamily: 'Avenir',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: v == selected ? kPokerInk : Colors.white60,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
