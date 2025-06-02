import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/utils/core/date_utils.dart';
import '../providers/router_connection_provider.dart';
import '../comm/models/command_models.dart';

class CommandMonitor extends ConsumerWidget {
  const CommandMonitor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commandHistory = ref.watch(commandHistoryProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Command History',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Clear History',
                  onPressed: () {
                    ref.read(routerCommandServiceProvider).clearHistory();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (commandHistory.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No commands executed yet'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: commandHistory.length,
                  itemBuilder: (context, index) {
                    final command = commandHistory[index];
                    return _buildCommandItem(context, command);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandItem(BuildContext context, QueuedCommand command) {
    IconData icon;
    Color color;

    switch (command.status) {
      case CommandStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case CommandStatus.executing:
        icon = Icons.pending;
        color = Colors.blue;
        break;
      case CommandStatus.queued:
        icon = Icons.hourglass_empty;
        color = Colors.orange;
        break;
      case CommandStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
      case CommandStatus.timedOut:
        icon = Icons.timer_off;
        color = Colors.red;
        break;
      case CommandStatus.cancelled:
        icon = Icons.cancel;
        color = Colors.grey;
        break;
    }

    return ExpansionTile(
      leading: Icon(icon, color: color),
      title: Text(
        command.command.length > 30
            ? '${command.command.substring(0, 30)}...'
            : command.command,
      ),
      subtitle: Text(
        '${command.routerIp} - ${formatDateTime(command.queuedAt)}',
      ),
      trailing: command.attemptsMade > 1
          ? Chip(label: Text('${command.attemptsMade} attempts'))
          : null,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Full Command: ${command.command}'),
              const SizedBox(height: 8),
              Text('Status: ${command.status.toString().split('.').last}'),
              const SizedBox(height: 8),
              Text('Priority: ${command.priority.toString().split('.').last}'),
              const SizedBox(height: 8),
              if (command.groupId != null) Text('Group ID: ${command.groupId}'),
              if (command.groupId != null) const SizedBox(height: 8),
              Text('Queued At: ${formatDateTime(command.queuedAt)}'),
              if (command.executedAt != null) ...[
                const SizedBox(height: 8),
                Text('Executed At: ${formatDateTime(command.executedAt!)}'),
              ],
              if (command.completedAt != null) ...[
                const SizedBox(height: 8),
                Text('Completed At: ${formatDateTime(command.completedAt!)}'),
              ],
              if (command.response != null) ...[
                const SizedBox(height: 8),
                Text('Response: ${command.response}'),
              ],
              if (command.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Error: ${command.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
