import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/utils/core/date_utils.dart';
import 'package:grms_designer/widgets/common/detail_card.dart';
import 'package:intl/intl.dart';
import '../../models/helvar_models/helvar_group.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../providers/workgroups_provider.dart';
import '../../utils/ui/ui_helpers.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final HelvarGroup group;
  final Workgroup workgroup;

  const GroupDetailScreen({
    super.key,
    required this.group,
    required this.workgroup,
  });

  @override
  GroupDetailScreenState createState() => GroupDetailScreenState();
}

class GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  late TextEditingController _pollingMinutesController;
  late TextEditingController _sceneTableController;
  bool _isLoading = false;

  HelvarGroup get currentGroup {
    final workgroups = ref.watch(workgroupsProvider);
    final currentWorkgroup = workgroups.firstWhere(
      (wg) => wg.id == widget.workgroup.id,
    );
    final group = currentWorkgroup.groups.firstWhere(
      (g) => g.id == widget.group.id,
    );
    return group;
  }

  @override
  void initState() {
    super.initState();
    _pollingMinutesController = TextEditingController(
      text: widget.group.powerPollingMinutes.toString(),
    );
    _sceneTableController = TextEditingController(
      text: widget.group.sceneTable.join(', '),
    );
  }

  @override
  void dispose() {
    _pollingMinutesController.dispose();
    _sceneTableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = currentGroup;

    // Update controllers when group data changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pollingMinutesController.text !=
          group.powerPollingMinutes.toString()) {
        _pollingMinutesController.text = group.powerPollingMinutes.toString();
      }
      if (_sceneTableController.text != group.sceneTable.join(', ')) {
        _sceneTableController.text = group.sceneTable.join(', ');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          group.description.isEmpty
              ? 'Group ${group.groupId}'
              : group.description,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Update Data',
            onPressed: _isLoading ? null : _refreshData,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'query_scenes',
                child: Text('Query Scenes'),
              ),
              const PopupMenuItem(
                value: 'recall_scene',
                child: Text('Recall Scene'),
              ),
              const PopupMenuItem(
                value: 'store_scene',
                child: Text('Store Scene'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: DetailRowsList(
                children: [
                  DetailRow(
                    label: 'Group ID',
                    value: group.groupId,
                    showDivider: true,
                  ),
                  DetailRow(
                    label: 'Description',
                    value: group.description.isEmpty
                        ? 'No description'
                        : group.description,
                    showDivider: true,
                  ),
                  DetailRow(
                    label: 'Type',
                    value: group.type,
                    showDivider: true,
                  ),
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
                  ...group.blockValues.asMap().entries.map(
                    (entry) => DetailRow(
                      label: 'Block ${entry.key + 1}',
                      value: entry.value.toString(),
                      showDivider: true,
                    ),
                  ),
                  DetailRow(
                    label: 'Current Power',
                    value: '${group.powerConsumption.toStringAsFixed(2)} W',
                    showDivider: true,
                  ),
                  EditableDetailRow(
                    label: 'Polling Minutes',
                    controller: _pollingMinutesController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onSubmitted: _savePollingInterval,
                    showDivider: true,
                  ),
                  DetailRow(
                    label: 'Last Power Update',
                    value: getLastUpdateTime(
                      dateTime: group.lastPowerUpdateTime,
                    ),
                    showDivider: true,
                  ),
                  StatusDetailRow(
                    label: 'Polling Status',
                    statusText: widget.workgroup.pollEnabled
                        ? 'Active'
                        : 'Disabled',
                    statusColor: widget.workgroup.pollEnabled
                        ? Colors.green
                        : Colors.orange,
                    showDivider: true,
                  ),
                  DetailRow(
                    label: 'Gateway Router',
                    value: group.gatewayRouterIpAddress.isEmpty
                        ? 'Not set'
                        : group.gatewayRouterIpAddress,
                    showDivider: true,
                  ),
                  EditableDetailRow(
                    label: 'Scene Table',
                    controller: _sceneTableController,
                    onSubmitted: _saveSceneTable,
                    showDivider: true,
                  ),
                  DetailRow(
                    label: 'Scene Count',
                    value: '${group.sceneTable.length} scenes',
                    showDivider: true,
                  ),
                  DetailRow(
                    label: 'Refresh Props After Action',
                    value: group.refreshPropsAfterAction.toString(),
                    showDivider: true,
                  ),
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
                  DetailRow(
                    label: 'Workgroup',
                    value: widget.workgroup.description,
                  ),
                ],
              ),
            ),
    );
  }

  void _savePollingInterval(String value) {
    final minutes = int.tryParse(value);
    if (minutes == null || minutes < 1 || minutes > 1440) {
      showSnackBarMsg(
        context,
        'Please enter a valid interval (1-1440 minutes)',
      );
      _pollingMinutesController.text = currentGroup.powerPollingMinutes
          .toString();
      return;
    }

    final updatedGroup = currentGroup.copyWith(powerPollingMinutes: minutes);
    ref
        .read(workgroupsProvider.notifier)
        .updateGroup(widget.workgroup.id, updatedGroup);

    showSnackBarMsg(context, 'Polling interval updated to $minutes minutes');
  }

  void _saveSceneTable(String value) {
    try {
      final text = value.trim();
      List<int> sceneNumbers = [];

      if (text.isNotEmpty) {
        final parts = text.split(',');
        for (final part in parts) {
          final trimmed = part.trim();
          if (trimmed.isNotEmpty) {
            final sceneNum = int.tryParse(trimmed);
            if (sceneNum != null && sceneNum > 0 && sceneNum <= 255) {
              sceneNumbers.add(sceneNum);
            } else {
              throw Exception('Invalid scene number: $trimmed (must be 1-255)');
            }
          }
        }
      }

      final uniqueScenes = sceneNumbers.toSet().toList()..sort();
      final updatedGroup = currentGroup.copyWith(sceneTable: uniqueScenes);

      ref
          .read(workgroupsProvider.notifier)
          .updateGroup(widget.workgroup.id, updatedGroup);
      _sceneTableController.text = uniqueScenes.join(', ');

      final message = uniqueScenes.isEmpty
          ? 'Scene table cleared'
          : 'Scene table saved with ${uniqueScenes.length} distinct scenes';

      showSnackBarMsg(context, message);
    } catch (e) {
      showSnackBarMsg(context, 'Error saving scene table: $e');
      _sceneTableController.text = currentGroup.sceneTable.join(', ');
    }
  }

  void _refreshData() {
    setState(() {
      _isLoading = true;
    });

    // Simulate refresh operation
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        showSnackBarMsg(context, 'Data refreshed');
      }
    });
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'query_scenes':
        showSnackBarMsg(context, 'Query scenes action');
        break;
      case 'recall_scene':
        showSnackBarMsg(context, 'Recall scene action');
        break;
      case 'store_scene':
        showSnackBarMsg(context, 'Store scene action');
        break;
    }
  }
}
