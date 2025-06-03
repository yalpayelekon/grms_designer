import 'dart:async';
import 'package:grms_designer/utils/core/logger.dart';

import 'polling_task.dart';

class CentralizedPollingService {
  final Map<String, PollingTaskInfo> _tasks = {};
  final StreamController<PollingTaskInfo> _taskUpdateController =
      StreamController<PollingTaskInfo>.broadcast();
  bool _disposed = false;

  Stream<PollingTaskInfo> get taskUpdates => _taskUpdateController.stream;

  Map<String, PollingTaskInfo> get tasks => Map.unmodifiable(_tasks);

  void registerTask(PollingTask task) {
    if (_disposed) return;

    if (_tasks.containsKey(task.id)) {
      logWarning('Task with ID ${task.id} already exists, replacing it');
      stopTask(task.id);
    }

    _tasks[task.id] = PollingTaskInfo(task: task, state: PollingTaskState.idle);

    logInfo('Registered polling task: ${task.name} (${task.id})');
  }

  Future<bool> startTask(String taskId) async {
    if (_disposed) return false;

    final taskInfo = _tasks[taskId];
    if (taskInfo == null) {
      logError('Task not found: $taskId');
      return false;
    }

    if (taskInfo.state == PollingTaskState.running) {
      logWarning('Task $taskId is already running');
      return true;
    }

    try {
      taskInfo.timer?.cancel();

      _updateTaskInfo(
        taskId,
        taskInfo.copyWith(state: PollingTaskState.running),
      );

      taskInfo.task.onStart();

      await _executeTask(taskId);

      final timer = Timer.periodic(taskInfo.task.interval, (_) {
        if (!_disposed && _tasks[taskId]?.state == PollingTaskState.running) {
          _executeTask(taskId);
        }
      });

      _updateTaskInfo(taskId, _tasks[taskId]!.copyWith(timer: timer));

      logInfo('Started polling task: ${taskInfo.task.name}');
      return true;
    } catch (e, stackTrace) {
      logError('Error starting task $taskId: $e', stackTrace: stackTrace);
      _updateTaskInfo(taskId, taskInfo.copyWith(state: PollingTaskState.error));
      return false;
    }
  }

  void stopTask(String taskId) {
    if (_disposed) return;

    final taskInfo = _tasks[taskId];
    if (taskInfo == null) {
      logWarning('Task not found: $taskId');
      return;
    }

    taskInfo.timer?.cancel();
    taskInfo.task.onStop();

    _updateTaskInfo(
      taskId,
      taskInfo.copyWith(state: PollingTaskState.stopped, timer: null),
    );

    logInfo('Stopped polling task: ${taskInfo.task.name}');
  }

  void pauseTask(String taskId) {
    if (_disposed) return;

    final taskInfo = _tasks[taskId];
    if (taskInfo == null || taskInfo.state != PollingTaskState.running) {
      return;
    }

    taskInfo.timer?.cancel();

    _updateTaskInfo(
      taskId,
      taskInfo.copyWith(state: PollingTaskState.paused, timer: null),
    );

    logInfo('Paused polling task: ${taskInfo.task.name}');
  }

  Future<bool> resumeTask(String taskId) async {
    if (_disposed) return false;

    final taskInfo = _tasks[taskId];
    if (taskInfo?.state != PollingTaskState.paused) {
      return false;
    }

    return await startTask(taskId);
  }

  Future<void> startAllTasks() async {
    final taskIds = _tasks.keys.toList();
    for (final taskId in taskIds) {
      await startTask(taskId);
    }
  }

  void stopAllTasks() {
    final taskIds = _tasks.keys.toList();
    for (final taskId in taskIds) {
      stopTask(taskId);
    }
  }

  void pauseAllTasks() {
    final taskIds = _tasks.keys.toList();
    for (final taskId in taskIds) {
      pauseTask(taskId);
    }
  }

