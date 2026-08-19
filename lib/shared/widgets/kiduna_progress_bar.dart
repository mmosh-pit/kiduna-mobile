import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';

class KidunaProgressBar extends StatelessWidget {
  const KidunaProgressBar({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  final int totalSteps;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Row(
      children: List.generate(totalSteps, (index) {
        final step = index + 1;
        final isDone = step < currentStep;
        final isCurrent = step == currentStep;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < totalSteps - 1 ? 5 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isDone || isCurrent ? colors.sky : colors.line,
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: colors.sky.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      }),
    );
  }
}
