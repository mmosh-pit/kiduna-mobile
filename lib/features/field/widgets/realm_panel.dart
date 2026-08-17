import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/assets.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../data/services/realm_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/ecosystem_controller.dart';
import '../controllers/field_controller.dart';
import '../data/field_fixtures.dart';
import 'field_inputs.dart';

/// The Form a New Realm working panel.
///
/// **Organization** — Name, Registration, Purpose, Email.
/// **Alliance** — Name, Handle, Description, Purpose/Project, Visibility.
/// **Institution** — Name, Handle, Entity Type, Description, Purpose,
///   Registration Domain, Standing Doc URL, Contact, Email, Address.
/// **Other types** — Name, Type, Purpose (local UI-only).
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

  // Alliance + Institution shared controllers.
  final TextEditingController _handle = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _sharedPurpose = TextEditingController();

  // Institution-specific controllers.
  final TextEditingController _regDomain = TextEditingController();
  final TextEditingController _standingDocUrl = TextEditingController();
  final TextEditingController _designateContact = TextEditingController();
  final TextEditingController _designateEmail = TextEditingController();
  final TextEditingController _address = TextEditingController();

  String _type = 'Organization';
  String _visibility = 'public';
  String _entityType = 'company';
  bool _submitting = false;
  String? _error;

  // Handle availability state.
  bool? _handleAvailable;
  bool _handleChecking = false;
  Timer? _handleDebounce;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    if (user != null && user.email.isNotEmpty) _email.text = user.email;
    _name.addListener(_autoSuggestHandle);
  }

  @override
  void dispose() {
    _name.removeListener(_autoSuggestHandle);
    _handleDebounce?.cancel();
    for (final c in [_name, _purpose, _registration, _email, _handle,
        _description, _sharedPurpose, _regDomain, _standingDocUrl,
        _designateContact, _designateEmail, _address]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isOrganization => _type == 'Organization';
  bool get _isAlliance => _type == 'Alliance';
  bool get _isInstitution => _type == 'Institution';
  bool get _hasHandle => _isAlliance || _isInstitution;

  void _autoSuggestHandle() {
    if (!_hasHandle) return;
    if (_handle.text.isNotEmpty &&
        _handle.text != _slugify(_name.text.substring(
            0, _name.text.length > 1 ? _name.text.length - 1 : 0))) {
      return;
    }
    _handle.text = _slugify(_name.text);
    _checkHandleAvailability(_handle.text);
  }

  String _slugify(String text) {
    return text.trim().toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  void _checkHandleAvailability(String handle) {
    _handleDebounce?.cancel();
    setState(() { _handleAvailable = null; _handleChecking = handle.isNotEmpty; });
    if (handle.isEmpty) return;
    _handleDebounce = Timer(const Duration(milliseconds: 400), () async {
      final available = await RealmService.instance.checkHandleAvailability(handle);
      if (mounted && _handle.text == handle) {
        setState(() { _handleAvailable = available; _handleChecking = false; });
      }
    });
  }

  // ── Validation patterns (mirror server-side) ──
  static final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _urlRe = RegExp(r'^https?://.+', caseSensitive: false);
  static final _domainRe = RegExp(
      r'^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$');
  static final _handleRe = RegExp(r'^[a-z0-9._-]{1,25}$');

  /// Validate form fields client-side. Returns error message or null.
  String? _validate() {
    final nameText = _name.text.trim();
    if (nameText.isEmpty) return 'Name is required.';
    if (nameText.length > 120) return 'Name must be 120 characters or fewer.';

    if (_hasHandle) {
      final h = _handle.text.trim();
      if (h.isEmpty) return 'Handle is required.';
      if (!_handleRe.hasMatch(h)) {
        return 'Handle can only contain lowercase letters, numbers, dots, hyphens, and underscores (max 25 chars).';
      }
      if (_handleAvailable == false) return 'That handle is already taken — pick another.';
    }

    if (_isAlliance) {
      // Alliance: no extra required fields beyond name + handle.
    }

    if (_isInstitution) {
      // Validate optional format fields.
      final email = _designateEmail.text.trim();
      if (email.isNotEmpty && !_emailRe.hasMatch(email)) {
        return 'Designate email format is invalid.';
      }
      final url = _standingDocUrl.text.trim();
      if (url.isNotEmpty && !_urlRe.hasMatch(url)) {
        return 'Standing document URL must start with http:// or https://';
      }
      final domain = _regDomain.text.trim();
      if (domain.isNotEmpty && !_domainRe.hasMatch(domain)) {
        return 'Registration domain format is invalid (e.g. acme.com).';
      }
      if (domain.isNotEmpty && domain.length > 253) {
        return 'Registration domain must be 253 characters or fewer.';
      }
      final contact = _designateContact.text.trim();
      if (contact.length > 200) {
        return 'Contact name must be 200 characters or fewer.';
      }
      final addr = _address.text.trim();
      if (addr.length > 500) {
        return 'Address must be 500 characters or fewer.';
      }
    }

    if (_isOrganization) {
      if (_purpose.text.trim().length < 10) return 'Purpose must be at least 10 characters.';
      if (_email.text.trim().isEmpty) return 'Email is required.';
      final orgEmail = _email.text.trim();
      if (!_emailRe.hasMatch(orgEmail)) return 'Email format is invalid.';
    }

    return null;
  }

  Future<void> _handleCreate() async {
    final validationError = _validate();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    final nameText = _name.text.trim();
    setState(() { _submitting = true; _error = null; });

    try {
      final auth = ref.read(authControllerProvider);
      final fieldCtrl = ref.read(fieldControllerProvider.notifier);

      if (_isAlliance) {
        final realm = await RealmService.instance.createRealm(
          name: nameText, type: 'alliance',
          handle: _handle.text.trim(),
          description: _description.text.trim(),
          purpose: _sharedPurpose.text.trim(),
          visibility: _visibility, walletEnabled: true, authToken: auth.token,
        );
        if (mounted) fieldCtrl.onRealmCreated(realm);
      } else if (_isInstitution) {
        final realm = await RealmService.instance.createRealm(
          name: nameText, type: 'institution',
          handle: _handle.text.trim(),
          description: _description.text.trim(),
          purpose: _sharedPurpose.text.trim(),
          config: {
            'entityType': _entityType,
            if (_regDomain.text.trim().isNotEmpty)
              'registrationDomain': _regDomain.text.trim(),
            if (_standingDocUrl.text.trim().isNotEmpty)
              'standingDocUrl': _standingDocUrl.text.trim(),
            if (_designateContact.text.trim().isNotEmpty)
              'designateContact': _designateContact.text.trim(),
            if (_designateEmail.text.trim().isNotEmpty)
              'designateEmail': _designateEmail.text.trim(),
            if (_address.text.trim().isNotEmpty)
              'address': _address.text.trim(),
          },
          walletEnabled: true, authToken: auth.token,
        );
        if (mounted) fieldCtrl.onRealmCreated(realm);
      } else if (_isOrganization) {
        // Organization: parentId is the genesis Ecosystem
        final ecosystemState = ref.read(ecosystemControllerProvider);
        final parentId = ecosystemState.genesis?.id;

        final realm = await RealmService.instance.createRealm(
          name: nameText, type: 'organization',
          parentId: parentId,
          purpose: _purpose.text.trim(),
          email: _email.text.trim(),
          config: {
            if (_registration.text.trim().isNotEmpty)
              'registration': _registration.text.trim(),
          },
          authToken: auth.token,
        );
        if (mounted) fieldCtrl.onRealmCreated(realm);
      } else {
        // Other types (chapter, guild, cooperative, etc.) — local UI-only for now
        await fieldCtrl.createRealm(
          name: nameText, type: _type, purpose: _purpose.text.trim(),
        );
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message ?? 'Something went wrong.');
    } catch (e) {
      if (mounted) setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.kiduna;
    final text = context.kidunaText;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Error banner ──────────────────────────────────────────
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(context.metrics.radiusMd),
                  border: Border.all(color: colors.gold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 18, color: colors.gold),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: text.bodySmall.copyWith(color: colors.gold))),
                    GestureDetector(
                      onTap: () => setState(() => _error = null),
                      child: Icon(Icons.close, size: 16, color: colors.quiet),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Row 1: Name + Handle (Alliance/Institution) or Type ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FieldTextInput(
                    label: _isAlliance ? l10n.allianceNameLabel
                        : _isInstitution ? l10n.institutionNameLabel
                        : _isOrganization ? l10n.organizationName
                        : l10n.realmName,
                    controller: _name,
                    hint: _isAlliance ? l10n.allianceNameHint
                        : _isInstitution ? l10n.institutionNameHint
                        : _isOrganization ? l10n.nameThisOrganization
                        : l10n.nameThisRealm,
                  ),
                ),
                const SizedBox(width: 12),
                if (_hasHandle)
                  Expanded(
                    child: _HandleField(
                      controller: _handle,
                      available: _handleAvailable,
                      checking: _handleChecking,
                      onChanged: _checkHandleAvailability,
                    ),
                  )
                else
                  Expanded(
                    child: FieldDropdown(
                      label: l10n.typeLabel, value: _type,
                      options: FieldFixtures.realmTypes,
                      onChanged: (v) => setState(() { _type = v; _error = null; }),
                    ),
                  ),
              ],
            ),

            // ── Type dropdown below name row for Alliance/Institution ─
            if (_hasHandle) ...[
              const SizedBox(height: 8),
              FieldDropdown(
                label: l10n.typeLabel, value: _type,
                options: FieldFixtures.realmTypes,
                onChanged: (v) => setState(() { _type = v; _error = null; }),
              ),
            ],
            const SizedBox(height: 12),

            // ═════════════════════════════════════════════════════════════
            // ── Institution-specific fields ──────────────────────────────
            // ═════════════════════════════════════════════════════════════
            if (_isInstitution) ...[
              _EntityTypeSelector(
                value: _entityType,
                onChanged: (v) => setState(() => _entityType = v),
              ),
              const SizedBox(height: 12),
              FieldTextInput(label: l10n.descriptionLabel, controller: _description,
                  hint: l10n.institutionDescriptionHint, maxLines: 3),
              const SizedBox(height: 12),
              FieldTextInput(label: l10n.purposeProjectLabel, controller: _sharedPurpose,
                  hint: l10n.institutionPurposeHint),
              const SizedBox(height: 12),
              FieldTextInput(label: l10n.registrationDomainLabel, controller: _regDomain,
                  hint: l10n.registrationDomainHint),
              const SizedBox(height: 12),
              FieldTextInput(label: l10n.standingDocUrlLabel, controller: _standingDocUrl,
                  hint: l10n.standingDocUrlHint),
              const SizedBox(height: 12),
              FieldTextInput(label: l10n.designateContactLabel, controller: _designateContact,
                  hint: l10n.designateContactHint),
              const SizedBox(height: 12),
              FieldTextInput(label: l10n.designateEmailLabel, controller: _designateEmail,
                  hint: l10n.designateEmailHint),
              const SizedBox(height: 12),
              FieldTextInput(label: l10n.addressLabel, controller: _address,
                  hint: l10n.addressHint, maxLines: 2),
              const SizedBox(height: 12),
              _ReadOnlyField(
                label: l10n.approvalThresholdLabel, value: '1 of 1',
                hint: l10n.approvalThresholdHint,
              ),
            ],

            // ═════════════════════════════════════════════════════════════
            // ── Alliance-specific fields ─────────────────────────────────
            // ═════════════════════════════════════════════════════════════
            if (_isAlliance) ...[
              FieldTextInput(label: l10n.descriptionLabel, controller: _description,
                  hint: l10n.allianceDescriptionHint, maxLines: 3),
              const SizedBox(height: 12),
              FieldTextInput(label: l10n.purposeProjectLabel, controller: _sharedPurpose,
                  hint: l10n.alliancePurposeHint),
              const SizedBox(height: 12),
              _VisibilitySelector(value: _visibility, onChanged: (v) => setState(() => _visibility = v)),
              const SizedBox(height: 12),
              _ReadOnlyField(
                label: l10n.approvalThresholdLabel, value: '1 of 1',
                hint: l10n.approvalThresholdHint,
              ),
            ],

            // ═════════════════════════════════════════════════════════════
            // ── Organization-specific fields ─────────────────────────────
            // ═════════════════════════════════════════════════════════════
            if (_isOrganization) ...[
              FieldTextInput(label: l10n.registrationLabel, controller: _registration, hint: l10n.registrationHint),
              const SizedBox(height: 12),
            ],

            // ── Purpose (Organization + Other types) ──────────────────
            if (!_isAlliance && !_isInstitution) ...[
              FieldTextInput(label: l10n.purpose, controller: _purpose,
                  hint: _isOrganization ? l10n.whatIsTheMissionYourMembersShare : l10n.whatShouldThisRealmBringIntoBeing,
                  maxLines: 3),
              const SizedBox(height: 12),
            ],

            // ── Email (Organization only) ─────────────────────────────
            if (_isOrganization) ...[
              FieldTextInput(label: l10n.emailLabel, controller: _email, hint: l10n.emailHint),
              const SizedBox(height: 12),
            ],

            // ── Portrait preview ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
                  colors.gold.withValues(alpha: 0.05), colors.sky.withValues(alpha: 0.035),
                ]),
                border: Border.all(color: colors.gold.withValues(alpha: 0.24)),
                borderRadius: BorderRadius.circular(context.metrics.radiusPanel),
              ),
              child: Row(children: [
                Container(width: 74, height: 74, decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.gold.withValues(alpha: 0.4)),
                  boxShadow: [BoxShadow(color: colors.gold.withValues(alpha: 0.1), blurRadius: 24)],
                  image: DecorationImage(image: ResizeImage(
                    AssetImage(AppAssets.realmEmblem(_type)),
                    width: (74 * MediaQuery.devicePixelRatioOf(context)).round(),
                    height: (74 * MediaQuery.devicePixelRatioOf(context)).round(),
                  ), fit: BoxFit.cover),
                )),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l10n.realmPortrait, style: text.h5.copyWith(color: colors.cream, fontSize: 17, height: 1.1)),
                  const SizedBox(height: 5),
                  Text(l10n.defaultPortraitDescription, style: text.micro.copyWith(color: colors.muted, fontSize: 9, height: 1.45)),
                ])),
                const SizedBox(width: 10),
                OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 30), padding: const EdgeInsets.symmetric(horizontal: 12),
                  foregroundColor: colors.skyButtonInk, backgroundColor: colors.sky,
                  side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                ), child: Text(l10n.create, style: text.label.copyWith(color: colors.skyButtonInk, fontWeight: FontWeight.w700))),
              ]),
            ),
            const SizedBox(height: 14),

            // ── Create button ─────────────────────────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: ListenableBuilder(
                listenable: Listenable.merge([_name, _purpose, _email, _handle, _sharedPurpose]),
                builder: (context, _) {
                  final nameOk = _name.text.trim().isNotEmpty;
                  bool canCreate;
                  if (_isAlliance || _isInstitution) {
                    final handleOk = _handle.text.trim().isNotEmpty && _handleAvailable != false;
                    canCreate = nameOk && handleOk && !_submitting;
                  } else if (_isOrganization) {
                    final purposeOk = _purpose.text.trim().length >= 10;
                    final emailOk = _email.text.trim().isNotEmpty;
                    canCreate = nameOk && purposeOk && emailOk && !_submitting;
                  } else {
                    canCreate = nameOk && !_submitting;
                  }
                  return FieldPrimaryButton(
                    label: _submitting ? l10n.creating
                        : _isAlliance ? l10n.createAllianceAction
                        : _isInstitution ? l10n.createInstitutionAction
                        : _isOrganization ? l10n.createOrganizationAction
                        : l10n.createRealmAction,
                    onPressed: canCreate ? _handleCreate : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared helper widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _HandleField extends StatelessWidget {
  const _HandleField({required this.controller, required this.available, required this.checking, required this.onChanged});
  final TextEditingController controller; final bool? available; final bool checking; final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna; final textTheme = context.kidunaText; final l10n = context.l10n;
    final inputStyle = textTheme.caption.copyWith(color: colors.text, height: 1.4);
    Widget? suffixWidget;
    if (checking) suffixWidget = SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: colors.quiet));
    else if (available == true) suffixWidget = Icon(Icons.check_circle, size: 16, color: colors.sky);
    else if (available == false) suffixWidget = Icon(Icons.cancel, size: 16, color: colors.gold);
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(context.metrics.radiusMd),
      borderSide: BorderSide(color: available == false ? colors.gold : colors.camel.withValues(alpha: 0.24)));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ConstrainedBox(constraints: const BoxConstraints(minHeight: 26), child: Row(children: [
        Text(l10n.handleLabel, style: textTheme.label.copyWith(color: colors.cream)),
        Text(' *', style: textTheme.label.copyWith(color: colors.gold)),
      ])),
      const SizedBox(height: 6),
      TextField(controller: controller, maxLength: 25, onChanged: onChanged, style: inputStyle,
        decoration: InputDecoration(isDense: true, filled: true, fillColor: const Color.fromRGBO(6, 3, 4, 0.66),
          prefixText: '@ ', prefixStyle: inputStyle.copyWith(color: colors.quiet), counterText: '',
          suffixIcon: suffixWidget != null ? Padding(padding: const EdgeInsets.only(right: 8), child: suffixWidget) : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 20, minHeight: 20),
          hintText: l10n.handleHint, hintStyle: inputStyle.copyWith(color: colors.quiet),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          constraints: const BoxConstraints(minHeight: 37, maxHeight: 37),
          border: border, enabledBorder: border, focusedBorder: border.copyWith(borderSide: BorderSide(color: colors.sky)))),
      if (available == false) Padding(padding: const EdgeInsets.only(top: 4),
        child: Text(l10n.handleTaken, style: textTheme.micro.copyWith(color: colors.gold))),
    ]);
  }
}

