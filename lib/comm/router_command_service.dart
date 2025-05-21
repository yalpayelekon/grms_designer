import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/project_settings.dart';
import '../utils/logger.dart';
import 'models/command_models.dart';
import 'models/connection_config.dart';
import 'router_connection.dart';
import 'router_connection_manager.dart';

class RouterCommandService {
  final RouterConnectionManager _connectionManager;
  final ConnectionConfig _config;
  final List<QueuedCommand> _commandHistory = [];
  final _commandStatusController = StreamController<QueuedCommand>.broadcast();
  final Map<String, List<QueuedCommand>> _commandQueues = {};
  final Map<String, bool> _executingQueues = {};

  RouterCommandService(this._connectionManager, this._config);

  Stream<QueuedCommand> get commandStatusStream =>
      _commandStatusController.stream;
  List<QueuedCommand> get commandHistory => List.unmodifiable(_commandHistory);

  int get _maxConcurrentCommandsPerRouter => _config.maxConcurrentCommands;
  int get _maxHistorySize => _config.historySize;

  Future<bool> ensureConnection(String routerIp) async {
    try {
      await _connectionManager.getConnection(routerIp);
      return true;
    } catch (e) {
      logError('Error ensuring connection to $routerIp: $e');
      return false;
    }
  }

  bool isRouterConnected(String routerIp) {
    return _connectionManager.hasConnection(routerIp);
  }

  Future<CommandResult> sendCommand(
    String routerIp,
    String command, {
    Duration? timeout,
    int? maxRetries,
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

    queuedCommand.status = CommandStatus.executing;
    queuedCommand.executedAt = DateTime.now();
    _updateCommandStatus(queuedCommand);

    RouterConnection? connection;
    try {
      connection = await _connectionManager.getConnection(routerIp);
    } catch (e) {
      return _handleConnectionError(queuedCommand, e);
    }

    final localMaxRetries = maxRetries ?? _config.maxRetries;
    final localTimeout = timeout ?? _config.commandTimeout;

    return _executeWithRetries(
        connection, queuedCommand, localTimeout, localMaxRetries);
  }

  Future<CommandResult> _executeWithRetries(RouterConnection connection,
      QueuedCommand command, Duration timeout, int maxRetries) async {
    String? lastError;

    for (int attempt = 0; attempt < maxRetries + 1; attempt++) {
      command.attemptsMade++;

      if (attempt > 0) {
        final delay = Duration(milliseconds: 200 * (1 << attempt));
        await Future.delayed(delay);
      }

      try {
        final completer = Completer<String>();

        final subscription = connection.messageStream.listen((message) {
          if (!completer.isCompleted) {
            completer.complete(message);
          }
        });

        final sent = await connection.sendFireAndForget(command.command);
        if (!sent) {
          lastError = 'Failed to send command';
          await subscription.cancel();
          continue;
        }

        String? response;
        try {
          response = await completer.future.timeout(timeout);
        } on TimeoutException {
          lastError = 'Command timed out';
          await subscription.cancel();
          continue;
        } finally {
          await subscription.cancel();
        }

        command.status = CommandStatus.completed;
        command.completedAt = DateTime.now();
        command.response = response;
        _updateCommandStatus(command);
        _addToHistory(command);

        return CommandResult.success(response, command.attemptsMade);
      } catch (e) {
        lastError = e.toString();

        if (attempt == maxRetries) {
          command.status = CommandStatus.failed;
          command.completedAt = DateTime.now();
          command.errorMessage = lastError;
          _updateCommandStatus(command);
          _addToHistory(command);

          return CommandResult.failure(lastError, command.attemptsMade);
        }
      }
    }

    return CommandResult.failure(
      lastError ?? 'Unknown error',
      command.attemptsMade,
    );
  }

  CommandResult _handleConnectionError(QueuedCommand command, dynamic error) {
    command.status = CommandStatus.failed;
    command.completedAt = DateTime.now();
    command.errorMessage = 'Connection error: ${error.toString()}';
    _updateCommandStatus(command);
    _addToHistory(command);

    return CommandResult.failure(
      'Failed to establish connection: ${error.toString()}',
      command.attemptsMade,
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
    logInfo('Command status updated: ${command.toString()}');
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
    logError('Unhandled async error: $error', tag: "RouterCommandService");
  });
}
