// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/providers/workgroups_provider.dart';
import 'package:grms_designer/utils/dialog_utils.dart';
import 'package:intl/intl.dart';
import '../../models/helvar_models/helvar_group.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../providers/router_connection_provider.dart';
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _sceneTableController = TextEditingController(
      text: widget.group.sceneTable.join(', '),
    );
  }

  @override
  void dispose() {
    _sceneTableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.group.description.isEmpty
              ? 'Group ${widget.group.groupId}'
              : widget.group.description,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Query Scene Data',
            onPressed: _isLoading ? null : _querySceneData,
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
                  _buildSceneTableCard(context),
                  const SizedBox(height: 24),
                  _buildDevicesSection(context),
                ],
              ),
            ),
    );
  }

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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget? _parseSceneNameInfo(String sceneName) {
    // Parse scene names like "[@24.1.1:Group 24 Scene 1.1]"
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

  Future<void> _querySceneData() async {
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
      final groupIdInt = int.tryParse(widget.group.groupId);

      if (groupIdInt == null) {
        throw Exception('Invalid group ID: ${widget.group.groupId}');
      }

      logInfo('Querying scene data for group ${widget.group.groupId}');

      // Use SceneQueryService to explore group scenes
      final sceneData = await sceneQueryService.exploreGroupScenes(
        router.ipAddress,
        groupIdInt,
      );

      // Build scene table using SceneQueryService, but filter out special scenes
      final allScenes = sceneQueryService.buildSceneTable(sceneData);
      final meaningfulScenes = allScenes.where((scene) {
        // Filter out common system scenes that appear in all blocks
        return scene !=
            129; // Min level appears in all blocks, probably not meaningful
      }).toList();

      final scenesToShow = meaningfulScenes.isNotEmpty
          ? meaningfulScenes
          : allScenes;
      _sceneTableController.text = scenesToShow.join(', ');

      if (mounted) {
        if (meaningfulScenes.isEmpty && allScenes.isNotEmpty) {
          showSnackBarMsg(
            context,
            'Found ${allScenes.length} system scenes: ${allScenes.join(', ')} (showing all)',
          );
        } else {
          showSnackBarMsg(
            context,
            'Found ${scenesToShow.length} scenes: ${scenesToShow.join(', ')}',
          );
        }
      }
    } catch (e) {
      logError('Error querying scene data: $e');
      if (mounted) {
        showSnackBarMsg(context, 'Error querying scenes: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                const Icon(Icons.layers, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Group Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            buildInfoRow('ID', widget.group.groupId),
            buildInfoRow('Description', widget.group.description),
            buildInfoRow('Type', widget.group.type),
            if (widget.group.lsig != null)
              buildInfoRow('LSIG', widget.group.lsig.toString()),
            if (widget.group.lsib1 != null)
              buildInfoRow('LSIB1', widget.group.lsib1.toString()),
            if (widget.group.lsib2 != null)
              buildInfoRow('LSIB2', widget.group.lsib2.toString()),
            for (int i = 0; i < widget.group.blockValues.length; i++)
              buildInfoRow(
                'Block${i + 1}',
                widget.group.blockValues[i].toString(),
              ),
            buildInfoRow(
              'Power Consumption',
              '${widget.group.powerConsumption} W',
              width: 280,
            ),
            buildInfoRow(
              'Power Polling',
              '${widget.group.powerPollingMinutes} minutes',
            ),
            buildInfoRow('Gateway Router', widget.group.gatewayRouterIpAddress),
            buildInfoRow(
              'Refresh Props After Action',
              widget.group.refreshPropsAfterAction.toString(),
            ),
            if (widget.group.actionResult.isNotEmpty)
              buildInfoRow('Action Result', widget.group.actionResult),
            if (widget.group.lastMessage.isNotEmpty)
              buildInfoRow('Last Message', widget.group.lastMessage),
            if (widget.group.lastMessageTime != null)
              buildInfoRow(
                'Message Time',
                DateFormat(
                  'MMM d, yyyy h:mm:ss a',
                ).format(widget.group.lastMessageTime!),
              ),
            buildInfoRow('Workgroup', widget.workgroup.description),
          ],
        ),
      ),
    );
  }

  Widget _buildSceneTableCard(BuildContext context) {
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
            if (widget.group.sceneTable.isNotEmpty) ...[
              Text(
                'Current Scenes: ${widget.group.sceneTable.length} scenes',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: widget.group.sceneTable.map((scene) {
                  return Chip(
                    label: Text(_getSceneDisplayName(scene)),
                    backgroundColor: _getSceneChipColor(scene),
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

  String _getSceneDisplayName(int scene) {
    switch (scene) {
      case 128:
        return 'Scene $scene (Off)';
      case 129:
        return 'Scene $scene (Min Level)';
      case 130:
        return 'Scene $scene (Max Level)';
      case 137:
        return 'Scene $scene (0%)';
      case 138:
        return 'Scene $scene (1%)';
      case 237:
        return 'Scene $scene (100%)';
      default:
        if (scene >= 137 && scene <= 237) {
          final percentage = scene - 137;
          return 'Scene $scene ($percentage%)';
        }
        return 'Scene $scene';
    }
  }

  Color _getSceneChipColor(int scene) {
    switch (scene) {
      case 128: // Off
        return Colors.red.withOpacity(0.1);
      case 129: // Min Level
        return Colors.orange.withOpacity(0.1);
      case 130: // Max Level
        return Colors.green.withOpacity(0.1);
      default:
        if (scene >= 137 && scene <= 237) {
          // Percentage scenes
          return Colors.purple.withOpacity(0.1);
        }
        return Colors.blue.withOpacity(0.1);
    }
  }

  Widget _buildDevicesSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.devices, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Devices in this Group',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  'No devices information available for this group',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

      final updatedGroup = widget.group.copyWith(sceneTable: uniqueScenes);

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

    final updatedGroup = widget.group.copyWith(sceneTable: []);

    ref
        .read(workgroupsProvider.notifier)
        .updateGroup(widget.workgroup.id, updatedGroup);

    showSnackBarMsg(context, 'Scene table cleared');
    logInfo('Scene table cleared for group ${widget.group.groupId}');
  }

  void _removeSceneFromTable(int sceneNumber) {
    final currentScenes = widget.group.sceneTable.toList();
    currentScenes.remove(sceneNumber);

    final updatedGroup = widget.group.copyWith(sceneTable: currentScenes);

    ref
        .read(workgroupsProvider.notifier)
        .updateGroup(widget.workgroup.id, updatedGroup);

    _sceneTableController.text = currentScenes.join(', ');
    showSnackBarMsg(context, 'Removed scene $sceneNumber');
    logInfo('Removed scene $sceneNumber from group ${widget.group.groupId}');
  }

  void _showRecallSceneDialog() {
    if (widget.group.sceneTable.isEmpty) {
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
              children: widget.group.sceneTable.map((scene) {
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
      final groupIdInt = int.tryParse(widget.group.groupId);

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
        showSnackBarMsg(context, 'Scene $sceneNumber recalled successfully');
        logInfo(
          'Recalled scene $sceneNumber for group ${widget.group.groupId}',
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
      final groupIdInt = int.tryParse(widget.group.groupId);

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
        showSnackBarMsg(
          context,
          'Scene $sceneNumber stored in block $blockNumber successfully',
        );
        logInfo(
          'Stored scene $sceneNumber in block $blockNumber for group ${widget.group.groupId}',
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
