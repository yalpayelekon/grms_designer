import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          IconButton(
            icon: const Icon(Icons.science),
            tooltip: 'Test Scene Queries',
            onPressed: _isLoading ? null : _testSceneQueries,
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
            _buildDetailRow('ID', widget.group.groupId),
            _buildDetailRow('Description', widget.group.description),
            _buildDetailRow('Type', widget.group.type),
            if (widget.group.lsig != null)
              _buildDetailRow('LSIG', widget.group.lsig.toString()),
            if (widget.group.lsib1 != null)
              _buildDetailRow('LSIB1', widget.group.lsib1.toString()),
            if (widget.group.lsib2 != null)
              _buildDetailRow('LSIB2', widget.group.lsib2.toString()),
            for (int i = 0; i < widget.group.blockValues.length; i++)
              _buildDetailRow(
                'Block${i + 1}',
                widget.group.blockValues[i].toString(),
              ),
            _buildDetailRow(
              'Power Consumption',
              '${widget.group.powerConsumption} W',
            ),
            _buildDetailRow(
              'Power Polling',
              '${widget.group.powerPollingMinutes} minutes',
            ),
            _buildDetailRow(
              'Gateway Router',
              widget.group.gatewayRouterIpAddress,
            ),
            _buildDetailRow(
              'Refresh Props After Action',
              widget.group.refreshPropsAfterAction.toString(),
            ),
            if (widget.group.actionResult.isNotEmpty)
              _buildDetailRow('Action Result', widget.group.actionResult),
            if (widget.group.lastMessage.isNotEmpty)
              _buildDetailRow('Last Message', widget.group.lastMessage),
            if (widget.group.lastMessageTime != null)
              _buildDetailRow(
                'Message Time',
                DateFormat(
                  'MMM d, yyyy h:mm:ss a',
                ).format(widget.group.lastMessageTime!),
              ),
            _buildDetailRow('Workgroup', widget.workgroup.description),
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
                    label: Text('Scene $scene'),
                    backgroundColor: Colors.blue.withOpacity(0.1),
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

  void _handleSceneAction(String action) {
    switch (action) {
      case 'query':
        _querySceneData();
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
    if (widget.workgroup.routers.isEmpty) {
      showSnackBarMsg(context, 'No routers available');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final router = widget.workgroup.routers.first;
      final commandService = ref.read(routerCommandServiceProvider);
      final groupIdInt = int.tryParse(widget.group.groupId);

      if (groupIdInt == null) {
        throw Exception('Invalid group ID: ${widget.group.groupId}');
      }

      logInfo('Querying scene data for group ${widget.group.groupId}');

      // Query scenes from different blocks
      final sceneNumbers = <int>{};

      for (int block = 1; block <= 8; block++) {
        try {
          final command = HelvarNetCommands.queryLastSceneInBlock(
            groupIdInt,
            block,
          );
          final result = await commandService.sendCommand(
            router.ipAddress,
            command,
          );

          if (result.success && result.response != null) {
            final responseData = result.response!;
            logInfo('Block $block response: $responseData');

            // Try to extract scene number from response
            if (responseData.contains('=')) {
              final parts = responseData.split('=');
              if (parts.length > 1) {
                final sceneStr = parts[1].replaceAll('#', '').trim();
                final sceneNum = int.tryParse(sceneStr);
                if (sceneNum != null && sceneNum > 0) {
                  sceneNumbers.add(sceneNum);
                  logInfo('Found scene $sceneNum in block $block');
                }
              }
            }
          }

          // Small delay between queries
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          logWarning('Error querying block $block: $e');
        }
      }

      // Update the scene table with discovered scenes
      final newSceneTable = sceneNumbers.toList()..sort();
      _sceneTableController.text = newSceneTable.join(', ');

      if (mounted) {
        showSnackBarMsg(
          context,
          'Found ${newSceneTable.length} scenes: ${newSceneTable.join(', ')}',
        );
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

  void _saveSceneTable() {
    try {
      final text = _sceneTableController.text.trim();
      if (text.isEmpty) {
        // TODO: Update the group with empty scene table
        showSnackBarMsg(context, 'Scene table cleared');
        return;
      }

      // Parse comma-separated scene numbers
      final sceneNumbers = <int>[];
      final parts = text.split(',');

      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.isNotEmpty) {
          final sceneNum = int.tryParse(trimmed);
          if (sceneNum != null && sceneNum > 0 && sceneNum <= 16) {
            sceneNumbers.add(sceneNum);
          } else {
            throw Exception('Invalid scene number: $trimmed (must be 1-16)');
          }
        }
      }

      // Remove duplicates and sort
      final uniqueScenes = sceneNumbers.toSet().toList()..sort();

      // TODO: Update the actual group model through provider
      // For now, just update the controller to show cleaned data
      _sceneTableController.text = uniqueScenes.join(', ');

      showSnackBarMsg(
        context,
        'Scene table saved with ${uniqueScenes.length} scenes',
      );
      logInfo('Scene table updated: $uniqueScenes');
    } catch (e) {
      showSnackBarMsg(context, 'Error saving scene table: $e');
    }
  }

  void _clearSceneTable() {
    _sceneTableController.clear();
    // TODO: Update the group model
    showSnackBarMsg(context, 'Scene table cleared');
  }

  void _removeSceneFromTable(int sceneNumber) {
    final currentScenes = widget.group.sceneTable.toList();
    currentScenes.remove(sceneNumber);
    _sceneTableController.text = currentScenes.join(', ');
    // TODO: Update the group model
    showSnackBarMsg(context, 'Removed scene $sceneNumber');
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
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

  Future<void> _testSceneQueries() async {
    if (widget.workgroup.routers.isEmpty) {
      showSnackBarMsg(context, 'No routers available for testing');
      return;
    }

    final router = widget.workgroup.routers.first;
    final groupIdInt = int.tryParse(widget.group.groupId);

    if (groupIdInt == null) {
      showSnackBarMsg(context, 'Invalid group ID for testing');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final commandService = ref.read(routerCommandServiceProvider);

      logInfo(
        '=== Testing Scene Queries for Group ${widget.group.groupId} ===',
      );

      // Test different query commands and log responses
      await _testCommand('Query Last Scene In Group', () async {
        final command = HelvarNetCommands.queryLastSceneInGroup(groupIdInt);
        return await commandService.sendCommand(router.ipAddress, command);
      });

      // Test each block
      for (int block = 1; block <= 4; block++) {
        await _testCommand('Query Last Scene In Block $block', () async {
          final command = HelvarNetCommands.queryLastSceneInBlock(
            groupIdInt,
            block,
          );
          return await commandService.sendCommand(router.ipAddress, command);
        });
        await Future.delayed(const Duration(milliseconds: 100));
      }

      await _testCommand('Query Scene Names', () async {
        final command = HelvarNetCommands.querySceneNames();
        return await commandService.sendCommand(router.ipAddress, command);
      });

      if (mounted) {
        showSnackBarMsg(
          context,
          'Scene query tests completed. Check logs for detailed results.',
        );
      }
    } catch (e) {
      logError('Error during scene query testing: $e');
      if (mounted) {
        showSnackBarMsg(context, 'Error during testing: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testCommand(
    String testName,
    Future<dynamic> Function() commandFunction,
  ) async {
    try {
      logInfo('--- $testName ---');
      final result = await commandFunction();

      logInfo('Command sent successfully');
      logInfo('Success: ${result.success}');
      logInfo('Response: ${result.response}');

      if (result.success && result.response != null) {
        final extractedValue = result.response!.contains('=')
            ? result.response!.split('=').last.replaceAll('#', '').trim()
            : null;
        logInfo('Extracted value: $extractedValue');
      }
    } catch (e) {
      logError('$testName failed: $e');
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
