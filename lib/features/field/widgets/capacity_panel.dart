import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';

/// A capacity workspace body. Compact for now: the capacity's [detail] with the
/// rich, service-backed workspace (Wisdom drops, Presence editor, Connections,
/// Automations, Skills) added when those services exist. The panel title is
/// carried by the surrounding [FieldPanel] chrome.
class CapacityPanel extends StatelessWidget {
  const CapacityPanel({super.key, required this.detail});

  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Text(
        detail,
        style: context.kidunaText.bodySmall.copyWith(
          color: context.kiduna.muted,
        ),
      ),
    );
  }
}
