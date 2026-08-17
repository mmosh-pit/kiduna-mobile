import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../models/presale_mock_data.dart';
import 'presale_card.dart';

/// Scrollable list of presale cards with status filter chips.
///
/// Cards are sorted by nearest closing time:
///   1. Live presales — nearest endDate first
///   2. Upcoming presales — nearest startDate first
///   3. Completed presales — most recently ended first
///
/// [onPresaleTap] is called when a card is tapped.
class PresaleListView extends StatefulWidget {
  const PresaleListView({super.key, required this.onPresaleTap});

  final ValueChanged<PresaleMockItem> onPresaleTap;

  @override
  State<PresaleListView> createState() => _PresaleListViewState();
}

class _PresaleListViewState extends State<PresaleListView> {
  String _filter = 'all';

  List<PresaleMockItem> get _filtered {
    var list = _filter == 'all'
        ? List<PresaleMockItem>.from(kMockPresales)
        : kMockPresales.where((p) => p.status == _filter).toList();

    // Sort: live first (nearest end), then upcoming (nearest start),
    // then completed (most recent end).
    list.sort((a, b) {
      final aPriority = _statusPriority(a.status);
      final bPriority = _statusPriority(b.status);
      if (aPriority != bPriority) return aPriority.compareTo(bPriority);

      // Within same status, sort by relevant date
      final aDate = a.status == 'upcoming'
          ? DateTime.tryParse(a.startDate)
          : DateTime.tryParse(a.endDate);
      final bDate = b.status == 'upcoming'
          ? DateTime.tryParse(b.startDate)
          : DateTime.tryParse(b.endDate);
      if (aDate == null || bDate == null) return 0;

      // Live/upcoming: nearest first. Completed: most recent first.
      return a.status == 'completed'
          ? bDate.compareTo(aDate)
          : aDate.compareTo(bDate);
    });

    return list;
  }

  static int _statusPriority(String status) {
    switch (status.toLowerCase()) {
      case 'live':
        return 0;
      case 'upcoming':
        return 1;
      case 'completed':
        return 2;
      default:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header + Filters ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Token Presales',
                    style: context.kidunaText.heading.copyWith(
                      color: colors.cream,
                    ),
                  ),
                  const Spacer(),
                  // Live count badge
                  _LiveCountBadge(
                    count: kMockPresales
                        .where((p) => p.status == 'live')
                        .length,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _FilterChips(
                active: _filter,
                onChanged: (f) => setState(() => _filter = f),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // ── List ──
        Expanded(
          child: filtered.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final presale = filtered[index];
                    return PresaleCard(
                      presale: presale,
                      onTap: () => widget.onPresaleTap(presale),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Badge showing count of live presales.
class _LiveCountBadge extends StatelessWidget {
  const _LiveCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    final colors = context.kiduna;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.mint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.mint.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.mint,
              boxShadow: [
                BoxShadow(
                  color: colors.mint.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count Live',
            style: context.kidunaText.micro.copyWith(
              color: colors.mint,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status filter chips with animated selection.
class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.active, required this.onChanged});

  final String active;
  final ValueChanged<String> onChanged;

  static const _filters = [
    ('all', 'All'),
    ('live', 'Live'),
    ('upcoming', 'Upcoming'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Row(
      children: [
        for (final (id, label) in _filters) ...[
          GestureDetector(
            onTap: () => onChanged(id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: active == id
                    ? colors.sky.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: active == id
                      ? colors.sky.withValues(alpha: 0.35)
                      : colors.line,
                ),
              ),
              child: Text(
                label,
                style: context.kidunaText.bodySm.copyWith(
                  color: active == id ? colors.sky : colors.muted,
                  fontWeight: active == id ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}

/// Empty state shown when no presales match the active filter.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.token_outlined,
            size: 48,
            color: colors.muted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No presales found',
            style: context.kidunaText.bodySm.copyWith(color: colors.quiet),
          ),
        ],
      ),
    );
  }
}
