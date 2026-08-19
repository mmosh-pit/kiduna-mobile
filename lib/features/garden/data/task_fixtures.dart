import 'task_model.dart';

/// Mock tasks for the Apiary board during development.
///
/// These map to real-ish work items from the current sprint so the demo
/// feels authentic. Replace with API calls via [TaskService] once the
/// backend endpoints are live.
abstract class TaskFixtures {
  const TaskFixtures._();

  static final List<TaskModel> tasks = [
    TaskModel(
      id: 'task_001',
      title: 'Beehive background rendering',
      subtitle: 'Asset management',
      description:
          'Render the 4K beehive backdrop with proper scaling across '
          'desktop and web. Should scale proportionally without distortion.',
      stage: TaskStage.build,
      category: 'wind',
      assignee: 'Muthu',
      estimatedHours: 6,
      createdBy: 'David',
      createdAt: DateTime(2026, 8, 18, 8),
    ),
    TaskModel(
      id: 'task_002',
      title: 'Stage column layout',
      subtitle: 'Apiary board',
      description:
          'Build the five-column board layout with Ready, Build, Test, '
          'Release, and Live columns. Cards should be scrollable within '
          'each column.',
      stage: TaskStage.build,
      category: 'portal',
      assignee: 'Aashik',
      estimatedHours: 4,
      createdBy: 'David',
      createdAt: DateTime(2026, 8, 18, 8),
    ),
    TaskModel(
      id: 'task_003',
      title: 'Invitation system for Apiary',
      subtitle: 'Access control',
      description:
          'Implement role-based invitations so users can invite team '
          'members with specific roles like editor, contributor, tester.',
      stage: TaskStage.ready,
      category: 'shield',
      estimatedHours: 8,
      createdBy: 'David',
      createdAt: DateTime(2026, 8, 18, 8),
    ),
    TaskModel(
      id: 'task_004',
      title: 'Bee sprite animations',
      subtitle: 'Asset management',
      description:
          'Integrate three animation cycles for bee entities: idle, walk, '
          'and waggle dance. Sigils displayed on thorax.',
      stage: TaskStage.ready,
      category: 'flower',
      estimatedHours: 12,
      createdBy: 'David',
      createdAt: DateTime(2026, 8, 18, 8),
    ),
    TaskModel(
      id: 'task_005',
      title: 'Task actor with Ki integration',
      subtitle: 'Agent orchestration',
      description:
          'Each task is an actor. Tapping any field on a task card sends '
          'context to Ki. Ki should respond based on what was tapped.',
      stage: TaskStage.ready,
      category: 'spark',
      assignee: 'Jeya',
      estimatedHours: 10,
      createdBy: 'David',
      createdAt: DateTime(2026, 8, 18, 8),
    ),
    TaskModel(
      id: 'task_006',
      title: 'CICD for public repository',
      subtitle: 'Infrastructure',
      description:
          'Set up continuous integration and deployment pipeline for the '
          'public repository. Previous version exists but needs update.',
      stage: TaskStage.test,
      category: 'wind',
      assignee: 'Sucil',
      estimatedHours: 4,
      createdBy: 'David',
      createdAt: DateTime(2026, 8, 17, 10),
    ),
    TaskModel(
      id: 'task_007',
      title: 'Desktop application build',
      subtitle: 'Distribution',
      description:
          'Package the Flutter app as a downloadable desktop application '
          'for macOS, Windows, and Linux.',
      stage: TaskStage.ready,
      category: 'wind',
      estimatedHours: 6,
      createdBy: 'David',
      createdAt: DateTime(2026, 8, 18, 9),
    ),
    TaskModel(
      id: 'task_008',
      title: 'Commit review and monitoring',
      subtitle: 'Quality assurance',
      description:
          'Review all incoming commits for code quality, architecture '
          'compliance, and test coverage.',
      stage: TaskStage.live,
      category: 'shield',
      assignee: 'Sriram',
      estimatedHours: 0,
      createdBy: 'David',
      createdAt: DateTime(2026, 8, 17, 8),
    ),
  ];
}
