enum CommandPriority { low, normal, high, critical }

enum CommandStatus { queued, executing, completed, failed, timedOut, cancelled }

class CommandResult {
  final bool success;
  final String? response;
  final String? errorMessage;
  final int attemptsMade;
  final DateTime completedAt;

  CommandResult({
    required this.success,
    this.response,
    this.errorMessage,
    required this.attemptsMade,
    required this.completedAt,
  });

  factory CommandResult.success(String? response, int attempts) {
    return CommandResult(
      success: true,
      response: response,
      attemptsMade: attempts,
      completedAt: DateTime.now(),
    );
  }

  factory CommandResult.failure(String errorMessage, int attempts) {
    return CommandResult(
      success: false,
      errorMessage: errorMessage,
      attemptsMade: attempts,
      completedAt: DateTime.now(),
    );
  }

  factory CommandResult.timeout(int attempts) {
    return CommandResult(
      success: false,
      errorMessage: 'Command execution timed out',
      attemptsMade: attempts,
      completedAt: DateTime.now(),
    );
  }
}

class QueuedCommand {
  final String id;
  final String routerIp;
  final String command;
  final CommandPriority priority;
  final String? groupId;
  final DateTime queuedAt;
  DateTime? executedAt;
  DateTime? completedAt;
  CommandStatus status;
  String? response;
  String? errorMessage;
  int attemptsMade = 0;

  QueuedCommand({
    required this.id,
    required this.routerIp,
    required this.command,
    required this.priority,
    this.groupId,
    required this.queuedAt,
    this.status = CommandStatus.queued,
  });

  QueuedCommand copyWith({
    CommandStatus? status,
    DateTime? executedAt,
    DateTime? completedAt,
    String? response,
    String? errorMessage,
    int? attemptsMade,
  }) {
    return QueuedCommand(
      id: id,
      routerIp: routerIp,
      command: command,
      priority: priority,
      groupId: groupId,
      queuedAt: queuedAt,
    )
      ..status = status ?? this.status
      ..executedAt = executedAt ?? this.executedAt
      ..completedAt = completedAt ?? this.completedAt
      ..response = response ?? this.response
      ..errorMessage = errorMessage ?? this.errorMessage
      ..attemptsMade = attemptsMade ?? this.attemptsMade;
  }

  int compareTo(QueuedCommand other) {
    final priorityComparison = other.priority.index.compareTo(priority.index);
    if (priorityComparison != 0) {
      return priorityComparison;
    }

    return queuedAt.compareTo(other.queuedAt);
  }

  @override
  String toString() {
    return 'QueuedCommand{'
        'id: $id, '
        'routerIp: $routerIp, '
        'command: $command, '
        'priority: $priority, '
        'groupId: $groupId, '
        'queuedAt: $queuedAt, '
        'executedAt: $executedAt, '
        'completedAt: $completedAt, '
        'status: $status, '
        'response: ${response != null ? '${response!.length} chars' : null}, '
        'errorMessage: $errorMessage, '
        'attemptsMade: $attemptsMade'
        '}';
  }
}
