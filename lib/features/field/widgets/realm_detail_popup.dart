import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/logger.dart';
import '../../../data/services/gravity_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/field_controller.dart';
import '../data/placement.dart';

String _gravityLabel(BuildContext context, int level) {
  final l10n = context.l10n;
  return switch (level) {
    1 => l10n.gravityQuiet,
    2 => l10n.gravityAvailable,
    3 => l10n.gravityRelevant,
    4 => l10n.gravityCentral,
    5 => l10n.gravityVital,
    _ => l10n.gravityRelevant,
  };
}

class RealmDetailPopup extends ConsumerWidget {
  const RealmDetailPopup({
    super.key,
    required this.placement,
    required this.onClose,
    required this.onEnter,
    required this.onAtlasReload,
  });

  final Placement placement;
  final VoidCallback onClose;
  final VoidCallback onEnter;
  final VoidCallback onAtlasReload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.kiduna;
    final realm = placement.realm;
    final accent = placement.cluster.accent;
    final level = placement.gravity.level;

    return Container(
      constraints: const BoxConstraints(maxWidth: 540),
      decoration: BoxDecoration(
        color: colors.deep.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.5),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            typeName: realm.typeName,
            levelLabel: _gravityLabel(context, level),
            name: realm.name,
            accent: accent,
            onClose: onClose,
          ),
          if (realm.reason != null && realm.reason!.isNotEmpty)
            _WhySection(reason: realm.reason!, accent: accent),
          _ActionRow(onEnter: onEnter),
          const _DoorRow(),
          _LevelFooter(
            level: level,
            realmId: realm.id,
            realmName: realm.name,
            accent: accent,
            onClose: onClose,
            onAtlasReload: onAtlasReload,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.typeName,
    required this.levelLabel,
    required this.name,
    required this.accent,
    required this.onClose,
  });

  final String typeName;
  final String levelLabel;
  final String name;
  final Color accent;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final typeDisplay = typeName[0].toUpperCase() + typeName.substring(1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$typeDisplay · $levelLabel'.toUpperCase(),
                  style: text.eyebrowSmall.copyWith(
                    color: accent,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.close, size: 16, color: colors.quiet),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: text.display.copyWith(
              color: colors.cream,
              fontSize: 22,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhySection extends StatelessWidget {
  const _WhySection({required this.reason, required this.accent});

  final String reason;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.whyIsThisHere.toUpperCase(),
            style: text.eyebrowSmall.copyWith(
              color: accent,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            reason,
            style: text.bodySmall.copyWith(color: colors.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.onEnter});

  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _ActionBtn(
              label: l10n.enterAction,
              color: colors.sky,
              textColor: colors.skyButtonInk,
              onTap: onEnter,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionBtn(
              label: l10n.chatAction,
              color: colors.raised,
              textColor: colors.cream,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionBtn(
              label: l10n.inspect,
              color: colors.raised,
              textColor: colors.cream,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _DoorRow extends StatelessWidget {
  const _DoorRow();

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final l10n = context.l10n;
    final doors = [
      l10n.organize,
      l10n.create,
      l10n.buildAction,
      l10n.enjoy,
      l10n.actAction,
      l10n.govern,
      l10n.settle,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          for (var i = 0; i < doors.length; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
                child: GestureDetector(
                  onTap: () {},
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: colors.camel.withValues(alpha: 0.14),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        doors[i],
                        style: TextStyle(
                          fontFamily: 'Avenir',
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          color: colors.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _levelApiName(int level) => switch (level) {
  1 => 'quiet',
  2 => 'available',
  3 => 'relevant',
  4 => 'central',
  5 => 'vital',
  _ => 'relevant',
};

class _LevelFooter extends ConsumerStatefulWidget {
  const _LevelFooter({
    required this.level,
    required this.realmId,
    required this.realmName,
    required this.accent,
    required this.onClose,
    required this.onAtlasReload,
  });

  final int level;
  final String realmId;
  final String realmName;
  final Color accent;
  final VoidCallback onClose;
  final VoidCallback onAtlasReload;

  @override
  ConsumerState<_LevelFooter> createState() => _LevelFooterState();
}

class _LevelFooterState extends ConsumerState<_LevelFooter> {
  bool _busy = false;

  String? get _wallet =>
      ref.read(authControllerProvider).user?.wallet;

  Future<void> _applyOverride(Future<void> Function() apiCall) async {
    if (_busy) return;
    final wallet = _wallet;
    if (wallet == null || wallet.isEmpty) return;
    setState(() => _busy = true);
    try {
      await apiCall();
      if (!mounted) return;
      widget.onClose();
      widget.onAtlasReload();
    } catch (e) {
      AppLogger.error(
        'Gravity override failed',
        tag: 'RealmDetail',
        error: e,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final l10n = context.l10n;
    final controller = ref.read(fieldControllerProvider.notifier);
    final currentLevel = ref.watch(
      fieldControllerProvider.select(
        (s) => s.realmGravity[widget.realmId] ?? widget.level,
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          Text(
            l10n.setLevel.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Avenir',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: colors.quiet,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            height: 30,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: colors.camel.withValues(alpha: 0.18),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: currentLevel,
                isDense: true,
                dropdownColor: colors.raised,
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 10,
                  color: colors.cream,
                ),
                icon: Icon(
                  Icons.expand_more,
                  size: 14,
                  color: colors.quiet,
                ),
                items: List.generate(5, (i) {
                  final lv = i + 1;
                  return DropdownMenuItem(
                    value: lv,
                    child: Text(_gravityLabel(context, lv)),
                  );
                }),
                onChanged: _busy
                    ? null
                    : (v) {
                        if (v == null || v == currentLevel) return;
                        controller.setGravity(widget.realmId, v);
                        final wallet = _wallet;
                        if (wallet == null || wallet.isEmpty) return;
                        _applyOverride(
                          () => GravityService.instance.setLevelOverride(
                            wallet: wallet,
                            realmId: widget.realmId,
                            level: _levelApiName(v),
                          ),
                        );
                      },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FooterBtn(
              icon: Icons.push_pin_outlined,
              label: l10n.pin,
              onTap: _busy
                  ? () {}
                  : () {
                      final wallet = _wallet;
                      if (wallet == null || wallet.isEmpty) return;
                      _applyOverride(
                        () => GravityService.instance.pinRealmOverride(
                          wallet: wallet,
                          realmId: widget.realmId,
                          level: _levelApiName(currentLevel),
                        ),
                      );
                    },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FooterBtn(
              icon: Icons.visibility_off_outlined,
              label: l10n.hideRealm,
              onTap: _busy
                  ? () {}
                  : () {
                      final wallet = _wallet;
                      if (wallet == null || wallet.isEmpty) return;
                      _applyOverride(
                        () => GravityService.instance.hideRealmOverride(
                          wallet: wallet,
                          realmId: widget.realmId,
                        ),
                      );
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterBtn extends StatelessWidget {
  const _FooterBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: colors.camel.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: colors.quiet),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Avenir',
                  fontSize: 9,
                  color: colors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
