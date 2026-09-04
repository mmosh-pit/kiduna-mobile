import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../data/models/realm_model.dart';
import '../../../data/services/realm_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/field_controller.dart';
import 'field_inputs.dart';

/// The Present working panel: view or edit the current Realm's name, type,
/// purpose, visibility, email, theme, and focus.
///
/// Only the Realm creator (matching wallet) sees editable fields and the save
/// button. All other users see a read-only view.
class PresentPanel extends ConsumerStatefulWidget {
  const PresentPanel({super.key});

  @override
  ConsumerState<PresentPanel> createState() => _PresentPanelState();
}

class _PresentPanelState extends ConsumerState<PresentPanel> {
  RealmModel? _realm;
  bool _loading = true;
  bool _isOwner = false;
  bool _saving = false;
  String? _error;

  late TextEditingController _name;
  late TextEditingController _purpose;
  late TextEditingController _email;
  late String _type;
  late String _visibility;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _purpose = TextEditingController();
    _email = TextEditingController();
    _type = '';
    _visibility = 'public';
    _fetchRealm();
  }

  Future<void> _fetchRealm() async {
    final realmId = ref.read(fieldControllerProvider).currentRealmId;
    try {
      final realm = await RealmService.instance.fetchRealmById(realmId);
      if (!mounted) return;
      final userWallet = ref.read(authControllerProvider).user?.wallet;
      setState(() {
        _realm = realm;
        _isOwner = userWallet != null && realm.wallet == userWallet;
        _name.text = realm.name;
        _purpose.text = realm.purpose ?? '';
        _email.text = realm.email ?? '';
        _type = realm.type;
        _visibility = realm.visibility;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load realm details.';
      });
    }
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      await ref.read(fieldControllerProvider.notifier).savePresentation(
        name: _name.text.trim(),
        type: _type,
        purpose: _purpose.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to save. Please try again.');
    }
    if (!mounted) return;
    setState(() => _saving = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _purpose.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.kiduna;
    final text = context.kidunaText;

    if (_loading) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.gold,
            ),
          ),
        ),
      );
    }

    if (_error != null && _realm == null) {
      return Padding(
        padding: const EdgeInsets.all(18),
        child: Text(_error!, style: text.body.copyWith(color: colors.quiet)),
      );
    }

    final readStyle = text.caption.copyWith(color: colors.text, height: 1.4);
    final labelStyle = text.caption.copyWith(color: colors.quiet, height: 1.4);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x33EF4444),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: text.micro.copyWith(color: const Color(0xFFEF4444)),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Name + Type ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _isOwner
                    ? FieldTextInput(
                        label: l10n.presentName,
                        controller: _name,
                      )
                    : _ReadOnlyField(
                        label: l10n.presentName,
                        value: _realm?.name ?? '',
                        readStyle: readStyle,
                        labelStyle: labelStyle,
                        colors: colors,
                        metrics: context.metrics,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ReadOnlyField(
                  label: l10n.typeLabel,
                  value: _type,
                  readStyle: labelStyle,
                  labelStyle: labelStyle,
                  colors: colors,
                  metrics: context.metrics,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Purpose ──
          _isOwner
              ? FieldTextInput(
                  label: l10n.purpose,
                  controller: _purpose,
                  hint: l10n.presentPurposeHint(_name.text),
                  maxLines: 3,
                )
              : _ReadOnlyField(
                  label: l10n.purpose,
                  value: _realm?.purpose ?? '',
                  readStyle: readStyle,
                  labelStyle: labelStyle,
                  colors: colors,
                  metrics: context.metrics,
                ),
          const SizedBox(height: 12),

          // ── Visibility ──
          _ReadOnlyField(
            label: l10n.visibilityLabel,
            value: _visibility,
            readStyle: _isOwner ? readStyle : labelStyle,
            labelStyle: labelStyle,
            colors: colors,
            metrics: context.metrics,
          ),
          const SizedBox(height: 12),

          // ── Email ──
          if (_realm?.email != null && _realm!.email!.isNotEmpty) ...[
            _ReadOnlyField(
              label: l10n.emailLabel,
              value: _realm?.email ?? '',
              readStyle: _isOwner ? readStyle : labelStyle,
              labelStyle: labelStyle,
              colors: colors,
              metrics: context.metrics,
            ),
            const SizedBox(height: 12),
          ],

          // ── Theme / Focus ──
          if (_realm?.primaryTheme != null) ...[
            Row(
              children: [
                Expanded(
                  child: _ReadOnlyField(
                    label: l10n.primaryThemeLabel,
                    value: _realm?.primaryTheme ?? '',
                    readStyle: _isOwner ? readStyle : labelStyle,
                    labelStyle: labelStyle,
                    colors: colors,
                    metrics: context.metrics,
                  ),
                ),
                if (_realm?.primaryFocus != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ReadOnlyField(
                      label: l10n.primaryFocusLabel,
                      value: _realm?.primaryFocus ?? '',
                      readStyle: _isOwner ? readStyle : labelStyle,
                      labelStyle: labelStyle,
                      colors: colors,
                      metrics: context.metrics,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],

          // ── Realm Portrait ──
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
                        AssetImage(
                          ref
                              .read(fieldControllerProvider)
                              .currentRealm
                              .emblemAsset,
                        ),
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
                        l10n.presentPortraitDescription(_type),
                        style: text.micro.copyWith(
                          color: colors.muted,
                          fontSize: 9,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Save button (owner only) ──
          if (_isOwner) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: FieldPrimaryButton(
                label: _saving ? l10n.saving : l10n.savePresentation,
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ],
      ),
    );
  }

}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
    required this.readStyle,
    required this.labelStyle,
    required this.colors,
    required this.metrics,
  });

  final String label;
  final String value;
  final TextStyle readStyle;
  final TextStyle labelStyle;
  final dynamic colors;
  final dynamic metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(text: label),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          constraints: const BoxConstraints(minHeight: 37),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(6, 3, 4, 0.66),
            borderRadius: BorderRadius.circular(metrics.radiusMd as double),
            border: Border.all(
              color: (colors.camel as Color).withValues(alpha: 0.24),
            ),
          ),
          child: Text(
            value.isEmpty ? '—' : value,
            style: readStyle,
          ),
        ),
      ],
    );
  }
}
