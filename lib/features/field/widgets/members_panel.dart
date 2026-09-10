import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/realm_model.dart';
import '../../../data/services/realm_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/field_controller.dart';
import '../data/field_fixtures.dart';
import '../data/field_models.dart';

/// Working panel that lists realm members and lets Catalyst / Mage
/// change roles or remove members.
class MembersPanel extends ConsumerStatefulWidget {
  const MembersPanel({super.key});

  @override
  ConsumerState<MembersPanel> createState() => _MembersPanelState();
}

class _MembersPanelState extends ConsumerState<MembersPanel> {
  List<RealmMemberModel> _members = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final fieldState = ref.read(fieldControllerProvider);
    final realmId = fieldState.enteredRealmId ?? fieldState.currentRealmId;
    if (realmId == null) {
      setState(() {
        _loading = false;
        _error = 'No realm selected.';
      });
      return;
    }

    try {
      setState(() => _loading = true);
      final realm = await RealmService.instance.fetchRealmById(realmId);
      if (!mounted) return;
      setState(() {
        _members = realm.members;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load members.';
        _loading = false;
      });
    }
  }

  String? get _viewerWallet =>
      ref.read(authControllerProvider).user?.wallet;

  Role get _viewerRole {
    final fieldState = ref.read(fieldControllerProvider);
    final realmId = fieldState.enteredRealmId ?? fieldState.currentRealmId;
    return realmId != null ? fieldState.viewerRoleIn(realmId) : Role.guest;
  }

  String? get _realmId {
    final fieldState = ref.read(fieldControllerProvider);
    return fieldState.enteredRealmId ?? fieldState.currentRealmId;
  }

  /// Roles this viewer is allowed to assign.
  List<String> _allowedRoles() {
    final vr = _viewerRole;
    return FieldFixtures.roles.where((label) {
      final role = Role.parse(label);
      if (role.index > vr.index) return false;
      if (role == Role.catalyst && vr != Role.catalyst) return false;
      return true;
    }).toList();
  }

  /// Whether the viewer can edit this member's role.
  bool _canEditRole(RealmMemberModel member) {
    // Can't edit own role.
    if (member.wallet == _viewerWallet) return false;
    // Can't edit someone with equal or higher rank.
    final memberRole = Role.parse(member.role);
    if (memberRole.index >= _viewerRole.index) return false;
    return true;
  }

  /// Whether the viewer can remove this member.
  bool _canRemove(RealmMemberModel member) {
    // Can't remove self.
    if (member.wallet == _viewerWallet) return false;
    // Can't remove someone with equal or higher rank.
    final memberRole = Role.parse(member.role);
    if (memberRole.index >= _viewerRole.index) return false;
    return true;
  }

  Future<void> _changeRole(RealmMemberModel member, String newRole) async {
    final realmId = _realmId;
    if (realmId == null) return;

    try {
      await RealmService.instance.updateMemberRole(
        realmId: realmId,
        memberId: member.id,
        role: newRole.toLowerCase(),
      );
      await _loadMembers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _removeMember(RealmMemberModel member) async {
    final realmId = _realmId;
    if (realmId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.kiduna.raised,
        title: Text(
          'Remove ${member.label}?',
          style: ctx.kidunaText.heading.copyWith(color: ctx.kiduna.cream),
        ),
        content: Text(
          'This will remove them from the realm. They can rejoin with a new invite.',
          style: ctx.kidunaText.bodySmall.copyWith(color: ctx.kiduna.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: ctx.kiduna.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await RealmService.instance.removeMember(
        realmId: realmId,
        memberId: member.id,
      );
      await _loadMembers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    if (_loading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CircularProgressIndicator(color: colors.cream),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, style: text.bodySmall.copyWith(color: colors.muted)),
        ),
      );
    }

    if (_members.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No members yet.', style: text.bodySmall.copyWith(color: colors.muted)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _members.length,
      separatorBuilder: (_, __) => Divider(
        color: colors.camel.withValues(alpha: 0.15),
        height: 1,
      ),
      itemBuilder: (context, index) {
        final member = _members[index];
        final isSelf = member.wallet == _viewerWallet;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              // Avatar circle
              CircleAvatar(
                radius: 18,
                backgroundColor: colors.camel.withValues(alpha: 0.2),
                backgroundImage:
                    member.picture != null ? NetworkImage(member.picture!) : null,
                child: member.picture == null
                    ? Text(
                        member.label[0].toUpperCase(),
                        style: text.bodySmall.copyWith(color: colors.cream),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Name + wallet
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${member.label}${isSelf ? ' (you)' : ''}',
                      style: text.bodySmall.copyWith(
                        color: colors.cream,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${member.wallet.substring(0, 4)}…${member.wallet.substring(member.wallet.length - 4)}',
                      style: text.caption.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),

              // Role badge / dropdown
              if (_canEditRole(member))
                _RoleDropdown(
                  currentRole: member.role,
                  options: _allowedRoles(),
                  onChanged: (newRole) => _changeRole(member, newRole),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.camel.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _capitalize(member.role),
                    style: text.caption.copyWith(color: colors.muted),
                  ),
                ),

              // Remove button
              if (_canRemove(member)) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _removeMember(member),
                  child: Icon(Icons.close, size: 18, color: Colors.red.shade300),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

/// Compact dropdown for role selection inside the member row.
class _RoleDropdown extends StatelessWidget {
  const _RoleDropdown({
    required this.currentRole,
    required this.options,
    required this.onChanged,
  });

  final String currentRole;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final text = context.kidunaText;

    final displayRole = currentRole.isNotEmpty
        ? '${currentRole[0].toUpperCase()}${currentRole.substring(1)}'
        : currentRole;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.camel.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.camel.withValues(alpha: 0.24)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: displayRole,
          isDense: true,
          dropdownColor: colors.raised,
          icon: Icon(Icons.arrow_drop_down, size: 16, color: colors.muted),
          style: text.caption.copyWith(color: colors.cream),
          items: options.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Text(role, style: text.caption.copyWith(color: colors.cream)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null && value.toLowerCase() != currentRole.toLowerCase()) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }
}
