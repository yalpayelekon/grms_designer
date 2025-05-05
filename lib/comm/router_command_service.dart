import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'models/command_models.dart';
import 'router_connection.dart';
import 'router_connection_manager.dart';

class RouterCommandService {
  static final RouterCommandService _instance =
      RouterCommandService._internal();
  factory RouterCommandService() => _instance;

  final RouterConnectionManager _connectionManager = RouterConnectionManager();
  final Map<String, List<QueuedCommand>> _commandQueues = {};
  final Map<String, Completer<CommandResult>> _activeCommands = {};
  final List<QueuedCommand> _commandHistory = [];
  final int _maxHistorySize = 100;
  final _commandStatusController = StreamController<QueuedCommand>.broadcast();
  int _maxConcurrentCommandsPerRouter = 5;
  int _maxRetries = 3;
  Duration _commandTimeout = const Duration(seconds: 10);
  final Map<String, bool> _executingQueues = {};

  RouterCommandService._internal();
  Stream<QueuedCommand> get commandStatusStream =>
      _commandStatusController.stream;
  List<QueuedCommand> get commandHistory => List.unmodifiable(_commandHistory);
  void configure({
    int? maxConcurrentCommandsPerRouter,
    int? maxRetries,
    Duration? commandTimeout,
  }) {
    if (maxConcurrentCommandsPerRouter != null) {
      _maxConcurrentCommandsPerRouter = maxConcurrentCommandsPerRouter;
    }
    if (maxRetries != null) {
      _maxRetries = maxRetries;
    }
    if (commandTimeout != null) {
      _commandTimeout = commandTimeout;
    }
  }

  Future<CommandResult> sendCommand(
    String routerIp,
    String command, {
    String? routerId,
    Duration? timeout,
    int? maxRetries,
    CommandPriority priority = CommandPriority.normal,
  }) async {
    final commandId = const Uuid().v4();
    final queuedCommand = QueuedCommand(
      id: commandId,
      routerIp: routerIp,
      command: command,
      priority: priority,
      queuedAt: DateTime.now(),
    );

    queuedCommand.status = CommandStatus.executing;
    queuedCommand.executedAt = DateTime.now();
    _updateCommandStatus(queuedCommand);

    RouterConnection? connection;
    try {
      if (routerId != null) {
        connection = await _connectionManager.getConnection(routerIp, routerId);
      } else {
        if (_connectionManager.hasConnection(routerIp)) {
          final connectionKey = '$routerIp:50000';
          if (_connectionManager.connections.containsKey(connectionKey)) {
            connection = _connectionManager.connections[connectionKey];
          }
        }
      }
    } catch (e) {
      queuedCommand.status = CommandStatus.failed;
      queuedCommand.completedAt = DateTime.now();
      queuedCommand.errorMessage = 'Connection error: ${e.toString()}';
      _updateCommandStatus(queuedCommand);
      _addToHistory(queuedCommand);

      return CommandResult.failure(
        'Failed to establish connection: ${e.toString()}',
        queuedCommand.attemptsMade,
      );
    }

    if (connection == null) {
      queuedCommand.status = CommandStatus.failed;
      queuedCommand.completedAt = DateTime.now();
      queuedCommand.errorMessage =
          'No connection available and routerId not provided';
      _updateCommandStatus(queuedCommand);
      _addToHistory(queuedCommand);

      return CommandResult.failure(
        'No connection available and routerId not provided',
        queuedCommand.attemptsMade,
      );
    }

    final localMaxRetries = maxRetries ?? _maxRetries;
    final localTimeout = timeout ?? _commandTimeout;
    String? lastError;

    for (int attempt = 0; attempt < localMaxRetries + 1; attempt++) {
      queuedCommand.attemptsMade++;

      if (attempt > 0) {
        final delay = Duration(milliseconds: 200 * (1 << attempt));
        await Future.delayed(delay);
      }

      try {
        final completer = Completer<String?>();
        _activeCommands[commandId] = Completer<CommandResult>();

        final success = await connection.sendCommand(command);
        if (!success) {
          lastError = 'Failed to send command';
          continue;
        }

        String? response;
        try {
          response = await completer.future.timeout(localTimeout);
        } on TimeoutException {
          lastError =
              'Command timed out after ${localTimeout.inSeconds} seconds';

          if (attempt == localMaxRetries) {
            queuedCommand.status = CommandStatus.timedOut;
            queuedCommand.completedAt = DateTime.now();
            queuedCommand.errorMessage = lastError;
            _updateCommandStatus(queuedCommand);
            _addToHistory(queuedCommand);

            return CommandResult.timeout(queuedCommand.attemptsMade);
          }
          continue;
        }

        queuedCommand.status = CommandStatus.completed;
        queuedCommand.completedAt = DateTime.now();
        queuedCommand.response = response;
        _updateCommandStatus(queuedCommand);
        _addToHistory(queuedCommand);

        return CommandResult.success(response, queuedCommand.attemptsMade);
      } catch (e) {
        lastError = e.toString();

        if (attempt == localMaxRetries) {
          queuedCommand.status = CommandStatus.failed;
          queuedCommand.completedAt = DateTime.now();
          queuedCommand.errorMessage = lastError;
          _updateCommandStatus(queuedCommand);
          _addToHistory(queuedCommand);

          return CommandResult.failure(lastError!, queuedCommand.attemptsMade);
        }
      } finally {
        _activeCommands.remove(commandId);
      }
    }

    return CommandResult.failure(
      lastError ?? 'Unknown error',
      queuedCommand.attemptsMade,
    );
  }

