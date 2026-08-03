import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/assets.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/field_controller.dart';
import '../data/field_fixtures.dart';
import 'field_inputs.dart';

/// The Form a New Realm working panel.
///
/// When the selected type is **Organization**, the form shows:
/// Organization Name, Registration, Purpose, and Email.
/// ecosystemId, capacities, organizations, and members are auto-generated
/// server-side.
///
/// On create, the Organization is persisted via
/// `POST /api/v1/dunas/organizations` under the Genesis DUNA.
///
/// For other types the form keeps the original 3 fields (name, type, purpose)
/// and creation remains local (UI-only).
class RealmPanel extends ConsumerStatefulWidget {
  const RealmPanel({super.key});

  @override
  ConsumerState<RealmPanel> createState() => _RealmPanelState();
}

class _RealmPanelState extends ConsumerState<RealmPanel> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _purpose = TextEditingController();
  final TextEditingController _registration = TextEditingController();
  final TextEditingController _email = TextEditingController();
  String _type = 'Organization';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    if (user != null && user.email.isNotEmpty) {
      _email.text = user.email;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _purpose.dispose();
    _registration.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _isOrganization => _type == 'Organization';

  Future<void> _handleCreate() async {
    final nameText = _name.text.trim();
    if (nameText.isEmpty) return;

    setState(() => _submitting = true);

    await ref
        .read(fieldControllerProvider.notifier)
        .createRealm(
          name: nameText,
          type: _type,
          purpose: _purpose.text.trim(),
          registration: _isOrganization ? _registration.text.trim() : null,
          email: _isOrganization ? _email.text.trim() : null,
        );

    if (mounted) {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.kiduna;
    final text = context.kidunaText;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Row 1: Name + Type ─────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FieldTextInput(
                  label: _isOrganization
                      ? l10n.organizationName
                      : l10n.realmName,
                  controller: _name,
                  hint: _isOrganization
                      ? l10n.nameThisOrganization
                      : l10n.nameThisRealm,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FieldDropdown(
                  label: l10n.typeLabel,
                  value: _type,
                  options: FieldFixtures.realmTypes,
                  onChanged: (value) => setState(() => _type = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Organization-specific: Registration ────────────────────
          if (_isOrganization) ...[
            FieldTextInput(
              label: l10n.registrationLabel,
              controller: _registration,
              hint: l10n.registrationHint,
            ),
            const SizedBox(height: 12),
          ],

          // ── Purpose (always shown) ─────────────────────────────────
          FieldTextInput(
            label: l10n.purpose,
            controller: _purpose,
            hint: _isOrganization
                ? l10n.whatIsTheMissionYourMembersShare
                : l10n.whatShouldThisRealmBringIntoBeing,
            maxLines: 3,
          ),
          const SizedBox(height: 12),

          // ── Organization-specific: Email ────────────────────────────
          if (_isOrganization) ...[
            FieldTextInput(
              label: l10n.emailLabel,
              controller: _email,
              hint: l10n.emailHint,
            ),
            const SizedBox(height: 12),
          ],

          // ── Portrait preview ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.gold.withValues(alpha: 0.05),
                  colors.sky.withValues(alpha: 0.035),
                ],
              ),
              border: Border.all(color: colors.gold.withValues(alpha: 0.24)),
              borderRadius: BorderRadius.circular(context.metrics.radiusPanel),
            ),
            child: Row(
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.gold.withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.gold.withValues(alpha: 0.1),
                        blurRadius: 24,
                      ),
                    ],
                    image: DecorationImage(
                      image: ResizeImage(
                        AssetImage(AppAssets.realmEmblem(_type)),
                        width: (74 * MediaQuery.devicePixelRatioOf(context))
                            .round(),
                        height: (74 * MediaQuery.devicePixelRatioOf(context))
                            .round(),
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.realmPortrait,
                        style: text.h5.copyWith(
                          color: colors.cream,
                          fontSize: 17,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        l10n.defaultPortraitDescription,
                        style: text.micro.copyWith(
                          color: colors.muted,
                          fontSize: 9,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    foregroundColor: colors.skyButtonInk,
                    backgroundColor: colors.sky,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: Text(
                    l10n.create,
                    style: text.label.copyWith(
                      color: colors.skyButtonInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Create button ───────────────────────────────────────────
          Align(
            alignment: Alignment.centerLeft,
            child: ListenableBuilder(
              listenable: Listenable.merge([_name, _purpose, _email]),
              builder: (context, _) {
                final nameOk = _name.text.trim().isNotEmpty;
                final purposeOk =
                    !_isOrganization || _purpose.text.trim().length >= 10;
                final emailOk =
                    !_isOrganization || _email.text.trim().isNotEmpty;
                final canCreate =
                    nameOk && purposeOk && emailOk && !_submitting;
                return FieldPrimaryButton(
                  label: _submitting
                      ? l10n.creating
                      : (_isOrganization
                            ? l10n.createOrganizationAction
                            : l10n.createRealmAction),
                  onPressed: canCreate ? _handleCreate : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
