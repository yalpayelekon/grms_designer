import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/router_connection_provider.dart';
import '../comm/models/router_connection_status.dart';

class RouterConnectionMonitor extends ConsumerWidget {
  const RouterConnectionMonitor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionStatuses = ref.watch(routerConnectionStatusesProvider);
    final connectionStats = ref.watch(connectionStatsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Router Connections',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),

            // Connection stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(context, 'Total', connectionStats['total'] ?? 0),
                _buildStatCard(context, 'Connected',
                    connectionStats['connected'] ?? 0, Colors.green),
                _buildStatCard(context, 'Reconnecting',
                    connectionStats['reconnecting'] ?? 0, Colors.orange),
                _buildStatCard(context, 'Failed',
                    connectionStats['failed'] ?? 0, Colors.red),
              ],
            ),

            const SizedBox(height: 16),

            // Connection list
            if (connectionStatuses.isEmpty)
              const Center(
                child: Text('No active router connections'),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: connectionStatuses.length,
                  itemBuilder: (context, index) {
                    final status = connectionStatuses[index];
                    return _buildConnectionStatusItem(context, status);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, int value,
      [Color? color]) {
    return Card(
      color: color?.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatusItem(
      BuildContext context, RouterConnectionStatus status) {
    IconData icon;
    Color color;

    switch (status.state) {
      case RouterConnectionState.connected:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case RouterConnectionState.connecting:
        icon = Icons.pending;
        color = Colors.blue;
        break;
      case RouterConnectionState.reconnecting:
        icon = Icons.sync;
        color = Colors.orange;
        break;
      case RouterConnectionState.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
      case RouterConnectionState.disconnected:
        icon = Icons.cancel;
        color = Colors.grey;
        break;
    }

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text('${status.routerId} (${status.routerIp})'),
      subtitle: Text(
        status.errorMessage != null
            ? 'Error: ${status.errorMessage}'
            : 'Last change: ${_formatDateTime(status.lastStateChange)}',
      ),
      trailing: status.reconnectAttempts > 0
          ? Chip(label: Text('Retry: ${status.reconnectAttempts}'))
          : null,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
