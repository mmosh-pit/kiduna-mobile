import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/utils/logger.dart';
import '../../features/garden/data/task_fixtures.dart';
import '../../features/garden/data/task_model.dart';

/// Handles task CRUD via the kinship-agent API.
///
/// Falls back to [TaskFixtures] when the backend endpoint is not yet
/// available — swap out the fallback once `/api/tasks` is live.
class TaskService {
  TaskService._();

  static final TaskService instance = TaskService._();

  /// Fetch all tasks for the current context.
  ///
  /// Tries the real API first; if the endpoint returns 404 (not yet
  /// deployed), falls back to fixture data so the board is never empty.
  Future<List<TaskModel>> fetchTasks() async {
    try {
      final response = await ApiClient.instance.dio.get<dynamic>(
        ApiEndpoints.tasks,
      );

      final body = response.data;
      if (body is List) {
        final result = body
            .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
            .toList();
        AppLogger.info('Loaded ${result.length} tasks from API',
            tag: 'TaskService');
        return result;
      }

      // If body wraps in { "tasks": [...] }
      if (body is Map<String, dynamic>) {
        final list = body['tasks'] as List<dynamic>? ?? [];
        final result = list
            .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
            .toList();
        AppLogger.info('Loaded ${result.length} tasks from API',
            tag: 'TaskService');
        return result;
      }

      return TaskFixtures.tasks;
    } catch (e) {
      AppLogger.warning(
        'Tasks API not available, using fixtures: $e',
        tag: 'TaskService',
      );
      return TaskFixtures.tasks;
    }
  }

  /// Fetch a single task by ID.
  Future<TaskModel?> getTask(String id) async {
    try {
      final response = await ApiClient.instance.dio.get<Map<String, dynamic>>(
        ApiEndpoints.taskById(id),
      );

      final body = response.data;
      if (body == null) return null;
      return TaskModel.fromJson(body);
    } catch (e) {
      AppLogger.warning(
        'Task fetch failed, checking fixtures: $e',
        tag: 'TaskService',
      );
      // Fallback to fixture lookup.
      try {
        return TaskFixtures.tasks.firstWhere((t) => t.id == id);
      } catch (_) {
        return null;
      }
    }
  }
}