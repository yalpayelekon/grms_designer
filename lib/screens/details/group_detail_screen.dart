// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/protocol/protocol_parser.dart';
import 'package:grms_designer/providers/workgroups_provider.dart';
import 'package:grms_designer/utils/dialog_utils.dart';
import 'package:grms_designer/utils/scene_utils.dart';
import 'package:intl/intl.dart';
import '../../models/helvar_models/helvar_group.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../providers/router_connection_provider.dart';
import '../../providers/group_polling_provider.dart';
import '../../protocol/query_commands.dart';
import '../../utils/general_ui.dart';
import '../../utils/logger.dart';

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
  late TextEditingController _sceneTableController;
  late TextEditingController _pollingMinutesController;
  bool _isLoading = false;
  bool _isEditingPollingInterval = false;

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
    _sceneTableController = TextEditingController(
      text: widget.group.sceneTable.join(', '),
    );
    _pollingMinutesController = TextEditingController(
      text: widget.group.powerPollingMinutes.toString(),
    );
  }

  @override
  void dispose() {
    _sceneTableController.dispose();
    _pollingMinutesController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final group = currentGroup;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentSceneTable = group.sceneTable.join(', ');
      if (_sceneTableController.text != currentSceneTable) {
        _sceneTableController.text = currentSceneTable;
      }

      if (_pollingMinutesController.text !=
          group.powerPollingMinutes.toString()) {
        _pollingMinutesController.text = group.powerPollingMinutes.toString();
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
            onPressed: _isLoading ? null : _getLatestData,
          ),
        ],
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
                  _buildPowerConsumptionCard(context),
                  const SizedBox(height: 24),
                  _buildSceneTableCard(context),
                ],
              ),
            ),
    );
  }

  Widget _buildPowerConsumptionCard(BuildContext context) {
    final group = currentGroup;
    final isPollingEnabled = widget.workgroup.pollEnabled;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.power, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Power Consumption',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            buildInfoRow(
              'Current Power',
              '${group.powerConsumption.toStringAsFixed(2)} W',
              width: 280,
            ),
            Row(
              children: [
                const SizedBox(
                  width: 140,
                  child: Text(
                    'Polling Interval:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: _isEditingPollingInterval
                      ? Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                controller: _pollingMinutesController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                ),
                                onFieldSubmitted: _savePollingInterval,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('minutes'),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.check,
                                color: Colors.green,
                              ),
                              onPressed: () => _savePollingInterval(
                                _pollingMinutesController.text,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 32,
                                height: 32,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: _cancelPollingEdit,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 32,
                                height: 32,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Text('${group.powerPollingMinutes} minutes'),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 16),
                              onPressed: _startPollingEdit,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 32,
                                height: 32,
                              ),
                              tooltip: 'Edit polling interval',
                            ),
                          ],
                        ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(
                  width: 140,
                  child: Text(
                    'Last Updated:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: group.lastPowerUpdateTime != null
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatLastUpdateTime(group.lastPowerUpdateTime),
                        style: TextStyle(
                          color: group.lastPowerUpdateTime != null
                              ? Colors.black87
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isPollingEnabled) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.autorenew, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Auto-polling active',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pause_circle_outline,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Auto-polling disabled',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _startPollingEdit() {
    setState(() {
      _isEditingPollingInterval = true;
    });
  }

  void _cancelPollingEdit() {
    setState(() {
      _isEditingPollingInterval = false;
      _pollingMinutesController.text = currentGroup.powerPollingMinutes
          .toString();
    });
  }

  void _savePollingInterval(String value) {
    final minutes = int.tryParse(value);
    if (minutes == null || minutes < 1 || minutes > 1440) {
      // Max 24 hours
      showSnackBarMsg(
        context,
        'Please enter a valid interval (1-1440 minutes)',
      );
      return;
    }

    final updatedGroup = currentGroup.copyWith(powerPollingMinutes: minutes);

    ref
        .read(workgroupsProvider.notifier)
        .updateGroup(widget.workgroup.id, updatedGroup);

    // Update polling if it's active
    ref
        .read(pollingStateProvider.notifier)
        .updateGroupPolling(widget.workgroup.id, updatedGroup);

    setState(() {
      _isEditingPollingInterval = false;
    });

    showSnackBarMsg(context, 'Polling interval updated to $minutes minutes');
    logInfo(
      'Updated polling interval for group ${currentGroup.groupId} to $minutes minutes',
    );
  }

  // ... rest of the existing methods remain the same ...

  Future<void> _getLatestData() async {
    if (widget.workgroup.routers.isEmpty) {
      showSnackBarMsg(context, 'No routers available');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final group = currentGroup;
      logInfo('Getting latest data for group ${group.groupId}');

      await Future.wait([_querySceneData(), _queryPowerConsumption()]);

      if (mounted) {
        showSnackBarMsg(context, 'Group data updated successfully');
      }

      logInfo('Successfully updated all data for group ${group.groupId}');
    } catch (e) {
      logError('Error getting latest group data: $e');
      if (mounted) {
        showSnackBarMsg(context, 'Error updating group data: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _queryPowerConsumption() async {
    try {
      final router = widget.workgroup.routers.first;
      final commandService = ref.read(routerCommandServiceProvider);
      final groupIdInt = int.tryParse(currentGroup.groupId);

      if (groupIdInt == null) {
        throw Exception('Invalid group ID: ${currentGroup.groupId}');
      }

      logInfo('Querying power consumption for group ${currentGroup.groupId}');

      final powerCommand = HelvarNetCommands.queryGroupPowerConsumption(
        groupIdInt,
      );
      final powerResult = await commandService.sendCommand(
        router.ipAddress,
        powerCommand,
      );

      if (powerResult.success && powerResult.response != null) {
        final powerValue = ProtocolParser.extractResponseValue(
          powerResult.response!,
        );

        if (powerValue != null) {
          final powerConsumption = double.tryParse(powerValue) ?? 0.0;
          final now = DateTime.now();

          final updatedGroup = currentGroup.copyWith(
            powerConsumption: powerConsumption,
            lastPowerUpdateTime: now,
          );

          await ref
              .read(workgroupsProvider.notifier)
              .updateGroup(widget.workgroup.id, updatedGroup);

          logInfo(
            'Updated power consumption for group ${currentGroup.groupId}: ${powerConsumption}W',
          );
        } else {
          logWarning('Empty power consumption value received');
        }
      } else {
        logWarning(
          'Failed to query power consumption: ${powerResult.response}',
        );
      }
    } catch (e) {
      logError('Error querying power consumption: $e');
    }
  }

  // ... include all other existing methods from the original file ...

  Widget _buildInfoCard(BuildContext context) {
    final group = currentGroup;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.layers, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Group Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            buildInfoRow('ID', group.groupId),
            buildInfoRow('Description', group.description),
            buildInfoRow('Type', group.type),
            if (group.lsig != null) buildInfoRow('LSIG', group.lsig.toString()),
            if (group.lsib1 != null)
              buildInfoRow('LSIB1', group.lsib1.toString()),
            if (group.lsib2 != null)
              buildInfoRow('LSIB2', group.lsib2.toString()),
            for (int i = 0; i < group.blockValues.length; i++)
              buildInfoRow('Block${i + 1}', group.blockValues[i].toString()),
            buildInfoRow('Gateway Router', group.gatewayRouterIpAddress),
            buildInfoRow(
              'Refresh Props After Action',
              group.refreshPropsAfterAction.toString(),
            ),
            if (group.actionResult.isNotEmpty)
              buildInfoRow('Action Result', group.actionResult),
            if (group.lastMessage.isNotEmpty)
              buildInfoRow('Last Message', group.lastMessage),
            if (group.lastMessageTime != null)
              buildInfoRow(
                'Message Time',
                DateFormat(
                  'MMM d, yyyy h:mm:ss a',
                ).format(group.lastMessageTime!),
              ),
            buildInfoRow('Workgroup', widget.workgroup.description),
          ],
        ),
      ),
    );
  }

  Widget _buildSceneTableCard(BuildContext context) {
    final group = currentGroup;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.table_chart, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Scene Table',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: _handleSceneAction,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'query',
                      child: Text('Query Scenes'),
                    ),
                    const PopupMenuItem(
                      value: 'query_names',
                      child: Text('Query Scene Names'),
                    ),
                    const PopupMenuItem(
                      value: 'recall',
                      child: Text('Recall Scene'),
                    ),
                    const PopupMenuItem(
                      value: 'store',
                      child: Text('Store Scene'),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Scene Numbers (comma-separated):',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _sceneTableController,
              decoration: InputDecoration(
                hintText:
                    'Enter scene numbers separated by commas (e.g., 1, 2, 5, 8)',
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.save),
                      tooltip: 'Save Scene Table',
                      onPressed: _saveSceneTable,
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear Scene Table',
                      onPressed: _clearSceneTable,
                    ),
                  ],
                ),
              ),
              maxLines: 3,
              minLines: 1,
            ),
            const SizedBox(height: 8),
            if (group.sceneTable.isNotEmpty) ...[
              Text(
                'Current Scenes: ${group.sceneTable.length} scenes',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: group.sceneTable.map((scene) {
                  return Chip(
                    label: Text(getSceneDisplayName(scene)),
                    backgroundColor: getSceneChipColor(scene),
                    onDeleted: () => _removeSceneFromTable(scene),
                    deleteIcon: const Icon(Icons.close, size: 16),
                  );
                }).toList(),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'No scenes in table. Query scenes to populate automatically.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Include all other scene-related methods...
  void _handleSceneAction(String action) {
    switch (action) {
      case 'query':
        _querySceneData();
        break;
      case 'query_names':
        _querySceneNames();
        break;
      case 'recall':
        _showRecallSceneDialog();
        break;
      case 'store':
        _showStoreSceneDialog();
        break;
    }
  }

  Future<void> _querySceneData() async {
    try {
      final router = widget.workgroup.routers.first;
      final sceneQueryService = ref.read(sceneQueryServiceProvider);
      final groupIdInt = int.tryParse(widget.group.groupId);

      if (groupIdInt == null) {
        throw Exception('Invalid group ID: ${currentGroup.groupId}');
      }

      logInfo('Querying scene data for group ${currentGroup.groupId}');

      final sceneData = await sceneQueryService.exploreGroupScenes(
        router.ipAddress,
        groupIdInt,
      );

      final allScenes = sceneQueryService.buildSceneTable(sceneData);
      final meaningfulScenes = allScenes.where((scene) {
        return scene != 129;
      }).toList();

      final scenesToShow = meaningfulScenes.isNotEmpty
          ? meaningfulScenes
          : allScenes;

      _sceneTableController.text = scenesToShow.join(', ');

      final currentGroupData = currentGroup;
      final updatedGroup = currentGroupData.copyWith(sceneTable: scenesToShow);

      await ref
          .read(workgroupsProvider.notifier)
          .updateGroup(widget.workgroup.id, updatedGroup);

      logInfo(
        'Updated scene table for group ${currentGroupData.groupId}: $scenesToShow',
      );
    } catch (e) {
      logError('Error querying scene data: $e');
      rethrow;
    }
  }

  Future<void> _querySceneNames() async {
    if (widget.workgroup.routers.isEmpty) {
      showSnackBarMsg(context, 'No routers available');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final router = widget.workgroup.routers.first;
      final sceneQueryService = ref.read(sceneQueryServiceProvider);

      logInfo('Querying scene names for router ${router.ipAddress}');

      final sceneNames = await sceneQueryService.querySceneNames(
        router.ipAddress,
      );

      if (mounted) {
        if (sceneNames.isNotEmpty) {
          _showSceneNamesDialog(sceneNames);
        } else {
          showSnackBarMsg(context, 'No scene names found');
        }
      }
    } catch (e) {
      logError('Error querying scene names: $e');
      if (mounted) {
        showSnackBarMsg(context, 'Error querying scene names: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSceneNamesDialog(List<String> sceneNames) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scene Names'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Found ${sceneNames.length} scene names:'),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sceneNames.length,
                  itemBuilder: (context, index) {
                    final sceneName = sceneNames[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.movie, size: 20),
                        title: Text(
                          sceneName,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: _parseSceneNameInfo(sceneName),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [closeAction(context)],
      ),
    );
  }

  Widget? _parseSceneNameInfo(String sceneName) {
    if (sceneName.startsWith('[@') && sceneName.contains(':')) {
      try {
        final parts = sceneName.substring(2, sceneName.length - 1).split(':');
        if (parts.length == 2) {
          final address = parts[0];
          final description = parts[1];
          return Text(
            'Address: $address • $description',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          );
        }
      } catch (e) {
        // If parsing fails, just return null
      }
    }
    return null;
  }

  void _saveSceneTable() {
    try {
      final text = _sceneTableController.text.trim();
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
      logInfo('Scene table updated: $uniqueScenes');
    } catch (e) {
      showSnackBarMsg(context, 'Error saving scene table: $e');
    }
  }

  void _clearSceneTable() {
    _sceneTableController.clear();

    final updatedGroup = currentGroup.copyWith(sceneTable: []);

    ref
        .read(workgroupsProvider.notifier)
        .updateGroup(widget.workgroup.id, updatedGroup);

    logInfo('Scene table cleared for group ${currentGroup.groupId}');
  }

  void _removeSceneFromTable(int sceneNumber) {
    final currentScenes = currentGroup.sceneTable.toList();
    currentScenes.remove(sceneNumber);

    final updatedGroup = currentGroup.copyWith(sceneTable: currentScenes);

    ref
        .read(workgroupsProvider.notifier)
        .updateGroup(widget.workgroup.id, updatedGroup);

    _sceneTableController.text = currentScenes.join(', ');
    showSnackBarMsg(context, 'Removed scene $sceneNumber');
    logInfo('Removed scene $sceneNumber from group ${currentGroup.groupId}');
  }

  void _showRecallSceneDialog() {
    if (currentGroup.sceneTable.isEmpty) {
      showSnackBarMsg(context, 'No scenes available to recall');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recall Scene'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a scene to recall:'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: currentGroup.sceneTable.map((scene) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _recallScene(scene);
                  },
                  child: Text('Scene $scene'),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [cancelAction(context)],
      ),
    );
  }

  void _showStoreSceneDialog() {
    final sceneController = TextEditingController();
    final blockController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Store Scene'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: sceneController,
              decoration: const InputDecoration(
                labelText: 'Scene Number (1-16)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: blockController,
              decoration: const InputDecoration(
                labelText: 'Block Number (1-8)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          cancelAction(context),
          ElevatedButton(
            onPressed: () {
              final scene = int.tryParse(sceneController.text);
              final block = int.tryParse(blockController.text);

              if (scene != null && block != null) {
                Navigator.of(context).pop();
                _storeScene(scene, block);
              } else {
                showSnackBarMsg(context, 'Please enter valid numbers');
              }
            },
            child: const Text('Store'),
          ),
        ],
      ),
    );
  }

  Future<void> _recallScene(int sceneNumber) async {
    if (widget.workgroup.routers.isEmpty) {
      showSnackBarMsg(context, 'No routers available');
      return;
    }

    try {
      final router = widget.workgroup.routers.first;
      final commandService = ref.read(routerCommandServiceProvider);
      final groupIdInt = int.tryParse(currentGroup.groupId);

      if (groupIdInt == null) {
        throw Exception('Invalid group ID');
      }

      final command = HelvarNetCommands.recallSceneGroup(
        groupIdInt,
        1, // block
        sceneNumber,
      );

      final result = await commandService.sendCommand(
        router.ipAddress,
        command,
      );

      if (result.success) {
        logInfo(
          'Recalled scene $sceneNumber for group ${currentGroup.groupId}',
        );
      } else {
        throw Exception('Command failed: ${result.response}');
      }
    } catch (e) {
      logError('Error recalling scene: $e');
      showSnackBarMsg(context, 'Error recalling scene: $e');
    }
  }

  Future<void> _storeScene(int sceneNumber, int blockNumber) async {
    if (widget.workgroup.routers.isEmpty) {
      showSnackBarMsg(context, 'No routers available');
      return;
    }

    try {
      final router = widget.workgroup.routers.first;
      final commandService = ref.read(routerCommandServiceProvider);
      final groupIdInt = int.tryParse(currentGroup.groupId);

      if (groupIdInt == null) {
        throw Exception('Invalid group ID');
      }

      final command = HelvarNetCommands.storeAsSceneGroup(
        groupIdInt,
        blockNumber,
        sceneNumber,
      );

      final result = await commandService.sendCommand(
        router.ipAddress,
        command,
      );

      if (result.success) {
        logInfo(
          'Stored scene $sceneNumber in block $blockNumber for group ${currentGroup.groupId}',
        );

        await Future.delayed(const Duration(milliseconds: 500));
        _querySceneData();
      } else {
        throw Exception('Command failed: ${result.response}');
      }
    } catch (e) {
      logError('Error storing scene: $e');
      showSnackBarMsg(context, 'Error storing scene: $e');
    }
  }
}
