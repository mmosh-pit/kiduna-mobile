import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// The Navigation panel body: the Realm ancestry breadcrumb. For the Newly
/// Created Ecosystem this is a single chip for the current Realm.
class NavigationPanel extends StatelessWidget {
  const NavigationPanel({super.key, required this.realmName});

  final String realmName;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.raised.withValues(alpha: 0.5),
              border: Border.all(color: colors.camel.withValues(alpha: 0.24)),
              borderRadius: BorderRadius.circular(context.metrics.radiusSm),
            ),
            child: Text(
              realmName,
              style: context.kidunaText.bodySmall.copyWith(color: colors.cream),
            ),
          ),
        ],
      ),
    );
  }
}
