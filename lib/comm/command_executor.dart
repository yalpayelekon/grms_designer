import 'dart:async';
import '../comm/models/command_models.dart';
import '../comm/router_connection.dart';

class CommandExecutor {
  static Future<CommandResult> executeWithRetries({
    required RouterConnection connection,
    required QueuedCommand command,
    required Duration timeout,
    required int maxRetries,
    required void Function(QueuedCommand updated) onStatusUpdate,
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      command.attemptsMade++;

      if (attempt > 0) {
        await Future.delayed(Duration(milliseconds: 200 * (1 << attempt)));
      }

      try {
        final completer = Completer<String>();

        final sub = connection.messageStream.listen((msg) {
          if (!completer.isCompleted) {
            completer.complete(msg);
          }
        });

        final sent = await connection.sendFireAndForget(command.command);
        if (!sent) {
          await sub.cancel();
          continue;
        }

        final response = await completer.future.timeout(timeout);
        await sub.cancel();

        command.status = CommandStatus.completed;
        command.response = response;
        command.completedAt = DateTime.now();
        onStatusUpdate(command);

        return CommandResult.success(response, command.attemptsMade);
      } catch (e) {
        if (attempt == maxRetries) {
          command.status = CommandStatus.failed;
          command.errorMessage = e.toString();
          command.completedAt = DateTime.now();
          onStatusUpdate(command);
          return CommandResult.failure(e.toString(), command.attemptsMade);
        }
      }
    }

    return CommandResult.failure("Unknown error", command.attemptsMade);
  }
}
