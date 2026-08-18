import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../models/scene_mock_data.dart';
import 'scene_card.dart';

/// Play Store style scene listing — header with create button,
/// category filters, list rows.
class SceneGridView extends StatefulWidget {
  const SceneGridView({
    super.key,
    required this.scenes,
    required this.onSceneTap,
    required this.onCreateTap,
  });

  final List<SceneMockItem> scenes;
  final ValueChanged<SceneMockItem> onSceneTap;
  final VoidCallback onCreateTap;

  @override
  State<SceneGridView> createState() => _SceneGridViewState();
}

class _SceneGridViewState extends State<SceneGridView> {
  String _filter = 'all';

  List<SceneMockItem> get _filtered {
    if (_filter == 'all') return widget.scenes;
    return widget.scenes.where((s) => s.category == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: colors.gold.withValues(alpha: 0.15),
                  ),
                ),
                child: Icon(Icons.grid_view_rounded,
                    size: 17, color: colors.gold),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Garden',
                    style: context.kidunaText.labelStrong.copyWith(
                      color: colors.cream,
                      fontSize: 17,
                    ),
                  ),
                  Text(
                    '${widget.scenes.length} scenes available',
                    style: context.kidunaText.micro.copyWith(
                      color: colors.quiet,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // ── Create button ──
              _CreateButton(onTap: widget.onCreateTap),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // ── Filters ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _FilterChips(
            active: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(height: 1, color: colors.line),
        ),
        const SizedBox(height: 6),
        // ── List ──
        Expanded(
          child: filtered.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => SceneCard(
                    scene: filtered[index],
                    onTap: () => widget.onSceneTap(filtered[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Create Scene button — gold themed, matching header style.
class _CreateButton extends StatefulWidget {
  const _CreateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CreateButton> createState() => _CreateButtonState();
}

class _CreateButtonState extends State<_CreateButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered
                ? colors.gold.withValues(alpha: 0.18)
                : colors.gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered
                  ? colors.gold.withValues(alpha: 0.4)
                  : colors.gold.withValues(alpha: 0.2),
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: colors.gold.withValues(alpha: 0.08),
                      blurRadius: 12,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 16, color: colors.gold),
              const SizedBox(width: 6),
              Text(
                'Create',
                style: context.kidunaText.micro.copyWith(
                  color: colors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Category filter chips.
class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.active, required this.onChanged});

  final String active;
  final ValueChanged<String> onChanged;

  static const _filters = [
    ('all', 'All'),
    ('game', 'Games'),
    ('productivity', 'Productivity'),
    ('wellness', 'Wellness'),
    ('finance', 'Finance'),
    ('lifestyle', 'Lifestyle'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (id, label) in _filters) ...[
            GestureDetector(
              onTap: () => onChanged(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: active == id
                      ? colors.gold.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active == id
                        ? colors.gold.withValues(alpha: 0.3)
                        : colors.line,
                  ),
                ),
                child: Text(
                  label,
                  style: context.kidunaText.micro.copyWith(
                    color: active == id ? colors.gold : colors.muted,
                    fontWeight:
                        active == id ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

/// Empty state.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.apps_rounded, size: 40,
              color: colors.muted.withValues(alpha: 0.3)),
          const SizedBox(height: 10),
          Text('No scenes found',
              style: context.kidunaText.bodySm.copyWith(color: colors.quiet)),
        ],
      ),
    );
  }
}
