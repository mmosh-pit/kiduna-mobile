import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/logger.dart';
import '../../../data/services/task_service.dart';
import '../../field/controllers/ki_chat_controller.dart';
import '../data/task_model.dart';

/// UI state for the Apiary task board.
@immutable
class ApiaryState {
  const ApiaryState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.expandedTaskId,
  });

  /// All tasks across every stage.
  final List<TaskModel> tasks;
  final bool isLoading;
  final String? error;

  /// ID of the currently expanded task card, or `null` if none.
  final String? expandedTaskId;

  /// Tasks filtered by stage — used by each column.
  List<TaskModel> tasksForStage(TaskStage stage) =>
      tasks.where((t) => t.stage == stage).toList();

  /// Count of tasks in a given stage.
  int countForStage(TaskStage stage) =>
      tasks.where((t) => t.stage == stage).length;

  ApiaryState copyWith({
    List<TaskModel>? tasks,
    bool? isLoading,
    String? error,
    String? expandedTaskId,
    bool clearError = false,
    bool clearExpanded = false,
  }) {
    return ApiaryState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      expandedTaskId:
          clearExpanded ? null : (expandedTaskId ?? this.expandedTaskId),
    );
  }
}

/// Manages the Apiary board — loading tasks, expanding cards, and
/// auto-refreshing when Ki finishes a conversation turn.
class ApiaryController extends Notifier<ApiaryState> {
  /// Tracks Ki streaming state so we can detect transitions.
  bool _wasStreaming = false;

  @override
  ApiaryState build() {
    // Watch Ki chat state — when streaming finishes, refresh the board.
    final chatState = ref.watch(kiChatControllerProvider);
    if (_wasStreaming && !chatState.isStreaming) {
      // Ki just finished responding — schedule a refresh.
      Future.microtask(() => refreshTasks());
    }
    _wasStreaming = chatState.isStreaming;

    // Initial load.
    Future.microtask(() => loadTasks());
    return const ApiaryState(isLoading: true);
  }

  /// Fetch tasks from the service (or fixtures).
  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tasks = await TaskService.instance.fetchTasks();
      if (!ref.mounted) return;
      state = state.copyWith(tasks: tasks, isLoading: false);
      AppLogger.info(
        'Apiary loaded ${tasks.length} tasks',
        tag: 'Apiary',
      );
    } catch (e) {
      if (!ref.mounted) return;
      AppLogger.error('Failed to load tasks', tag: 'Apiary', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load tasks.',
      );
    }
  }

  /// Re-fetch tasks — called after Ki finishes a conversation turn.
  Future<void> refreshTasks() async {
    try {
      final tasks = await TaskService.instance.fetchTasks();
      if (!ref.mounted) return;
      state = state.copyWith(tasks: tasks);
    } catch (e) {
      // Silent refresh failure — don't overwrite existing tasks.
      AppLogger.warning('Task refresh failed: $e', tag: 'Apiary');
    }
  }

  /// Expand a task card to show full details.
  void expandTask(String taskId) {
    // Toggle — tap same card again to collapse.
    if (state.expandedTaskId == taskId) {
      state = state.copyWith(clearExpanded: true);
    } else {
      state = state.copyWith(expandedTaskId: taskId);
    }
  }

  /// Collapse the currently expanded task card.
  void collapseTask() {
    state = state.copyWith(clearExpanded: true);
  }

  /// Send context about a task field to Ki.
  ///
  /// When the user taps a specific field on a task card (title, assignee,
  /// category, etc.), we format a contextual message and send it to Ki
  /// so Ki can respond intelligently.
  void sendTaskContext(String taskId, String field) {
    final task = state.tasks.where((t) => t.id == taskId).firstOrNull;
    if (task == null) return;

    final String message;
    switch (field) {
      case 'title':
        message = 'Tell me more about the task: "${task.title}"';
      case 'assignee':
        if (task.isAssigned) {
          message =
              'Tell me about ${task.assignee} working on "${task.title}"';
        } else {
          message = 'Who should be assigned to "${task.title}"?';
        }
      case 'category':
        message =
            'What does the ${task.category} category mean for "${task.title}"?';
      case 'stage':
        message =
            'What is the status of "${task.title}"? It is currently in '
            '${task.stage.label}.';
      case 'advance':
        final next = task.stage.next;
        if (next != null) {
          message =
              'Move the task "${task.title}" from ${task.stage.label} '
              'to ${next.label}.';
        } else {
          message = 'The task "${task.title}" is already live.';
        }
      default:
        message = 'Tell me about the task: "${task.title}"';
    }

    ref.read(kiChatControllerProvider.notifier).sendMessage(message);
  }
}

/// Global Apiary board state provider.
final apiaryControllerProvider =
    NotifierProvider<ApiaryController, ApiaryState>(ApiaryController.new);
