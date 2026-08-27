import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/kiduna_primary_button.dart';
import '../../../data/services/auth_service.dart';
import '../controllers/auth_controller.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// Unified public profile page.
///
/// Two modes:
///   1. **Profile only** — `inviteCode` is null. Shows profile card,
///      upward lineage, active invites, and downward referral tree.
///      Reached from the header "View Profile" menu.
///
///   2. **Invite landing** — `inviteCode` is set. Shows the same profile
///      content plus invite-specific info (realm, sponsorship, spots,
///      expiry) and a "Join Kiduna" button at the bottom.
///      Reached from `kiduna.ai/{handle}/code/{CODE}` URLs.
class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({
    super.key,
    required this.handle,
    this.inviteCode,
  });

  final String handle;

  /// When set, the page shows invite details and a "Join Kiduna" button.
  final String? inviteCode;

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _tree;
  Map<String, dynamic>? _preview; // invite preview (only when inviteCode set)
  bool _loading = true;
  String? _error;

  bool get _isInviteMode => widget.inviteCode != null;

  Dio get _dio => ApiClient.instance.authDio;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      // ── If invite mode, load preview first to validate ──
      if (_isInviteMode) {
        final preview = await AuthService.instance.previewInvite(
          code: widget.inviteCode!,
        );
        if (!mounted) return;

        if (preview['valid'] != true) {
          setState(() {
            _error = preview['reason'] as String? ?? 'Invalid invitation.';
            _loading = false;
          });
          return;
        }
        _preview = preview;
      }

      // ── Load profile ──
      Map<String, dynamic>? profile;
      try {
        final resp = await _dio
            .get<Map<String, dynamic>>('/profile/${widget.handle}');
        profile = resp.data;
      } catch (e) {
        AppLogger.warning('Profile load failed: $e', tag: 'Profile');
        if (_isInviteMode) {
          // In invite mode, profile failure is non-fatal — we have preview
        } else {
          if (!mounted) return;
          setState(() {
            _error = (e is DioException && e.response?.statusCode == 404)
                ? 'User not found'
                : 'Failed to load profile';
            _loading = false;
          });
          return;
        }
      }

      // ── Load tree ──
      Map<String, dynamic>? tree;
      try {
        print('[Profile] Loading tree for handle=${widget.handle}');
        final treeResp = await _dio.get<Map<String, dynamic>>(
            '/profile/${widget.handle}/tree?depth=4');
        tree = treeResp.data;
        print('[Profile] Tree loaded: ${tree?.keys.toList()}');
        print('[Profile] Tree children count: ${(tree?['children'] as List?)?.length ?? 0}');
      } catch (e) {
        print('[Profile] Tree load FAILED: $e');
        AppLogger.warning('Tree load failed: $e', tag: 'Profile');
      }

      if (!mounted) return;
      print('[Profile] Setting state — profile=${profile != null}, tree=${tree != null}');
      setState(() {
        _profile = profile;
        _tree = tree;
        _loading = false;
      });
    } catch (e, st) {
      AppLogger.error('Profile load failed', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load. Please try again.';
        _loading = false;
      });
    }
  }

  bool _joining = false;
  String? _joinError;
  String? _joinSuccess;

  /// Logged-in user — directly join the realm via invite code.
  Future<void> _joinRealm() async {
    if (widget.inviteCode == null) return;
    setState(() {
      _joining = true;
      _joinError = null;
      _joinSuccess = null;
    });

    try {
      final result = await AuthService.instance.joinRealmViaInvite(
        code: widget.inviteCode!,
      );
      if (!mounted) return;

      final alreadyMember = result['already_member'] == true;
      final realmName = result['realmName'] as String? ?? 'the realm';
      final kiduna = result['kidunaReceived'] as num? ?? 0;

      setState(() {
        _joining = false;
        _joinSuccess = alreadyMember
            ? 'You are already a member of $realmName.'
            : 'Joined $realmName!'
                '${kiduna > 0 ? ' +${_formatKiduna(kiduna.toDouble())} KIDUNA' : ''}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _joining = false;
        _joinError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _goToSignup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const SignupScreen()),
    );
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    return Scaffold(
      backgroundColor: colors.field,
      body: Column(
        children: [
          // Show header in profile mode, hide in invite mode (no session)
          if (!_isInviteMode) const AppHeader(),
          Expanded(
            child: _loading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colors.sky,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isInviteMode
                              ? 'Loading invitation...'
                              : 'Loading profile...',
                          style: TextStyle(color: colors.muted, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: colors.orange),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: text.body
                                  .copyWith(color: colors.text, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : _buildContent(colors, text),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(dynamic colors, dynamic text) {
    // Profile data
    final inviter = _preview?['inviter'] as Map<String, dynamic>?;
    final name = _profile?['name'] as String? ??
        inviter?['name'] as String? ??
        'User';
    final username = _profile?['username'] as String? ??
        inviter?['handle'] as String?;
    final picture = _profile?['picture'] as String? ??
        inviter?['picture'] as String?;
    final bio =
        _profile?['bio'] as String? ?? inviter?['bio'] as String?;
    final inviteeCount =
        int.tryParse(_profile?['inviteeCount']?.toString() ?? '') ?? 0;
    final profileRealms =
        (_profile?['realms'] as List<dynamic>?) ?? [];
    final activeInvites =
        (_profile?['activeInvites'] as List<dynamic>?) ?? [];
    final upwardLineage =
        (_profile?['upwardLineage'] as List<dynamic>?) ?? [];

    // Invite-specific data
    final realm = _preview?['realm'] as Map<String, dynamic>?;
    final role = _preview?['role'] as String? ?? 'member';
    final kidunaPerPerson =
        double.tryParse(_preview?['kidunaPerPerson']?.toString() ?? '') ?? 0;
    final maxUses =
        int.tryParse(_preview?['maxUses']?.toString() ?? '') ?? 0;
    final currentUses =
        int.tryParse(_preview?['currentUses']?.toString() ?? '') ?? 0;
    final expiresAt = _preview?['expiresAt'] as String?;
    final label = _preview?['label'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Profile card ──
              _buildProfileCard(
                colors, text, name, username, picture, bio,
                inviteeCount, profileRealms,
              ),
              const SizedBox(height: 24),

              // ── Upward lineage ──
              if (upwardLineage.isNotEmpty) ...[
                _buildUpwardLineage(colors, text, upwardLineage),
                const SizedBox(height: 24),
              ],

              // ── Downward referral tree ──
              if (_tree != null) ...[
                _buildTreeSection(colors, text),
                const SizedBox(height: 24),
              ],

              // ── Active invites (profile mode only) ──
              if (!_isInviteMode && activeInvites.isNotEmpty) ...[
                _buildActiveInvites(colors, text, activeInvites),
                const SizedBox(height: 24),
              ],

              // ── Invite actions (invite mode only) ──
              if (_isInviteMode) ...[
                if (realm != null) ...[
                  _buildRealmCard(colors, text, realm, role),
                  const SizedBox(height: 16),
                ],
                if (kidunaPerPerson > 0)
                  _buildInfoRow(colors, text, Icons.toll,
                      '${_formatKiduna(kidunaPerPerson)} KIDUNA sponsored for you'),
                if (maxUses > 0)
                  _buildInfoRow(colors, text, Icons.people_outline,
                      '${maxUses - currentUses} of $maxUses spots remaining'),
                if (expiresAt != null)
                  _buildInfoRow(colors, text, Icons.schedule,
                      'Expires ${_formatDate(expiresAt)}'),
                if (label != null && label.isNotEmpty)
                  _buildInfoRow(colors, text, Icons.label_outline, label),

                const SizedBox(height: 28),
                _buildJoinActions(colors, text),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Join actions (auth-aware) ────────────────────────────────────────

  Widget _buildJoinActions(dynamic colors, dynamic text) {
    final isLoggedIn = ref.watch(authControllerProvider).isAuthenticated;

    // Already joined successfully
    if (_joinSuccess != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.mint.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.mint.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: colors.mint, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_joinSuccess!,
                  style: text.body.copyWith(color: colors.mint, fontSize: 14)),
            ),
          ],
        ),
      );
    }

    // Error
    if (_joinError != null) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.orange.withValues(alpha: 0.3)),
            ),
            child: Text(_joinError!,
                style: text.caption.copyWith(color: colors.orange)),
          ),
          const SizedBox(height: 12),
          if (isLoggedIn)
            SizedBox(
              width: double.infinity,
              child: KidunaPrimaryButton(
                label: 'Try Again',
                onPressed: _joinRealm,
              ),
            ),
        ],
      );
    }

    // Logged in — join directly
    if (isLoggedIn) {
      return SizedBox(
        width: double.infinity,
        child: _joining
            ? Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: colors.sky))
            : KidunaPrimaryButton(
                label: 'Join Realm',
                onPressed: _joinRealm,
              ),
      );
    }

    // Not logged in — show both options
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: KidunaPrimaryButton(
            label: 'Sign Up to Join',
            onPressed: _goToSignup,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _goToLogin,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              foregroundColor: colors.sky,
              side: BorderSide(color: colors.sky.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle: text.body.copyWith(fontSize: 16),
            ),
            child: const Text('Log In to Join'),
          ),
        ),
      ],
    );
  }

  // ── Profile card ───────────────────────────────────────────────────────

  Widget _buildProfileCard(
    dynamic colors, dynamic text,
    String name, String? username, String? picture, String? bio,
    int inviteeCount, List<dynamic> realmsJoined,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.camel.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.sky.withValues(alpha: 0.15),
              border: Border.all(
                  color: colors.sky.withValues(alpha: 0.3), width: 2),
              image: picture != null && picture.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(picture), fit: BoxFit.cover)
                  : null,
            ),
            child: picture == null || picture.isEmpty
                ? Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style:
                          text.h4.copyWith(color: colors.sky, fontSize: 28),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 14),
          Text(name, style: text.h4.copyWith(color: colors.text),
              textAlign: TextAlign.center),
          if (username != null) ...[
            const SizedBox(height: 2),
            Text('@$username',
                style: text.caption.copyWith(color: colors.muted)),
          ],
          if (_isInviteMode) ...[
            const SizedBox(height: 4),
            Text('invites you to join',
                style: text.body.copyWith(color: colors.muted, fontSize: 14),
                textAlign: TextAlign.center),
          ],
          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(bio,
                style: text.body.copyWith(
                    color: colors.muted, fontSize: 14, height: 1.5),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: colors.camel.withValues(alpha: 0.15)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatChip(
                    colors: colors, text: text,
                    label: 'Invited', value: inviteeCount.toString()),
                const SizedBox(width: 32),
                _StatChip(
                    colors: colors, text: text,
                    label: 'Realms', value: realmsJoined.length.toString()),
              ],
            ),
          ),
          if (realmsJoined.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 6,
              alignment: WrapAlignment.center,
              children: realmsJoined
                  .map<Widget>((r) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.gold.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: colors.gold.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          '${r['name']} · ${(r['role'] as String? ?? '').toUpperCase()}',
                          style: text.caption.copyWith(
                              color: colors.gold, fontSize: 11),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ── Upward lineage ─────────────────────────────────────────────────────

  Widget _buildUpwardLineage(
      dynamic colors, dynamic text, List<dynamic> lineage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.camel.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lineage (Upward)',
              style: text.body.copyWith(
                  color: colors.gold, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 12),
          ...lineage.asMap().entries.map<Widget>((entry) {
            final i = entry.key;
            final a = entry.value as Map<String, dynamic>;
            final aName = (a['name'] as String?) ?? 'Unknown';
            final aUsername = a['username'] as String?;
            final aPicture = a['picture'] as String?;
            final aWallet = a['wallet'] as String? ?? '';
            final gen = a['generation'] as String? ?? 'Gen${i + 1}';

            return Padding(
              padding: EdgeInsets.only(left: i * 20.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    if (i > 0) ...[
                      Container(width: 12, height: 1,
                          color: colors.gold.withValues(alpha: 0.3)),
                      const SizedBox(width: 4),
                    ],
                    _avatar(colors, text, aName, aPicture,
                        accentColor: colors.gold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _nameRow(text, colors, aName, aUsername),
                          Text(_truncateWallet(aWallet),
                              style: text.caption.copyWith(
                                  color: colors.quiet,
                                  fontFamily: 'monospace',
                                  fontSize: 10)),
                        ],
                      ),
                    ),
                    Text(gen,
                        style: text.caption.copyWith(
                            color: colors.gold.withValues(alpha: 0.6),
                            fontSize: 10)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Downward tree ──────────────────────────────────────────────────────

  Widget _buildTreeSection(dynamic colors, dynamic text) {
    final children = (_tree!['children'] as List<dynamic>?) ?? [];
    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.camel.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Referral Network',
              style: text.body.copyWith(
                  color: colors.gold, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 12),
          ...children.map<Widget>(
              (c) => _buildTreeNode(colors, text, c, 0)),
        ],
      ),
    );
  }

  Widget _buildTreeNode(
      dynamic colors, dynamic text, dynamic node, int depth) {
    final name = (node['displayName'] as String?) ??
        (node['name'] as String?) ?? 'Unknown';
    final username = node['username'] as String?;
    final picture = node['picture'] as String?;
    final wallet = node['wallet'] as String? ?? '';
    final children = (node['children'] as List<dynamic>?) ?? [];
    final joinedAt = node['joinedAt'] as String?;

    return Padding(
      padding: EdgeInsets.only(left: depth * 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                if (depth > 0) ...[
                  Container(width: 12, height: 1,
                      color: colors.camel.withValues(alpha: 0.3)),
                  const SizedBox(width: 4),
                ],
                _avatar(colors, text, name, picture),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _nameRow(text, colors, name, username),
                      if (wallet.isNotEmpty)
                        Text(_truncateWallet(wallet),
                            style: text.caption.copyWith(
                                color: colors.quiet,
                                fontFamily: 'monospace',
                                fontSize: 10)),
                    ],
                  ),
                ),
                if (joinedAt != null)
                  Text(_formatDate(joinedAt),
                      style: text.caption.copyWith(
                          color: colors.quiet, fontSize: 10)),
              ],
            ),
          ),
          ...children.map<Widget>(
              (c) => _buildTreeNode(colors, text, c, depth + 1)),
        ],
      ),
    );
  }

  // ── Active invites ─────────────────────────────────────────────────────

  Widget _buildActiveInvites(
      dynamic colors, dynamic text, List<dynamic> invites) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.camel.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Active Invites',
              style: text.body.copyWith(
                  color: colors.gold, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 10),
          ...invites.map<Widget>((inv) {
            final realmName = inv['realmName'] as String? ?? '';
            final mu = int.tryParse(inv['maxUses']?.toString() ?? '') ?? 0;
            final cu = int.tryParse(inv['currentUses']?.toString() ?? '') ?? 0;
            final k = double.tryParse(
                    inv['kidunaPerPerson']?.toString() ?? '') ?? 0;
            final lbl = inv['label'] as String?;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.field,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: colors.camel.withValues(alpha: 0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(realmName,
                        style: text.caption.copyWith(
                            color: colors.cream, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      '${mu - cu}/$mu spots'
                      '${k > 0 ? ' · ${_formatKiduna(k)} KIDUNA' : ''}'
                      '${lbl != null ? ' · $lbl' : ''}',
                      style: text.caption
                          .copyWith(color: colors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Realm card (invite mode) ───────────────────────────────────────────

  Widget _buildRealmCard(
      dynamic colors, dynamic text, Map<String, dynamic> realm, String role) {
    final realmName = realm['name'] as String? ?? '';
    final realmType = realm['type'] as String? ?? 'realm';
    final description = realm['description'] as String?;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.gold.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(realmName,
              style: text.h4.copyWith(color: colors.gold, fontSize: 18)),
          const SizedBox(height: 4),
          Text('${realmType.toUpperCase()} · Role: $role',
              style: text.caption.copyWith(color: colors.muted, fontSize: 12)),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(description,
                style: text.body.copyWith(
                    color: colors.text, fontSize: 14, height: 1.5),
                maxLines: 4,
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────

  Widget _avatar(dynamic colors, dynamic text, String name, String? picture,
      {Color? accentColor}) {
    final color = accentColor ?? colors.sky;
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (color as Color).withValues(alpha: 0.12),
        image: picture != null && picture.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(picture), fit: BoxFit.cover)
            : null,
      ),
      child: picture == null || picture.isEmpty
          ? Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: text.caption.copyWith(
                    color: color, fontWeight: FontWeight.w700, fontSize: 11),
              ),
            )
          : null,
    );
  }

  Widget _nameRow(dynamic text, dynamic colors, String name, String? username) {
    return Row(
      children: [
        Flexible(
          child: Text(name,
              style: text.caption.copyWith(
                  color: colors.cream, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        if (username != null) ...[
          const SizedBox(width: 4),
          Text('@$username',
              style: text.caption.copyWith(color: colors.muted, fontSize: 10)),
        ],
      ],
    );
  }

  Widget _buildInfoRow(
      dynamic colors, dynamic text, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: text.body.copyWith(color: colors.text, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  String _formatKiduna(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(amount % 1000000 == 0 ? 0 : 1)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  String _truncateWallet(String wallet) {
    if (wallet.length <= 14) return wallet;
    return '${wallet.substring(0, 6)}...${wallet.substring(wallet.length - 4)}';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.colors,
    required this.text,
    required this.label,
    required this.value,
  });

  final dynamic colors;
  final dynamic text;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: text.body.copyWith(
                color: colors.gold, fontWeight: FontWeight.w700, fontSize: 20)),
        Text(label,
            style: text.caption.copyWith(color: colors.muted, fontSize: 11)),
      ],
    );
  }
}
