import 'package:flutter/material.dart';

import '../widgets/apiary_board.dart';

/// Root screen for the Garden section — the Apiary task board.
///
/// This widget is passed as `content` to the existing [_ContentKiWide] /
/// [_ContentKiNarrow] layout wrappers in `field_screen.dart`, which place
/// the board on the left and Ki chat on the right.
class ApiaryScreen extends StatelessWidget {
  const ApiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ApiaryBoard();
  }
}
