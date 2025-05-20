import 'dart:async';
import 'package:grms_designer/protocol/protocol_constants.dart';
import 'package:uuid/uuid.dart';
import '../models/project_settings.dart';
import '../utils/logger.dart';
import 'models/command_models.dart';
import 'router_connection.dart';
import 'router_connection_manager.dart';

class RouterCommandService {
  static final RouterCommandService _instance =
      RouterCommandService._internal();
  factory RouterCommandService() => _instance;

  final RouterConnectionManager _connectionManager = RouterConnectionManager();
  final Map<String, List<QueuedCommand>> _commandQueues = {};
  final List<QueuedCommand> _commandHistory = [];
  int _maxHistorySize = 100;
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

  Future<bool> ensureConnection(String routerIp) async {
    try {
      final connectionManager = RouterConnectionManager();
      await connectionManager.getConnection(routerIp);
      return true;
    } catch (e) {
      logError('Error ensuring connection to $routerIp: $e');
      return false;
    }
  }

  Future<String?> executeCommand(String routerIp, String command) async {
    try {
      final result = await sendCommand(
        routerIp,
        command,
        priority: CommandPriority.high,
      );

      if (result.success) {
        return result.response;
      } else {
        logError('Command execution failed: ${result.errorMessage}');
        return null;
      }
    } catch (e) {
      logError('Error executing command: $e');
      return null;
    }
  }

  bool isRouterConnected(String routerIp) {
    final connectionManager = RouterConnectionManager();
    return connectionManager.hasConnection(routerIp);
  }

  void configureFromSettings(ProjectSettings settings) {
    _maxConcurrentCommandsPerRouter = settings.maxConcurrentCommandsPerRouter;
    _maxRetries = settings.maxCommandRetries;
    _commandTimeout = Duration(milliseconds: settings.commandTimeoutMs);
    _maxHistorySize = settings.commandHistorySize;
  }

  Future<CommandResult> sendCommand(
    String routerIp,
    String command, {
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
      connection = await _connectionManager.getConnection(routerIp);
      if (_connectionManager.hasConnection(routerIp)) {
        final connectionKey = '$routerIp:$defaultTcpPort';
        if (_connectionManager.connections.containsKey(connectionKey)) {
          connection = _connectionManager.connections[connectionKey];
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
        final response = await connection.sendCommandWithResponse(
          command,
          localTimeout,
        );

        if (response == null) {
          lastError = 'Command timed out or failed to get response';

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

          return CommandResult.failure(lastError, queuedCommand.attemptsMade);
        }
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
