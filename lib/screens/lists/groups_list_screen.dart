import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/helvar_models/helvar_group.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../providers/workgroups_provider.dart';
import '../../services/discovery_service.dart';
import '../../utils/general_ui.dart';
import '../details/group_detail_screen.dart';

class GroupsListScreen extends ConsumerStatefulWidget {
  final Workgroup workgroup;

  const GroupsListScreen({
    super.key,
    required this.workgroup,
  });

  @override
  GroupsListScreenState createState() => GroupsListScreenState();
}

class GroupsListScreenState extends ConsumerState<GroupsListScreen> {
  bool _isLoading = false;
  final DiscoveryService _discoveryService = DiscoveryService();
  Map<String, bool> expandedGroups = {};
  bool _showGroups = true;

  @override
  void initState() {
    super.initState();
    _isLoading = false;
    for (var group in widget.workgroup.groups) {
      expandedGroups[group.groupId] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Groups - ${widget.workgroup.description}'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGroupsSection(context),
                ],
              ),
            ),
    );
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
                  icon: Icon(
                      _showGroups ? Icons.visibility : Icons.visibility_off),
                  tooltip: _showGroups ? 'Hide Groups' : 'Show Groups',
                  onPressed: () {
                    setState(() {
                      _showGroups = !_showGroups;
                    });
                  },
                ),
                if (_showGroups) ...[
                  IconButton(
                    icon: const Icon(Icons.unfold_less),
                    tooltip: 'Collapse All',
                    onPressed: () {
                      setState(() {
                        for (var group in widget.workgroup.groups) {
                          expandedGroups[group.groupId] = false;
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
                          expandedGroups[group.groupId] = true;
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
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_showGroups) _buildCollapsibleGroupsList(context),
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
    final isExpanded = expandedGroups[group.groupId] ?? false;

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
                      expandedGroups[group.groupId] = !isExpanded;
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
                expandedGroups[group.groupId] = !isExpanded;
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

  void _editGroup(BuildContext context, HelvarGroup group) {
    showSnackBarMsg(context, 'Edit Group feature coming soon');
  }

  void _showGroupDetails(BuildContext context, HelvarGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailScreen(
          group: group,
          workgroup: widget.workgroup,
        ),
      ),
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
      showSnackBarMsg(context, 'Group deleted');
    }
  }

  Future<void> _discoverGroups(BuildContext context) async {
    if (widget.workgroup.routers.isEmpty) {
      showSnackBarMsg(context, 'No routers available to discover groups');
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
        showSnackBarMsg(context, 'No groups discovered');
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
      showSnackBarMsg(context, 'Added ${newGroups.length} groups');
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      showSnackBarMsg(context, 'Error discovering groups: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
}
