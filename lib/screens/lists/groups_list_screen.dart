import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/widgets/common/detail_card.dart';
import 'package:intl/intl.dart';
import '../../models/helvar_models/helvar_group.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../providers/workgroups_provider.dart';
import '../../widgets/common/expandable_list_item.dart';
import '../../utils/ui/ui_helpers.dart';
import '../../utils/device/scene_utils.dart';

class GroupsListScreen extends ConsumerStatefulWidget {
  final Workgroup workgroup;

  const GroupsListScreen({super.key, required this.workgroup});

  @override
  GroupsListScreenState createState() => GroupsListScreenState();
}

class GroupsListScreenState extends ConsumerState<GroupsListScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final workgroups = ref.watch(workgroupsProvider);
    final currentWorkgroup = workgroups.firstWhere(
      (wg) => wg.id == widget.workgroup.id,
      orElse: () => widget.workgroup,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Groups - ${currentWorkgroup.description}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Discover Groups',
            onPressed: () => _discoverGroups(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : currentWorkgroup.groups.isEmpty
          ? _buildEmptyState()
          : ExpandableListView(
              padding: const EdgeInsets.all(8.0),
              children: currentWorkgroup.groups
                  .map((group) => _buildGroupItem(group, currentWorkgroup))
                  .toList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_work, size: 48, color: Colors.grey),
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
    );
  }

  Widget _buildGroupItem(HelvarGroup group, Workgroup workgroup) {
    return ExpandableListItem(
      title: group.description.isEmpty
          ? "Group ${group.groupId}"
          : group.description,
      subtitle: 'Group ID: ${group.groupId}',
      leadingIcon: Icons.layers,
      leadingIconColor: Colors.green,
      showDelete: true,
      onDelete: () => _confirmDeleteGroup(context, group),
      detailRows: [
        DetailRow(label: 'Group ID', value: group.groupId, showDivider: true),

        DetailRow(
          label: 'Description',
          value: group.description.isEmpty
              ? 'No description'
              : group.description,
          showDivider: true,
        ),

        DetailRow(label: 'Type', value: group.type, showDivider: true),

        if (group.lsig != null)
          DetailRow(
            label: 'LSIG',
            value: group.lsig.toString(),
            showDivider: true,
          ),

        if (group.lsib1 != null)
          DetailRow(
            label: 'LSIB1',
            value: group.lsib1.toString(),
            showDivider: true,
          ),

        if (group.lsib2 != null)
          DetailRow(
            label: 'LSIB2',
            value: group.lsib2.toString(),
            showDivider: true,
          ),

        // Block values
        ...group.blockValues.asMap().entries.map(
          (entry) => DetailRow(
            label: 'Block ${entry.key + 1}',
            value: entry.value.toString(),
            showDivider: true,
          ),
        ),

        // Power Consumption
        DetailRow(
          label: 'Current Power',
          value: '${group.powerConsumption.toStringAsFixed(2)} W',
          showDivider: true,
        ),

        DetailRow(
          label: 'Polling Minutes',
          value: '${group.powerPollingMinutes} minutes',
          showDivider: true,
        ),

        DetailRow(
          label: 'Last Power Update',
          value: _formatLastUpdateTime(group.lastPowerUpdateTime),
          showDivider: true,
        ),

        StatusDetailRow(
          label: 'Polling Status',
          statusText: workgroup.pollEnabled ? 'Active' : 'Disabled',
          statusColor: workgroup.pollEnabled ? Colors.green : Colors.orange,
          showDivider: true,
        ),

        // Gateway Router
        DetailRow(
          label: 'Gateway Router',
          value: group.gatewayRouterIpAddress.isEmpty
              ? 'Not set'
              : group.gatewayRouterIpAddress,
          showDivider: true,
        ),

        // Scene information
        DetailRow(
          label: 'Scene Count',
          value: '${group.sceneTable.length} scenes',
          showDivider: true,
        ),

        // Settings
        DetailRow(
          label: 'Refresh Props After Action',
          value: group.refreshPropsAfterAction.toString(),
          showDivider: true,
        ),

        // Status information
        if (group.actionResult.isNotEmpty)
          DetailRow(
            label: 'Action Result',
            value: group.actionResult,
            showDivider: true,
          ),

        if (group.lastMessage.isNotEmpty)
          DetailRow(
            label: 'Last Message',
            value: group.lastMessage,
            showDivider: true,
          ),

        if (group.lastMessageTime != null)
          DetailRow(
            label: 'Message Time',
            value: DateFormat(
              'MMM d, yyyy h:mm:ss a',
            ).format(group.lastMessageTime!),
            showDivider: true,
          ),
      ],
      children: [
        // Scene Table as nested expandable item
        if (group.sceneTable.isNotEmpty)
          ExpandableListItem(
            title: 'Scenes',
            subtitle: '${group.sceneTable.length} scenes configured',
            leadingIcon: Icons.movie,
            leadingIconColor: Colors.blue,
            indentLevel: 1,
            detailRows: [
              // Scene table as text
              DetailRow(
                label: 'Scene Numbers',
                value: group.sceneTable.join(', '),
                showDivider: true,
              ),

              // Individual scenes with display names
              ...group.sceneTable.map(
                (scene) => DetailRow(
                  label: 'Scene $scene',
                  value: getSceneDisplayName(scene),
                  customValue: Row(
                    children: [
                      Expanded(
                        child: Text(
                          getSceneDisplayName(scene),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: getSceneChipColor(scene),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          scene.toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  showDivider: true,
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _formatLastUpdateTime(DateTime? lastUpdate) {
    if (lastUpdate == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(lastUpdate);
    }
  }

  Future<void> _confirmDeleteGroup(
    BuildContext context,
    HelvarGroup group,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          'Are you sure you want to delete the group "${group.description.isEmpty ? 'Group ${group.groupId}' : group.description}"?',
        ),
        actions: [
          cancelAction(context),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref
          .read(workgroupsProvider.notifier)
          .removeGroupFromWorkgroup(widget.workgroup.id, group);

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
      // Simulate discovery
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      showSnackBarMsg(context, 'Group discovery completed');

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
