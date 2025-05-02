import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/helvar_group.dart';
import '../models/workgroup.dart';
import '../models/helvar_router.dart';
import '../providers/workgroups_provider.dart';
import '../services/discovery_service.dart';
import 'router_detail_screen.dart';

class WorkgroupDetailScreen extends ConsumerStatefulWidget {
  final Workgroup workgroup;

  const WorkgroupDetailScreen({
    super.key,
    required this.workgroup,
  });

  @override
  WorkgroupDetailScreenState createState() => WorkgroupDetailScreenState();
}

class WorkgroupDetailScreenState extends ConsumerState<WorkgroupDetailScreen> {
  bool _isLoading = false;
  final DiscoveryService _discoveryService = DiscoveryService();
  Map<String, bool> _expandedGroups = {};

  @override
  void initState() {
    super.initState();
    _isLoading = false;
    for (var group in widget.workgroup.groups) {
      _expandedGroups[group.groupId] = false;
    }
  }

  Widget _buildGroupsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.unfold_less),
                  tooltip: 'Collapse All',
                  onPressed: () {
                    setState(() {
                      for (var group in widget.workgroup.groups) {
                        _expandedGroups[group.groupId] = false;
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.unfold_more),
                  tooltip: 'Expand All',
                  onPressed: () {
                    setState(() {
                      for (var group in widget.workgroup.groups) {
                        _expandedGroups[group.groupId] = true;
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Discover Groups',
                  onPressed: () => _discoverGroups(context),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildCollapsibleGroupsList(context),
      ],
    );
  }

  Widget _buildCollapsibleGroupsList(BuildContext context) {
    return widget.workgroup.groups.isEmpty
        ? Card(
            margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.group_work,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No groups found for this workgroup',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text('Discover Groups'),
                    onPressed: () => _discoverGroups(context),
                  ),
                ],
              ),
            ),
          )
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.workgroup.groups.length,
            itemBuilder: (context, index) {
              final group = widget.workgroup.groups[index];
              return _buildCollapsibleGroupItem(context, group);
            },
          );
  }

  Widget _buildCollapsibleGroupItem(BuildContext context, HelvarGroup group) {
    final isExpanded = _expandedGroups[group.groupId] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        children: [
          ListTile(
            title: Text(
              group.description.isEmpty
                  ? "Group ${group.groupId}"
                  : group.description,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Group ID: ${group.groupId}'),
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(
                Icons.layers,
                color: Colors.white,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                  onPressed: () {
                    setState(() {
                      _expandedGroups[group.groupId] = !isExpanded;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editGroup(context, group),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _confirmDeleteGroup(context, group),
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _expandedGroups[group.groupId] = !isExpanded;
              });
            },
          ),
          if (isExpanded)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Type', group.type),
                  if (group.lsig != null)
                    _buildDetailRow('LSIG', group.lsig.toString()),
                  _buildDetailRow(
                      'Power Polling', '${group.powerPollingMinutes} minutes'),
                  if (group.gatewayRouterIpAddress.isNotEmpty)
                    _buildDetailRow(
                        'Gateway Router', group.gatewayRouterIpAddress),
                  _buildDetailRow('Refresh Props After Action',
                      group.refreshPropsAfterAction.toString()),
                  OverflowBar(
                    alignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _showGroupDetails(context, group),
                        child: const Text('View Details'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workgroup.description),
        centerTitle: true,
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
                  _buildGroupsSection(context),
                  const SizedBox(height: 24),
                  const Text(
                    'Routers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRoutersList(context),
                ],
              ),
            ),
    );
  }

  Future<void> _discoverGroups(BuildContext context) async {
    if (widget.workgroup.routers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No routers available to discover groups')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final router = widget.workgroup.routers.first;
      final discoveredGroups =
          await _discoveryService.discoverGroups(router.ipAddress);

      if (discoveredGroups.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No groups discovered')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (!mounted) return;
      final shouldAdd = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Groups Discovered'),
              content: Text(
                  'Found ${discoveredGroups.length} groups. Do you want to add them?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Add Groups'),
                ),
              ],
            ),
          ) ??
          false;

      if (!shouldAdd || !mounted) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final existingGroupIds =
          widget.workgroup.groups.map((g) => g.groupId).toSet();
      final newGroups = discoveredGroups
          .where((g) => !existingGroupIds.contains(g.groupId))
          .toList();

      for (final group in newGroups) {
        await ref.read(workgroupsProvider.notifier).addGroupToWorkgroup(
              widget.workgroup.id,
              group,
            );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${newGroups.length} groups')),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error discovering groups: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildGroupCard(BuildContext context, HelvarGroup group) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: ListTile(
        title: Text(
          group.description.isEmpty
              ? "Group ${group.groupId}"
              : group.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Group ID: ${group.groupId}'),
            Text('Type: ${group.type}'),
          ],
        ),
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.layers, color: Colors.white),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editGroup(context, group),
              tooltip: 'Edit group',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDeleteGroup(context, group),
              tooltip: 'Remove group',
            ),
          ],
        ),
        onTap: () => _showGroupDetails(context, group),
      ),
    );
  }

  void _showGroupDetails(BuildContext context, HelvarGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          group.description.isEmpty
              ? 'Group ${group.groupId}'
              : group.description,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Group ID', group.groupId),
              _buildDetailRow('Type', group.type),
              if (group.lsig != null)
                _buildDetailRow('LSIG', group.lsig.toString()),
              _buildDetailRow(
                  'Power Polling', '${group.powerPollingMinutes} minutes'),
              _buildDetailRow('Gateway Router', group.gatewayRouterIpAddress),
              _buildDetailRow('Refresh Props After Action',
                  group.refreshPropsAfterAction.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => _editGroup(context, group),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _editGroup(BuildContext context, HelvarGroup group) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit Group feature coming soon')),
    );
  }

  Future<void> _confirmDeleteGroup(
      BuildContext context, HelvarGroup group) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          'Are you sure you want to delete the group "${group.description.isEmpty ? 'Group ${group.groupId}' : group.description}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref.read(workgroupsProvider.notifier).removeGroupFromWorkgroup(
            widget.workgroup.id,
            group,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group deleted'),
        ),
      );
    }
  }

  Widget _buildInfoCard(BuildContext context) {
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
            _buildDetailRow('ID', widget.workgroup.id),
            _buildDetailRow('Description', widget.workgroup.description),
            _buildDetailRow(
                'Network Interface', widget.workgroup.networkInterface),
            _buildDetailRow('Number of Routers',
                widget.workgroup.routers.length.toString()),
          ],
        ),
      ),
    );
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
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutersList(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.workgroup.routers.length,
      itemBuilder: (context, index) {
        final router = widget.workgroup.routers[index];
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
            leading: const CircleAvatar(
              child: Icon(Icons.router),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RouterDetailScreen(
                    workgroup: widget.workgroup,
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
                          workgroup: widget.workgroup,
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
