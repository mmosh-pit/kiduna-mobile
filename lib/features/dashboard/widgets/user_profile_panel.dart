import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/user_model.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../features/auth/screens/login_screen.dart';

class UserProfilePanel extends ConsumerStatefulWidget {
  const UserProfilePanel({super.key});

  @override
  ConsumerState<UserProfilePanel> createState() => _UserProfilePanelState();
}

class _UserProfilePanelState extends ConsumerState<UserProfilePanel> {
  bool _inspectOpen = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfilePill(
          user: user,
          inspectOpen: _inspectOpen,
          onInspect: () => setState(() => _inspectOpen = !_inspectOpen),
        ),
        if (_inspectOpen) ...[
          const SizedBox(height: 12),
          _InspectPanel(
            user: user,
            onLogout: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                PageRouteBuilder<void>(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const LoginScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
                (_) => false,
              );
            },
          ),
        ],
      ],
    );
  }
}

const Color _enamelWarm = Color(0xFF28405A);
const Color _enamelCore = Color(0xFF080D10);

class _ProfilePill extends StatelessWidget {
  const _ProfilePill({
    required this.user,
    required this.inspectOpen,
    required this.onInspect,
  });

  final UserModel user;
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
            color: colors.sky.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _ProfileEmblem(
            initial: user.name.isNotEmpty ? user.name.characters.first : 'U',
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PROFILE',
                  style: text.eyebrow.copyWith(
                    color: colors.sky,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.displayName ?? user.name,
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

class _ProfileEmblem extends StatelessWidget {
  const _ProfileEmblem({required this.initial});

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
                colors: [_enamelWarm, Color(0xFF0A101B)],
                stops: [0, 0.63],
              ),
              border: Border.all(
                color: colors.sky.withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.sky.withValues(alpha: 0.14),
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
                  color: colors.sky.withValues(alpha: 0.25),
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
                    colors.sky.withValues(alpha: 0.1),
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
  const _InspectPanel({required this.user, required this.onLogout});

  final UserModel user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    final facts = [
      ('NAME', user.displayName ?? user.name),
      if (user.username != null) ('USERNAME', '@${user.username}'),
      ('EMAIL', user.email),
      ('ROLE', (user.role ?? 'member').toUpperCase()),
      if (user.kinshipCode != null) ('KINSHIP CODE', user.kinshipCode!),
      if (user.bio != null && user.bio!.isNotEmpty) ('BIO', user.bio!),
    ];

    final hasWallet = user.wallet != null && user.wallet!.isNotEmpty;

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
                  'PROFILE',
                  style: text.eyebrowSmall.copyWith(color: colors.sky),
                ),
                const SizedBox(height: 4),
                Text(
                  user.displayName ?? user.name,
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
          if (hasWallet) _WalletRow(wallet: user.wallet!),
          const SizedBox(height: 8),
          _LogoutRow(onTap: onLogout),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LogoutRow extends StatefulWidget {
  const _LogoutRow({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_LogoutRow> createState() => _LogoutRowState();
}

class _LogoutRowState extends State<_LogoutRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? colors.error.withValues(alpha: 0.06)
                : Colors.transparent,
            border: Border(
              top: BorderSide(color: colors.camel.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                size: 18,
                color: _hovered ? colors.error : colors.quiet,
              ),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: text.body.copyWith(
                  color: _hovered ? colors.error : colors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletRow extends StatefulWidget {
  const _WalletRow({required this.wallet});

  final String wallet;

  @override
  State<_WalletRow> createState() => _WalletRowState();
}

class _WalletRowState extends State<_WalletRow> {
  bool _hovered = false;
  bool _copied = false;

  Future<void> _copyWallet() async {
    await Clipboard.setData(ClipboardData(text: widget.wallet));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  String _truncate(String wallet) {
    if (wallet.length <= 14) return wallet;
    return '${wallet.substring(0, 6)}…${wallet.substring(wallet.length - 6)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _copyWallet,
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
                  'WALLET',
                  style: text.eyebrowSmall.copyWith(
                    color: colors.quiet,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _truncate(widget.wallet),
                  style: text.body.copyWith(
                    color: _hovered ? colors.sky : colors.cream,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                _copied ? Icons.check_rounded : Icons.copy_rounded,
                size: 16,
                color: _copied
                    ? colors.sky
                    : (_hovered ? colors.sky : colors.quiet),
              ),
            ],
          ),
        ),
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
