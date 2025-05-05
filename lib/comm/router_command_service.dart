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

  // Dependencies
  final RouterConnectionManager _connectionManager = RouterConnectionManager();

  // Command queues per router
  final Map<String, List<QueuedCommand>> _commandQueues = {};

  // Active command executions
  final Map<String, Completer<CommandResult>> _activeCommands = {};

  // Command history
  final List<QueuedCommand> _commandHistory = [];
  final int _maxHistorySize = 100;

  // Status streams
  final _commandStatusController = StreamController<QueuedCommand>.broadcast();

  // Configuration
  int _maxConcurrentCommandsPerRouter = 5;
  int _maxRetries = 3;
  Duration _commandTimeout = const Duration(seconds: 10);

  // Execute flags
  final Map<String, bool> _executingQueues = {};

  RouterCommandService._internal();

  // Public getters
  Stream<QueuedCommand> get commandStatusStream =>
      _commandStatusController.stream;
  List<QueuedCommand> get commandHistory => List.unmodifiable(_commandHistory);

  // Configure the service
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

  // Send a command to a router with immediate execution
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

    // Update command status
    queuedCommand.status = CommandStatus.executing;
    queuedCommand.executedAt = DateTime.now();
    _updateCommandStatus(queuedCommand);

    // Try to get an existing connection or create a new one
    RouterConnection? connection;
    try {
      if (routerId != null) {
        connection = await _connectionManager.getConnection(routerIp, routerId);
      } else {
        // Check if we already have a connection to this router
        if (_connectionManager.hasConnection(routerIp)) {
          // Use existing connection
          final connectionKey = '$routerIp:50000';
          if (_connectionManager.connections.containsKey(connectionKey)) {
            connection = _connectionManager.connections[connectionKey];
          }
        }
      }
    } catch (e) {
      // Connection error
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
      // No connection and couldn't create one
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

    // Execute the command with retries
    final localMaxRetries = maxRetries ?? _maxRetries;
    final localTimeout = timeout ?? _commandTimeout;
    String? lastError;

    for (int attempt = 0; attempt < localMaxRetries + 1; attempt++) {
      queuedCommand.attemptsMade++;

      if (attempt > 0) {
        // Delay before retry, increasing with each attempt
        final delay = Duration(milliseconds: 200 * (1 << attempt));
        await Future.delayed(delay);
      }

      try {
        // Create a completer for this command execution
        final completer = Completer<String?>();
        _activeCommands[commandId] = Completer<CommandResult>();

        // Send the command
        final success = await connection.sendCommand(command);
        if (!success) {
          lastError = 'Failed to send command';
          continue;
        }

        // Wait for response or timeout
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

        // Command succeeded
        queuedCommand.status = CommandStatus.completed;
        queuedCommand.completedAt = DateTime.now();
        queuedCommand.response = response;
        _updateCommandStatus(queuedCommand);
        _addToHistory(queuedCommand);

        return CommandResult.success(response, queuedCommand.attemptsMade);
      } catch (e) {
        lastError = e.toString();

        // Last attempt failed
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

    // This should never happen, but just in case
    return CommandResult.failure(
      lastError ?? 'Unknown error',
      queuedCommand.attemptsMade,
    );
  }

  // Queue a command for execution
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

    // Initialize queue for this router if it doesn't exist
    if (!_commandQueues.containsKey(routerIp)) {
      _commandQueues[routerIp] = [];
    }

    // Add command to queue
    _commandQueues[routerIp]!.add(queuedCommand);

    // Sort queue by priority and time
    _commandQueues[routerIp]!.sort((a, b) => a.compareTo(b));

    // Update command status
    _updateCommandStatus(queuedCommand);

    // Start queue execution if not already running
    _startQueueExecution(routerIp);

    return commandId;
  }

  // Cancel a queued command
  bool cancelCommand(String commandId) {
    // Check all router queues
    for (final routerIp in _commandQueues.keys) {
      final queue = _commandQueues[routerIp]!;
      final index = queue.indexWhere((cmd) => cmd.id == commandId);

      if (index >= 0) {
        final command = queue[index];

        // Only cancel if not already executing
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

  // Batch execute multiple commands
  Future<List<CommandResult>> batchExecute(
    String routerIp,
    List<String> commands, {
    String? routerId,
    CommandPriority priority = CommandPriority.normal,
  }) async {
    final results = <CommandResult>[];

    // Execute each command in sequence
    for (final command in commands) {
      final result = await sendCommand(
        routerIp,
        command,
        routerId: routerId,
        priority: priority,
      );

      results.add(result);

      // If a command fails, stop execution
      if (!result.success) {
        break;
      }
    }

    return results;
  }

  // Clear command history
  void clearHistory() {
    _commandHistory.clear();
  }

  // Private methods
  void _updateCommandStatus(QueuedCommand command) {
    _commandStatusController.add(command);
  }

  void _addToHistory(QueuedCommand command) {
    _commandHistory.insert(0, command);

    // Trim history if it gets too large
    if (_commandHistory.length > _maxHistorySize) {
      _commandHistory.removeLast();
    }
  }

  void _startQueueExecution(String routerIp) {
    // Avoid multiple simultaneous executions for the same router
    if (_executingQueues[routerIp] == true) {
      return;
    }

    _executingQueues[routerIp] = true;

    // Execute queue in the background
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

    // Continue processing until queue is empty
    while (queue.isNotEmpty) {
      // Check if we've reached the maximum concurrent commands
      if (executingCommands.length >= _maxConcurrentCommandsPerRouter) {
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }

      // Get the next command from the queue
      final command = queue.removeAt(0);

      // Mark as executing
      executingCommands.add(command.id);

      // Execute the command in the background
      unawaited(_executeQueuedCommand(command).then((_) {
        executingCommands.remove(command.id);
      }));

      // Small delay to avoid flooding the router
      await Future.delayed(const Duration(milliseconds: 10));
    }

    // Wait for all commands to complete
    while (executingCommands.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _executeQueuedCommand(QueuedCommand command) async {
    try {
      // Update status
      command.status = CommandStatus.executing;
      command.executedAt = DateTime.now();
      _updateCommandStatus(command);

      // Execute command
      final result = await sendCommand(
        command.routerIp,
        command.command,
        priority: command.priority,
      );

      // Update command with result
      command.status =
          result.success ? CommandStatus.completed : CommandStatus.failed;
      command.completedAt = DateTime.now();
      command.response = result.response;
      command.errorMessage = result.errorMessage;
      command.attemptsMade = result.attemptsMade;

      _updateCommandStatus(command);
      _addToHistory(command);
    } catch (e) {
      // Handle unexpected errors
      command.status = CommandStatus.failed;
      command.completedAt = DateTime.now();
      command.errorMessage = 'Unexpected error: ${e.toString()}';

      _updateCommandStatus(command);
      _addToHistory(command);
    }
  }
}

// Helper to avoid "The argument type 'Future<void>' can't be assigned to the parameter type 'FutureOr<void>'"
void unawaited(Future<void> future) {
  // Avoid issues with unhandled async exceptions
  future.catchError((error) {
    debugPrint('Unhandled async error: $error');
  });
}
