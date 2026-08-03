import 'package:flutter/widgets.dart';

import 'tokens.dart';
import 'typography.dart';

/// The sky-blue Action rule.
///
/// > White or cream content is prohibited on every sky-blue filled button.
/// > The type and icons on a sky-blue button must match the exact local ground
/// > directly behind that button. The ink is contextual, not one universal
/// > brown.
/// >
/// > — `design-kit/studio-v1.7/DESIGN-SYSTEM.md`
///
/// The reference implementation inherits a `--sky-button-ink` CSS token set on
/// each material container. [KidunaGround] is the Flutter equivalent: wrap any
/// container that establishes a new ground, and [SkyAction] descendants take
/// their ink from it automatically.
///
/// The canon is explicit that no general button-colour rule may override this,
/// so ink is never accepted as a constructor argument.
class KidunaGround extends InheritedWidget {
  const KidunaGround({
    required this.ground,
    required super.child,
    super.key,
  });

  /// The exact local ground directly behind descendants.
  final Color ground;

  /// Defaults to the Field ground when no container has declared one.
  static Color of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KidunaGround>()?.ground ??
      Enamel.deepField;

  @override
  bool updateShouldNotify(KidunaGround oldWidget) => ground != oldWidget.ground;
}

/// A primary sky-blue Action.
///
/// The ink is resolved from the inherited [KidunaGround] and can never be passed
/// in. In debug builds, a ground light enough to read as white or cream trips
/// an assertion rather than silently violating the canon.
class SkyAction extends StatelessWidget {
  const SkyAction({required this.label, this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ink = KidunaGround.of(context);

    assert(
      ink.computeLuminance() < 0.35,
      'Sky-blue Action ink resolved to a light colour (${ink.toString()}). '
      'White or cream content is prohibited on sky-blue fills — the enclosing '
      'KidunaGround must declare a dark ground token.',
    );

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: Enamel.skyBlue,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(label, style: Type.control.copyWith(color: ink)),
      ),
    );
  }
}
