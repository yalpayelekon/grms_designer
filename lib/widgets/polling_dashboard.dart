import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/utils/ui/ui_helpers.dart';
import '../providers/centralized_polling_provider.dart';
import '../services/polling/polling_task.dart';

class PollingDashboard extends ConsumerWidget {
  const PollingDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statistics = ref.watch(pollingStatisticsProvider);
    final tasks = ref.watch(pollingTasksProvider);
    final pollingManager = ref.read(pollingManagerProvider.notifier);

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
                  'Polling Dashboard',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.pause),
                      tooltip: 'Pause All Polling',
                      onPressed: () {
                        pollingManager.pauseAllPolling();
                        showSnackBarMsg(context, 'All polling paused');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_arrow),
                      tooltip: 'Resume All Polling',
                      onPressed: () async {
                        await pollingManager.resumeAllPolling();
                        if (context.mounted) {
                          showSnackBarMsg(context, 'All polling resumed');
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            _buildStatisticsSection(context, statistics),
            const SizedBox(height: 16),
            _buildActiveTasksSection(context, tasks, pollingManager),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(
    BuildContext context,
    Map<String, dynamic> statistics,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Statistics', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildStatCard(
              'Total Tasks',
              statistics['totalTasks']?.toString() ?? '0',
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              'Running',
              statistics['runningTasks']?.toString() ?? '0',
              Colors.green,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              'Paused',
              statistics['pausedTasks']?.toString() ?? '0',
              Colors.orange,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              'Errors',
              statistics['errorTasks']?.toString() ?? '0',
              Colors.red,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Total Executions: ${statistics['totalExecutions'] ?? 0}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, [Color? color]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color ?? Colors.grey),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActiveTasksSection(
    BuildContext context,
    Map<String, PollingTaskInfo> tasks,
    PollingManager pollingManager,
  ) {
    final activeTasks = tasks.values
        .where((taskInfo) => taskInfo.state == PollingTaskState.running)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Tasks (${activeTasks.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (activeTasks.isEmpty)
          const Text('No active polling tasks')
        else
          ...activeTasks.map(
            (taskInfo) => _buildTaskCard(context, taskInfo, pollingManager),
          ),
      ],
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    PollingTaskInfo taskInfo,
    PollingManager pollingManager,
  ) {
    final task = taskInfo.task;
    final lastExecution = taskInfo.lastExecution;
    final executionCount = taskInfo.executionCount;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              _getTaskIcon(taskInfo.state),
              color: _getTaskColor(taskInfo.state),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Interval: ${task.interval.inMinutes}min | Executions: $executionCount',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (lastExecution != null)
                    Text(
                      'Last run: ${_formatLastExecution(lastExecution)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow, size: 16),
              tooltip: 'Execute Now',
              onPressed: () async {
                await pollingManager.executeTaskNow(task.id);
                if (context.mounted) {
                  showSnackBarMsg(context, 'Task ${task.name} executed');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTaskIcon(PollingTaskState state) {
    switch (state) {
      case PollingTaskState.running:
        return Icons.play_circle_filled;
      case PollingTaskState.paused:
        return Icons.pause_circle_filled;
      case PollingTaskState.error:
        return Icons.error;
      case PollingTaskState.stopped:
        return Icons.stop_circle;
      case PollingTaskState.idle:
        return Icons.radio_button_unchecked;
    }
  }

  Color _getTaskColor(PollingTaskState state) {
    switch (state) {
      case PollingTaskState.running:
        return Colors.green;
      case PollingTaskState.paused:
        return Colors.orange;
      case PollingTaskState.error:
        return Colors.red;
      case PollingTaskState.stopped:
        return Colors.grey;
      case PollingTaskState.idle:
        return Colors.blue;
    }
  }

  String _formatLastExecution(DateTime lastExecution) {
    final now = DateTime.now();
    final difference = now.difference(lastExecution);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}