  Future<void> resumeAllTasks() async {
    final taskIds = _tasks.keys.toList();
    for (final taskId in taskIds) {
      final taskInfo = _tasks[taskId];
      if (taskInfo?.state == PollingTaskState.paused) {
        await resumeTask(taskId);
      }
    }
  }

  void unregisterTask(String taskId) {
    stopTask(taskId);
    _tasks.remove(taskId);
    logInfo('Unregistered polling task: $taskId');
  }

  PollingTaskInfo? getTaskInfo(String taskId) {
    return _tasks[taskId];
  }

  List<PollingTaskInfo> getTasksByState(PollingTaskState state) {
    return _tasks.values.where((info) => info.state == state).toList();
  }

  Future<bool> updateTaskInterval(String taskId, Duration newInterval) async {
    final taskInfo = _tasks[taskId];
    if (taskInfo == null) return false;

    final wasRunning = taskInfo.state == PollingTaskState.running;

    if (wasRunning) {
      stopTask(taskId);
    }

    final updatedTask = _createTaskWithNewInterval(taskInfo.task, newInterval);
    if (updatedTask == null) return false;

    _tasks[taskId] = taskInfo.copyWith(task: updatedTask);

    if (wasRunning) {
      return await startTask(taskId);
    }

    return true;
  }

  Future<PollingResult?> executeTaskNow(String taskId) async {
    if (_disposed) return null;

    final taskInfo = _tasks[taskId];
    if (taskInfo == null) return null;

    return await _executeTask(taskId);
  }

  Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{};

    stats['totalTasks'] = _tasks.length;
    stats['runningTasks'] = getTasksByState(PollingTaskState.running).length;
    stats['pausedTasks'] = getTasksByState(PollingTaskState.paused).length;
    stats['errorTasks'] = getTasksByState(PollingTaskState.error).length;
    stats['idleTasks'] = getTasksByState(PollingTaskState.idle).length;

    final executionCounts = _tasks.values.map((info) => info.executionCount);
    stats['totalExecutions'] = executionCounts.fold(
      0,
      (sum, count) => sum + count,
    );

    return stats;
  }

  Future<PollingResult?> _executeTask(String taskId) async {
    final taskInfo = _tasks[taskId];
    if (taskInfo == null || _disposed) return null;

    try {
      logDebug('Executing polling task: ${taskInfo.task.name}');

      final result = await taskInfo.task.execute();

      _updateTaskInfo(
        taskId,
        taskInfo.copyWith(
          lastExecution: DateTime.now(),
          lastResult: result,
          executionCount: taskInfo.executionCount + 1,
        ),
      );

      if (!result.success) {
        logWarning('Task ${taskInfo.task.name} failed: ${result.error}');
        taskInfo.task.onError(Exception(result.error), StackTrace.current);
      } else {
        logDebug('Task ${taskInfo.task.name} completed successfully');
      }

      return result;
    } catch (e, stackTrace) {
      logError(
        'Error executing task ${taskInfo.task.name}: $e',
        stackTrace: stackTrace,
      );

      final errorResult = PollingResult.failure(e.toString());

      _updateTaskInfo(
        taskId,
        taskInfo.copyWith(
          state: PollingTaskState.error,
          lastExecution: DateTime.now(),
          lastResult: errorResult,
          executionCount: taskInfo.executionCount + 1,
        ),
      );

      taskInfo.task.onError(e, stackTrace);
      return errorResult;
    }
  }

  void _updateTaskInfo(String taskId, PollingTaskInfo newInfo) {
    _tasks[taskId] = newInfo;

    if (!_taskUpdateController.isClosed) {
      _taskUpdateController.add(newInfo);
    }
  }

  PollingTask? _createTaskWithNewInterval(
    PollingTask originalTask,
    Duration newInterval,
  ) {
    logWarning(
      'Task interval update not implemented for ${originalTask.runtimeType}',
    );
    return null;
  }

  void dispose() {
    if (_disposed) return;

    _disposed = true;
    stopAllTasks();
    _taskUpdateController.close();
    _tasks.clear();

    logInfo('Centralized polling service disposed');
  }
}
