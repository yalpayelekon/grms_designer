import 'dart:async';

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

      unawaited(_executeCommand(cmd).then((_) {
        _executing.remove(cmd.id);
      }));

      await Future.delayed(const Duration(milliseconds: 10));
    }

    while (_executing.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _executeCommand(QueuedCommand command) async {
    command.status = CommandStatus.executing;
    command.executedAt = DateTime.now();
    _statusController.add(command);

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      command.attemptsMade++;

      if (attempt > 0) {
        await Future.delayed(Duration(milliseconds: 200 * (1 << attempt)));
      }

      try {
        final completer = Completer<String>();
        final sub = connection.messageStream.listen((msg) {
          if (!completer.isCompleted) completer.complete(msg);
        });

        final sent = await connection.sendFireAndForget(command.command);
        if (!sent) {
          await sub.cancel();
          continue;
        }

        final response = await completer.future.timeout(commandTimeout);
        await sub.cancel();

        command.status = CommandStatus.completed;
        command.response = response;
        command.completedAt = DateTime.now();
        _statusController.add(command);
        return;
      } catch (e) {
        if (attempt == maxRetries) {
          command.status = CommandStatus.failed;
          command.errorMessage = e.toString();
          command.completedAt = DateTime.now();
          _statusController.add(command);
        }
      }
    }
  }
}
