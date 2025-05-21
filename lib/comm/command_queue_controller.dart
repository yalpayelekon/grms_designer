import 'dart:async';

import 'command_executor.dart';
import 'models/command_models.dart';
import 'router_connection.dart';

class CommandQueueController {
  final RouterConnection connection;
  final Duration commandTimeout;
  final int maxRetries;

  final List<QueuedCommand> _queue = [];
  final _executing = <String>{};
  final StreamController<QueuedCommand> _statusController;

  CommandQueueController({
    required this.connection,
    required this.commandTimeout,
    required this.maxRetries,
    required StreamController<QueuedCommand> statusController,
  }) : _statusController = statusController;

  void enqueue(QueuedCommand command) {
    _queue.add(command);
    _queue.sort((a, b) => a.compareTo(b));
    _statusController.add(command);
    _startQueueExecution();
  }

  bool cancel(String commandId) {
    final index = _queue.indexWhere((c) => c.id == commandId);
    if (index != -1) {
      final command = _queue.removeAt(index);
      command.status = CommandStatus.cancelled;
      command.completedAt = DateTime.now();
      _statusController.add(command);
      return true;
    }
    return false;
  }

  Future<void> _startQueueExecution() async {
    while (_queue.isNotEmpty) {
      if (_executing.length >= 3) {
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }

      final cmd = _queue.removeAt(0);
      _executing.add(cmd.id);

      CommandExecutor.executeWithRetries(
        connection: connection,
        command: cmd,
        timeout: commandTimeout,
        maxRetries: maxRetries,
        onStatusUpdate: (updatedCmd) => _statusController.add(updatedCmd),
      );

      await Future.delayed(const Duration(milliseconds: 10));
    }

    while (_executing.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}