  Future<String> queueCommand(
    String routerIp,
    String command, {
    CommandPriority priority = CommandPriority.normal,
    String? groupId,
  }) async {
    final commandId = const Uuid().v4();
    final queuedCommand = QueuedCommand(
      id: commandId,
      routerIp: routerIp,
      command: command,
      priority: priority,
      groupId: groupId,
      queuedAt: DateTime.now(),
    );

    if (!_commandQueues.containsKey(routerIp)) {
      _commandQueues[routerIp] = [];
    }

    _commandQueues[routerIp]!.add(queuedCommand);
    _commandQueues[routerIp]!.sort((a, b) => a.compareTo(b));
    _updateCommandStatus(queuedCommand);
    _startQueueExecution(routerIp);
    return commandId;
  }

  bool cancelCommand(String commandId) {
    for (final routerIp in _commandQueues.keys) {
      final queue = _commandQueues[routerIp]!;
      final index = queue.indexWhere((cmd) => cmd.id == commandId);

      if (index >= 0) {
        final command = queue[index];

        if (command.status == CommandStatus.queued) {
          queue.removeAt(index);

          command.status = CommandStatus.cancelled;
          command.completedAt = DateTime.now();
          _updateCommandStatus(command);
          _addToHistory(command);

          return true;
        }
      }
    }

    return false;
  }

  Future<List<CommandResult>> batchExecute(
    String routerIp,
    List<String> commands, {
    String? routerId,
    CommandPriority priority = CommandPriority.normal,
  }) async {
    final results = <CommandResult>[];

    for (final command in commands) {
      final result = await sendCommand(
        routerIp,
        command,
        routerId: routerId,
        priority: priority,
      );

      results.add(result);

      if (!result.success) {
        break;
      }
    }

    return results;
  }

  void clearHistory() {
    _commandHistory.clear();
  }

  void _updateCommandStatus(QueuedCommand command) {
    print(command.toString());
    _commandStatusController.add(command);
  }

  void _addToHistory(QueuedCommand command) {
    _commandHistory.insert(0, command);

    if (_commandHistory.length > _maxHistorySize) {
      _commandHistory.removeLast();
    }
  }

  void _startQueueExecution(String routerIp) {
    if (_executingQueues[routerIp] == true) {
      return;
    }

    _executingQueues[routerIp] = true;
    _executeQueue(routerIp).then((_) {
      _executingQueues[routerIp] = false;
    });
  }

  Future<void> _executeQueue(String routerIp) async {
    if (!_commandQueues.containsKey(routerIp) ||
        _commandQueues[routerIp]!.isEmpty) {
      return;
    }

    final queue = _commandQueues[routerIp]!;
    final executingCommands = <String>{};

    while (queue.isNotEmpty) {
      if (executingCommands.length >= _maxConcurrentCommandsPerRouter) {
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }

      final command = queue.removeAt(0);
      executingCommands.add(command.id);
      unawaited(_executeQueuedCommand(command).then((_) {
        executingCommands.remove(command.id);
      }));
      await Future.delayed(const Duration(milliseconds: 10));
    }

    while (executingCommands.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<String?> testConnection(String routerIp, String routerId) async {
    try {
      final connection =
          await _connectionManager.getConnection(routerIp, routerId);
      final response = await connection.sendCommandWithResponse('>V:2,C:191#');

      return response;
    } catch (e) {
      debugPrint('Test connection error: $e');
      return 'ERROR: $e';
    }
  }

  Future<void> _executeQueuedCommand(QueuedCommand command) async {
    try {
      command.status = CommandStatus.executing;
      command.executedAt = DateTime.now();
      _updateCommandStatus(command);

      final result = await sendCommand(
        command.routerIp,
        command.command,
        priority: command.priority,
      );

      command.status =
          result.success ? CommandStatus.completed : CommandStatus.failed;
      command.completedAt = DateTime.now();
      command.response = result.response;
      command.errorMessage = result.errorMessage;
      command.attemptsMade = result.attemptsMade;

      _updateCommandStatus(command);
      _addToHistory(command);
    } catch (e) {
      command.status = CommandStatus.failed;
      command.completedAt = DateTime.now();
      command.errorMessage = 'Unexpected error: ${e.toString()}';

      _updateCommandStatus(command);
      _addToHistory(command);
    }
  }
}

void unawaited(Future<void> future) {
  future.catchError((error) {
    debugPrint('Unhandled async error: $error');
  });
}
