import 'package:flutter/material.dart';

import '../models/scene_mock_data.dart';
import '../widgets/scene_create_form.dart';
import '../widgets/scene_detail_view.dart';
import '../widgets/scene_grid_view.dart';

/// Root screen for the Garden section.
///
/// Manages: scene list (mock + user-created), internal navigation
/// (grid ↔ detail), and the create-scene bottom sheet.
class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  SceneMockItem? _selected;
  final List<SceneMockItem> _userScenes = [];

  List<SceneMockItem> get _allScenes => [...kMockScenes, ..._userScenes];

  void _openCreateForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SceneCreateForm(
        onCreated: (scene) {
          Navigator.of(context).pop();
          setState(() => _userScenes.add(scene));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${scene.name} created successfully'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _selected == null
          ? SceneGridView(
              key: const ValueKey('scene-grid'),
              scenes: _allScenes,
              onSceneTap: (scene) => setState(() => _selected = scene),
              onCreateTap: _openCreateForm,
            )
          : SceneDetailView(
              key: ValueKey('scene-detail-${_selected!.id}'),
              scene: _selected!,
              onBack: () => setState(() => _selected = null),
            ),
    );
  }
}
