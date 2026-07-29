import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../controllers/field_controller.dart';
import '../data/field_fixtures.dart';
import 'field_inputs.dart';

/// The Form a New Realm working panel: name, type, and purpose, then Create.
class RealmPanel extends ConsumerStatefulWidget {
  const RealmPanel({super.key});

  @override
  ConsumerState<RealmPanel> createState() => _RealmPanelState();
}

class _RealmPanelState extends ConsumerState<RealmPanel> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _purpose = TextEditingController();
  String _type = 'Community';

  @override
  void dispose() {
    _name.dispose();
    _purpose.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          FieldTextInput(
            label: l10n.realmName,
            controller: _name,
            hint: 'Name this Realm',
          ),
          const SizedBox(height: 12),
          FieldDropdown(
            label: l10n.typeLabel,
            value: _type,
            options: FieldFixtures.realmTypes,
            onChanged: (value) => setState(() => _type = value),
          ),
          const SizedBox(height: 12),
          FieldTextInput(
            label: l10n.purpose,
            controller: _purpose,
            hint: 'What should this Realm bring into being?',
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _name,
            builder: (context, value, _) {
              final canCreate = value.text.trim().isNotEmpty;
              return FieldPrimaryButton(
                label: l10n.createRealmAction,
                onPressed: canCreate
                    ? () => ref
                          .read(fieldControllerProvider.notifier)
                          .createRealm(name: value.text.trim(), type: _type)
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}
