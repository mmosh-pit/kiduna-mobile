import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/realm_model.dart';
import '../controllers/ecosystem_controller.dart';

class EcosystemPanel extends ConsumerStatefulWidget {
  const EcosystemPanel({super.key});

  @override
  ConsumerState<EcosystemPanel> createState() => _EcosystemPanelState();
}

class _EcosystemPanelState extends ConsumerState<EcosystemPanel> {
  bool _inspectOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ecosystemControllerProvider.notifier).loadEcosystem();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ecoState = ref.watch(ecosystemControllerProvider);

    if (ecoState.isLoading) {
      return const _EcosystemShimmer();
    }

    if (ecoState.error != null) {
      return _EcosystemError(
        message: ecoState.error!,
        onRetry: () {
          ref.read(ecosystemControllerProvider.notifier).loadEcosystem();
        },
      );
    }

    final eco = ecoState.ecosystem;
    if (eco == null) {
      return const _EcosystemEmpty();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RealmContextPill(
          ecosystem: eco,
          inspectOpen: _inspectOpen,
          onInspect: () => setState(() => _inspectOpen = !_inspectOpen),
        ),
        if (_inspectOpen) ...[
          const SizedBox(height: 12),
          _InspectPanel(ecosystem: eco),
        ],
      ],
    );
  }
}

class _RealmContextPill extends StatelessWidget {
  const _RealmContextPill({
    required this.ecosystem,
    required this.inspectOpen,
    required this.onInspect,
  });

  final RealmModel ecosystem;
  final bool inspectOpen;
  final VoidCallback onInspect;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.fromLTRB(0, 6, 7, 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.raised.withValues(alpha: 0.86),
            colors.field.withValues(alpha: 0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.camel.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: colors.gold.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _EnamelEmblem(
            initial: ecosystem.name.isNotEmpty
                ? ecosystem.name.characters.first
                : 'K',
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ECOSYSTEM',
                  style: text.eyebrow.copyWith(
                    color: colors.sky,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ecosystem.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.h2.copyWith(color: colors.cream),
                ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          _InspectToggle(active: inspectOpen, onTap: onInspect),
        ],
      ),
    );
  }
}

const Color _enamelWarm = Color(0xFF5A4028);
const Color _enamelCore = Color(0xFF100B08);

class _EnamelEmblem extends StatelessWidget {
  const _EnamelEmblem({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    const double size = 52;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment(-0.6, -0.8),
                end: Alignment(0.6, 0.8),
                colors: [_enamelWarm, Color(0xFF1B100A)],
                stops: [0, 0.63],
              ),
              border: Border.all(
                color: colors.gold.withValues(alpha: 0.55),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.gold.withValues(alpha: 0.18),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.gold.withValues(alpha: 0.32),
                ),
              ),
            ),
          ),
          ..._studPositions(size, colors.cream),
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _enamelCore,
                border: Border.all(
                  color: colors.cream.withValues(alpha: 0.28),
                ),
              ),
              foregroundDecoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.cream.withValues(alpha: 0.1),
                    const Color(0x00000000),
                  ],
                  stops: const [0, 0.58],
                ),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    fontFamily: 'GoudyHeavyface',
                    fontSize: size * 0.38,
                    color: colors.cream.withValues(alpha: 0.48),
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _studPositions(double size, Color color) {
    const double stud = 4;
    final half = size / 2 - stud / 2;
    final positions = [
      (half, -3.0),
      (size - 1, half),
      (half, size - 1),
      (-3.0, half),
    ];
    return positions.map((pos) {
      return Positioned(
        left: pos.$1,
        top: pos.$2,
        child: Container(
          width: stud,
          height: stud,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.65),
                blurRadius: 5,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _InspectToggle extends StatelessWidget {
  const _InspectToggle({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final tint = active ? colors.sky : colors.cream;

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(Icons.remove_red_eye_outlined, size: 16, color: tint),
      label: Text(
        'Inspect',
        style: text.caption.copyWith(color: tint),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        side: BorderSide(
          color: active
              ? colors.sky.withValues(alpha: 0.42)
              : colors.camel.withValues(alpha: 0.28),
        ),
        shape: const StadiumBorder(),
        backgroundColor: active
            ? colors.sky.withValues(alpha: 0.06)
            : colors.cream.withValues(alpha: 0.035),
      ),
    );
  }
}

class _InspectPanel extends StatelessWidget {
  const _InspectPanel({required this.ecosystem});

  final RealmModel ecosystem;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    final facts = [
      ('HANDLE', '@${ecosystem.handle}'),
      ('STATUS', ecosystem.status.toUpperCase()),
      ('TYPE', ecosystem.type.toUpperCase()),
      ('PURPOSE', ecosystem.purpose ?? '–'),
      ('DESCRIPTION', ecosystem.description ?? '–'),
      ('VISIBILITY', ecosystem.visibility?.toUpperCase() ?? 'PUBLIC'),
      ('MEMBERS', '${ecosystem.memberCount}'),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.raised.withValues(alpha: 0.72),
            colors.field.withValues(alpha: 0.68),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.camel.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 13),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colors.camel.withValues(alpha: 0.14),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ECOSYSTEM',
                  style: text.eyebrowSmall.copyWith(color: colors.gold),
                ),
                const SizedBox(height: 4),
                Text(
                  ecosystem.name,
                  style: text.h2.copyWith(color: colors.cream),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
            child: Text(
              'Select any fact to explore it with Ki',
              style: text.caption.copyWith(color: colors.quiet),
            ),
          ),
          ...facts.map(
            (fact) => _FactRow(label: fact.$1, value: fact.$2),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _FactRow extends StatefulWidget {
  const _FactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  State<_FactRow> createState() => _FactRowState();
}

class _FactRowState extends State<_FactRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: _hovered
              ? colors.sky.withValues(alpha: 0.04)
              : Colors.transparent,
          border: Border(
            top: BorderSide(color: colors.camel.withValues(alpha: 0.1)),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 102,
              child: Text(
                widget.label,
                style: text.eyebrowSmall.copyWith(
                  color: colors.quiet,
                  letterSpacing: 0.7,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.value,
                style: text.body.copyWith(
                  color: _hovered ? colors.sky : colors.cream,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '→',
              style: text.body.copyWith(
                color: _hovered ? colors.sky : colors.quiet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EcosystemEmpty extends StatelessWidget {
  const _EcosystemEmpty();

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.raised.withValues(alpha: 0.86),
            colors.field.withValues(alpha: 0.82),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.camel.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surface.withValues(alpha: 0.5),
              border: Border.all(
                color: colors.camel.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(
              Icons.hub_outlined,
              size: 20,
              color: colors.quiet,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ECOSYSTEM',
                  style: text.eyebrow.copyWith(
                    color: colors.quiet,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No ecosystem found',
                  style: text.body.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EcosystemShimmer extends StatelessWidget {
  const _EcosystemShimmer();

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Container(
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.raised.withValues(alpha: 0.5),
            colors.field.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.camel.withValues(alpha: 0.15)),
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: colors.sky,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

class _EcosystemError extends StatelessWidget {
  const _EcosystemError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.08),
        border: Border.all(color: colors.error.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: colors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: text.body.copyWith(color: colors.muted),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text('Retry', style: text.body.copyWith(color: colors.sky)),
          ),
        ],
      ),
    );
  }
}
