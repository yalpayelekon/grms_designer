import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../providers/router_connection_provider.dart';
import '../utils/logger.dart';
import 'command_executor.dart';
import 'command_queue_controller.dart';
import 'models/command_models.dart';
import 'models/connection_config.dart';
import 'router_connection.dart';
import 'router_connection_manager.dart';

class RouterCommandService {
  final RouterConnectionManager _connectionManager;
  final ConnectionConfig _config;
  final List<QueuedCommand> _commandHistory = [];
  final _commandStatusController = StreamController<QueuedCommand>.broadcast();
  final Map<String, CommandQueueController> _queueControllers = {};

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

  CommandQueueController _getQueueController(RouterConnection connection) {
    return _queueControllers.putIfAbsent(connection.ipAddress, () {
      return CommandQueueController(
        connection: connection,
        commandTimeout: _config.commandTimeout,
        maxRetries: _config.maxRetries,
        statusController: _commandStatusController,
      );
    });
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

    return CommandExecutor.executeWithRetries(
      connection: connection,
      command: queuedCommand,
      timeout: localTimeout,
      maxRetries: localMaxRetries,
      onStatusUpdate: _updateCommandStatus,
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

    final conn = await _connectionManager.getConnection(routerIp);

    final controller = _getQueueController(conn);
    controller.enqueue(queuedCommand);

    return commandId;
  }

  bool cancelCommand(String commandId) {
    for (final controller in _queueControllers.values) {
      final result = controller.cancel(commandId);
      if (result) return true;
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
}

void unawaited(Future<void> future) {
  future.catchError((error) {
    logError('Unhandled async error: $error', tag: "RouterCommandService");
  });
}

final commandStatusStreamProvider = StreamProvider<QueuedCommand>((ref) {
  final service = ref.watch(routerCommandServiceProvider);
  return service.commandStatusStream;
});
