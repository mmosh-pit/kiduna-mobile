import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/presale_model.dart';
import 'presale_card.dart';

/// Scrollable list of presale cards with status filter chips.
///
/// Receives data from [ExchangeController] — no internal state for data,
/// only UI filter selection is handled locally.
class PresaleListView extends StatelessWidget {
  const PresaleListView({
    super.key,
    required this.presales,
    required this.isLoading,
    required this.activeFilter,
    required this.onPresaleTap,
    required this.onFilterChanged,
    required this.onRefresh,
    this.error,
    this.loggedInEmail,
    this.onLogout,
  });

  final List<PresaleModel> presales;
  final bool isLoading;
  final String? error;
  final String activeFilter;
  final ValueChanged<PresaleModel> onPresaleTap;
  final ValueChanged<String> onFilterChanged;
  final Future<void> Function() onRefresh;
  final String? loggedInEmail;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final liveCount = presales.where((p) => p.isLive).length;

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
                  if (liveCount > 0) _LiveCountBadge(count: liveCount),
                ],
              ),
              if (loggedInEmail != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 13, color: colors.quiet),
                    const SizedBox(width: 4),
                    Text(
                      loggedInEmail!,
                      style: context.kidunaText.micro.copyWith(
                        color: colors.quiet,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (onLogout != null)
                      GestureDetector(
                        onTap: onLogout,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: colors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Logout',
                            style: context.kidunaText.micro.copyWith(
                              color: colors.error.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              _FilterChips(
                active: activeFilter,
                onChanged: onFilterChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // ── Content ──
        Expanded(child: _buildContent(context)),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final colors = context.kiduna;

    // Error state
    if (error != null && presales.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48,
                color: colors.error.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              error!,
              style: context.kidunaText.bodySm.copyWith(color: colors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRefresh,
              child: Text('Retry',
                  style: TextStyle(color: colors.sky)),
            ),
          ],
        ),
      );
    }

    // Loading state
    if (isLoading && presales.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colors.sky,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Loading presales...',
              style: context.kidunaText.bodySm.copyWith(color: colors.quiet),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (presales.isEmpty) {
      return const _EmptyState();
    }

    // List
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: colors.sky,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: presales.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final presale = presales[index];
          return PresaleCard(
            presale: presale,
            onTap: () => onPresaleTap(presale),
          );
        },
      ),
    );
  }
}

/// Badge showing count of live presales.
class _LiveCountBadge extends StatelessWidget {
  const _LiveCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
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
