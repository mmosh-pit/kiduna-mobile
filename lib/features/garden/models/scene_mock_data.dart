import 'package:flutter/material.dart';

/// A scene (mini app) available in the Garden section.
@immutable
class SceneMockItem {
  const SceneMockItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.status,
    required this.icon,
    this.iconUrl,
    this.imageUrls = const [],
  });

  final String id;
  final String name;
  final String description;

  /// One of: 'productivity', 'game', 'wellness', 'finance', 'lifestyle'.
  final String category;

  /// One of: 'available', 'coming_soon'.
  final String status;

  /// Fallback Material icon (used when [iconUrl] fails to load).
  final IconData icon;

  /// Network icon URL (Pinata/IPFS hosted).
  final String? iconUrl;

  /// Gallery image URLs for the scene preview/screenshots.
  final List<String> imageUrls;

  bool get isAvailable => status == 'available';
  bool get isComingSoon => status == 'coming_soon';

  String get categoryLabel {
    switch (category) {
      case 'productivity': return 'Productivity';
      case 'game':         return 'Game';
      case 'wellness':     return 'Wellness';
      case 'finance':      return 'Finance';
      case 'lifestyle':    return 'Lifestyle';
      default:             return category;
    }
  }

  String get statusLabel => isAvailable ? 'Available' : 'Coming Soon';
}

/// Static mock scenes for UI development.
const List<SceneMockItem> kMockScenes = [
  SceneMockItem(
    id: 'scene-task-tracker',
    name: 'Task Tracker',
    description: 'Track and manage your daily tasks with boards, lists, and deadlines.',
    category: 'productivity',
    status: 'available',
    icon: Icons.check_circle_outline_rounded,
    iconUrl: 'https://indigo-neat-vulture-132.mypinata.cloud/ipfs/bafybeihyp5f6j7elsn5xf6sworcjtxctas5qbdhrhmaupruahjigcslsh4',
  ),
  SceneMockItem(
    id: 'scene-isometric-game',
    name: 'Isometric Game',
    description: 'Explore vibrant worlds rendered in beautiful isometric perspective.',
    category: 'game',
    status: 'available',
    icon: Icons.videogame_asset_rounded,
    iconUrl: 'https://indigo-neat-vulture-132.mypinata.cloud/ipfs/bafybeighc3t4h4hb5up5owflxjdggljm5y4kw4jgf475wlmwulca4ubz5q',
  ),
  SceneMockItem(
    id: 'scene-habit-builder',
    name: 'Habit Builder',
    description: 'Build positive daily habits with streaks, reminders, and insights.',
    category: 'wellness',
    status: 'coming_soon',
    icon: Icons.emoji_events_rounded,
    iconUrl: 'https://indigo-neat-vulture-132.mypinata.cloud/ipfs/bafybeifp24q6wiwbh2itvg2ncit22uvoavlwthxdkijorcoxzjeecm2lm4',
  ),
  SceneMockItem(
    id: 'scene-budget-planner',
    name: 'Budget Planner',
    description: 'Plan and track your expenses with categories and visual breakdowns.',
    category: 'finance',
    status: 'available',
    icon: Icons.account_balance_wallet_rounded,
    iconUrl: 'https://indigo-neat-vulture-132.mypinata.cloud/ipfs/bafybeihhttslegtxwavvifb4lw4fh3agahpkauu4hrrflhr2zl3elkqhca',
  ),
  SceneMockItem(
    id: 'scene-recipe-book',
    name: 'Recipe Book',
    description: 'Discover, save, and organise your favourite recipes in one place.',
    category: 'lifestyle',
    status: 'coming_soon',
    icon: Icons.restaurant_menu_rounded,
    iconUrl: 'https://indigo-neat-vulture-132.mypinata.cloud/ipfs/bafybeig3qzf5mpfk3e5wbymfpclcerxeyoxknunhxsnw4itwftauqvvgtm',
  ),
  SceneMockItem(
    id: 'scene-quiz-arena',
    name: 'Quiz Arena',
    description: 'Test your knowledge across topics with timed challenges and leaderboards.',
    category: 'game',
    status: 'available',
    icon: Icons.quiz_rounded,
    iconUrl: 'https://indigo-neat-vulture-132.mypinata.cloud/ipfs/bafybeiamzqg2a76djocbcquqdl4lbiribqog2jlfecpu3lc36o5bt52ctq',
  ),
];
