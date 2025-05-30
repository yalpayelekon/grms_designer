import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../providers/workgroups_provider.dart';
import '../../providers/group_polling_provider.dart';
import '../lists/groups_list_screen.dart';
import 'router_detail_screen.dart';

class WorkgroupDetailScreen extends ConsumerStatefulWidget {
  final Workgroup workgroup;

  const WorkgroupDetailScreen({super.key, required this.workgroup});

  @override
  WorkgroupDetailScreenState createState() => WorkgroupDetailScreenState();
}

class WorkgroupDetailScreenState extends ConsumerState<WorkgroupDetailScreen> {
  bool _isLoading = false;

  Workgroup get currentWorkgroup {
    final workgroups = ref.watch(workgroupsProvider);
    return workgroups.firstWhere(
      (wg) => wg.id == widget.workgroup.id,
      orElse: () => widget.workgroup,
    );
  }

  @override
  void initState() {
    super.initState();
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    final workgroup = currentWorkgroup;
    final pollingState = ref.watch(pollingStateProvider);
    final isPollingActive = pollingState[workgroup.id] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(workgroup.description),
        centerTitle: true,
        actions: const [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(context),
                  const SizedBox(height: 24),
                  _buildPollingCard(context),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Groups',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.navigate_next),
                        label: const Text('View All Groups'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  GroupsListScreen(workgroup: workgroup),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Routers',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildRoutersList(context),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final workgroup = currentWorkgroup;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.group_work, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Workgroup Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            _buildDetailRow('ID', workgroup.id),
            _buildDetailRow('Description', workgroup.description),
            _buildDetailRow('Network Interface', workgroup.networkInterface),
            _buildDetailRow(
              'Number of Routers',
              workgroup.routers.length.toString(),
            ),
            _buildDetailRow(
              'Number of Groups',
              workgroup.groups.length.toString(),
            ),
            _buildDetailRow(
              'Gateway Router IP',
              workgroup.gatewayRouterIpAddress.isEmpty
                  ? 'Not set'
                  : workgroup.gatewayRouterIpAddress,
            ),
            _buildDetailRow(
              'Refresh Props After Action',
              workgroup.refreshPropsAfterAction.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollingCard(BuildContext context) {
    final workgroup = currentWorkgroup;
    final pollingState = ref.watch(pollingStateProvider);
    final isPollingActive = pollingState[workgroup.id] ?? false;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  workgroup.pollEnabled
                      ? Icons.autorenew
                      : Icons.pause_circle_outline,
                  color: workgroup.pollEnabled ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Power Consumption Polling',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                const SizedBox(
                  width: 140,
                  child: Text(
                    'Polling Enabled:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: DropdownButton<bool>(
                    value: workgroup.pollEnabled,
                    isExpanded: true,
                    onChanged: (bool? newValue) {
                      if (newValue != null) {
                        _togglePolling(newValue);
                      }
                    },
                    items: const [
                      DropdownMenuItem<bool>(
                        value: false,
                        child: Row(
                          children: [
                            Icon(
                              Icons.pause_circle_outline,
                              size: 16,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 8),
                            Text('Disabled'),
                          ],
                        ),
                      ),
                      DropdownMenuItem<bool>(
                        value: true,
                        child: Row(
                          children: [
                            Icon(
                              Icons.autorenew,
                              size: 16,
                              color: Colors.green,
                            ),
                            SizedBox(width: 8),
                            Text('Enabled'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (workgroup.pollEnabled) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isPollingActive ? Icons.check_circle : Icons.pending,
                          size: 16,
                          color: isPollingActive ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isPollingActive
                              ? 'Polling Active'
                              : 'Starting Polling...',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isPollingActive
                                ? Colors.green[700]
                                : Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Groups will be polled automatically based on their individual polling intervals.',
                      style: TextStyle(fontSize: 12, color: Colors.green[600]),
                    ),
                    if (workgroup.groups.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Active Groups: ${workgroup.groups.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: workgroup.groups.map((group) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Group ${group.groupId} (${group.powerPollingMinutes}min)',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Automatic power consumption polling is disabled. Enable to start monitoring group power consumption.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (workgroup.lastPollTime != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                'Last Poll Started',
                _formatDateTime(workgroup.lastPollTime!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  void _togglePolling(bool enabled) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(workgroupsProvider.notifier)
          .toggleWorkgroupPolling(widget.workgroup.id, enabled);

      // Update polling state through the provider
      if (enabled) {
        ref
            .read(pollingStateProvider.notifier)
            .startPolling(widget.workgroup.id);
      } else {
        ref
            .read(pollingStateProvider.notifier)
            .stopPolling(widget.workgroup.id);
      }

      final message = enabled
          ? 'Automatic polling enabled for all groups in this workgroup'
          : 'Automatic polling disabled';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: enabled ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error toggling polling: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildRoutersList(BuildContext context) {
    final workgroup = currentWorkgroup;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: workgroup.routers.length,
      itemBuilder: (context, index) {
        final router = workgroup.routers[index];
        return _buildRouterCard(context, router);
      },
    );
  }

  Widget _buildRouterCard(BuildContext context, HelvarRouter router) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(
              router.description,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('IP Address: ${router.ipAddress}'),
                Text('Address: ${router.address}'),
                Text('Description: ${router.description}'),
                Text('Devices: ${router.devices.length}'),
              ],
            ),
            isThreeLine: true,
            leading: const CircleAvatar(child: Icon(Icons.router)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RouterDetailScreen(
                    workgroup: currentWorkgroup,
                    router: router,
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.devices),
                  label: const Text('Manage Devices'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RouterDetailScreen(
                          workgroup: currentWorkgroup,
                          router: router,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