class _VisibilitySelector extends StatelessWidget {
  const _VisibilitySelector({required this.value, required this.onChanged});
  final String value; final ValueChanged<String> onChanged;
  static const _options = ['public', 'private', 'secret'];
  static const _labels = ['Public', 'Private', 'Secret'];

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna; final textTheme = context.kidunaText; final l10n = context.l10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FieldLabel(text: l10n.visibilityLabel),
      const SizedBox(height: 8),
      Row(children: List.generate(_options.length, (i) {
        final selected = value == _options[i];
        return Padding(padding: EdgeInsets.only(right: i < _options.length - 1 ? 8 : 0),
          child: GestureDetector(onTap: () => onChanged(_options[i]),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? colors.gold.withValues(alpha: 0.15) : const Color.fromRGBO(6, 3, 4, 0.66),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? colors.gold : colors.camel.withValues(alpha: 0.24))),
              child: Text(_labels[i], style: textTheme.label.copyWith(
                color: selected ? colors.gold : colors.quiet,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500)))));
      })),
    ]);
  }
}

/// Entity type selector — 6 chips for Institution.
class _EntityTypeSelector extends StatelessWidget {
  const _EntityTypeSelector({required this.value, required this.onChanged});
  final String value; final ValueChanged<String> onChanged;
  static const _options = ['company', 'government', 'charity', 'ngo', 'education', 'other'];
  static const _labels = ['Company', 'Government', 'Charity', 'NGO', 'Education', 'Other'];

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna; final textTheme = context.kidunaText; final l10n = context.l10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FieldLabel(text: l10n.entityTypeLabel),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: List.generate(_options.length, (i) {
        final selected = value == _options[i];
        return GestureDetector(onTap: () => onChanged(_options[i]),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? colors.gold.withValues(alpha: 0.15) : const Color.fromRGBO(6, 3, 4, 0.66),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? colors.gold : colors.camel.withValues(alpha: 0.24))),
            child: Text(_labels[i], style: textTheme.label.copyWith(
              color: selected ? colors.gold : colors.quiet,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500))));
      })),
    ]);
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value, this.hint});
  final String label; final String value; final String? hint;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna; final textTheme = context.kidunaText;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      FieldLabel(text: label),
      const SizedBox(height: 6),
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        constraints: const BoxConstraints(minHeight: 37),
        decoration: BoxDecoration(color: const Color.fromRGBO(6, 3, 4, 0.66),
          borderRadius: BorderRadius.circular(context.metrics.radiusMd),
          border: Border.all(color: colors.camel.withValues(alpha: 0.24))),
        child: Text(value, style: textTheme.caption.copyWith(color: colors.quiet, height: 1.4))),
      if (hint != null) ...[const SizedBox(height: 4),
        Text(hint!, style: textTheme.micro.copyWith(color: colors.quiet.withValues(alpha: 0.6)))],
    ]);
  }
}