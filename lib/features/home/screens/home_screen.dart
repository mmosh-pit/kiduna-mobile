import 'package:flutter/material.dart';

import '../../../config/constants.dart';
import '../../../core/extensions/context_extensions.dart';

/// Landing screen shown at app start.
///
/// Placeholder for the base setup — replace with the real home feature once
/// routing and controllers are wired.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.rocket_launch_outlined,
                size: 64,
                color: context.colors.primary,
              ),
              const SizedBox(height: AppConstants.spacingMd),
              Text(
                'Welcome to ${AppConstants.appName}',
                style: context.textStyles.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                'Base project ready. Start building features.',
                style: context.textStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
