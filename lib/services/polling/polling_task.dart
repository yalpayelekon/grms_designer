import 'dart:async';

abstract class PollingTask {
  final String id;
  final String name;
  final Duration interval;
  final Map<String, dynamic> parameters;

  PollingTask({
    required this.id,
    required this.name,
    required this.interval,
    this.parameters = const {},
  });

  Future<PollingResult> execute();

  void onStart() {}

  void onStop() {}

  void onError(Object error, StackTrace stackTrace) {}
}

class PollingResult {
  final bool success;
  final dynamic data;
  final String? error;
  final DateTime timestamp;

  PollingResult.success(this.data)
    : success = true,
      error = null,
      timestamp = DateTime.now();

  PollingResult.failure(this.error)
    : success = false,
      data = null,
      timestamp = DateTime.now();
}

enum PollingTaskState { idle, running, paused, stopped, error }

class PollingTaskInfo {
  final PollingTask task;
  final PollingTaskState state;
  final Timer? timer;
  final DateTime? lastExecution;
  final PollingResult? lastResult;
  final int executionCount;

  PollingTaskInfo({
    required this.task,
    required this.state,
    this.timer,
    this.lastExecution,
    this.lastResult,
    this.executionCount = 0,
  });

  PollingTaskInfo copyWith({
    PollingTask? task,
    PollingTaskState? state,
    Timer? timer,
    DateTime? lastExecution,
    PollingResult? lastResult,
    int? executionCount,
  }) {
    return PollingTaskInfo(
      task: task ?? this.task,
      state: state ?? this.state,
      timer: timer ?? this.timer,
      lastExecution: lastExecution ?? this.lastExecution,
      lastResult: lastResult ?? this.lastResult,
      executionCount: executionCount ?? this.executionCount,
    );
  }
}
