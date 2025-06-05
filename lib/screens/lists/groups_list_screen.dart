import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/providers/router_connection_provider.dart';
import '../../models/helvar_models/helvar_group.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../providers/workgroups_provider.dart';
import '../../widgets/common/expandable_list_item.dart';
import '../../utils/ui/ui_helpers.dart';
import '../details/group_detail_screen.dart';

class GroupsListScreen extends ConsumerStatefulWidget {
  final Workgroup workgroup;
  final bool asWidget;

  const GroupsListScreen({
    super.key,
    required this.workgroup,
    this.asWidget = false,
  });

  @override
  GroupsListScreenState createState() => GroupsListScreenState();
}

class GroupsListScreenState extends ConsumerState<GroupsListScreen> {
  bool _isLoading = false;

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
      lazyChildren: () => [
        GroupDetailScreen(group: group, workgroup: workgroup, asWidget: true),
      ],
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

  Widget _buildContent() {
    final workgroups = ref.watch(workgroupsProvider);
    final currentWorkgroup = workgroups.firstWhere(
      (wg) => wg.id == widget.workgroup.id,
      orElse: () => widget.workgroup,
    );

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (currentWorkgroup.groups.isEmpty) {
      return _buildEmptyState();
    }

    if (widget.asWidget) {
      // When used as widget, return just the group items without ExpandableListView wrapper
      return Column(
        children: currentWorkgroup.groups
            .map((group) => _buildGroupItem(group, currentWorkgroup))
            .toList(),
      );
    }

    return ExpandableListView(
      padding: const EdgeInsets.all(8.0),
      children: currentWorkgroup.groups
          .map((group) => _buildGroupItem(group, currentWorkgroup))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.asWidget) {
      return _buildContent();
    }

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
      body: _buildContent(),
    );
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
      final router = widget.workgroup.routers.first;
      final discoveryService = ref.watch(discoveryServiceProvider);
      final discoveredGroups = await discoveryService.discoverGroups(
        router.ipAddress,
      );

      if (discoveredGroups.isEmpty) {
        if (!mounted) return;
        showSnackBarMsg(context, 'No groups discovered');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (!mounted) return;
      final shouldAdd =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Groups Discovered'),
              content: Text(
                'Found ${discoveredGroups.length} groups. Do you want to add them?',
              ),
              actions: [
                cancelAction(context),
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

      final existingGroupIds = widget.workgroup.groups
          .map((g) => g.groupId)
          .toSet();
      final newGroups = discoveredGroups
          .where((g) => !existingGroupIds.contains(g.groupId))
          .toList();

      for (final group in newGroups) {
        await ref
            .read(workgroupsProvider.notifier)
            .addGroupToWorkgroup(widget.workgroup.id, group);
      }

      if (!mounted) return;
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
