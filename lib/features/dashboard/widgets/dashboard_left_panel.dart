import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import 'ecosystem_panel.dart';
import 'user_profile_panel.dart';

class DashboardLeftPanel extends StatelessWidget {
  const DashboardLeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return ColoredBox(
      color: colors.field,
      child: Align(
        alignment: Alignment.topLeft,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EcosystemPanel(),
              SizedBox(height: 16),
              UserProfilePanel(),
            ],
          ),
        ),
      ),
    );
  }
}
