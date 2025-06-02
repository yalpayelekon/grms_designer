import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:grms_designer/screens/dialogs/network_interface_dialog.dart';
import 'package:grms_designer/widgets/common/detail_card.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/helvar_group.dart';
import '../../providers/workgroups_provider.dart';
import '../../widgets/common/expandable_list_item.dart';
import '../../utils/ui_helpers.dart';
import '../../utils/network_utils.dart';
import '../../comm/discovery_manager.dart';
import '../../utils/file_dialog_helper.dart';
import '../dialogs/workgroup_selection_dialog.dart';
import '../../providers/settings_provider.dart';

class WorkgroupListScreen extends ConsumerStatefulWidget {
  const WorkgroupListScreen({super.key});

  @override
  WorkgroupListScreenState createState() => WorkgroupListScreenState();
}

class WorkgroupListScreenState extends ConsumerState<WorkgroupListScreen> {
  bool _isLoading = false;
  DiscoveryManager? discoveryManager;

  @override
  Widget build(BuildContext context) {
    final workgroups = ref.watch(workgroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workgroups'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'discover',
                child: Text('Discover New Workgroup'),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Text('Export Workgroups'),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Text('Import Workgroups'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Discovering Helvar routers...'),
                ],
              ),
            )
          : workgroups.isEmpty
          ? _buildEmptyState()
          : ExpandableListView(
              padding: const EdgeInsets.all(8.0),
              children: workgroups
                  .map((workgroup) => _buildWorkgroupItem(workgroup))
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
          const Text('No workgroups found', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.search),
            label: const Text('Discover New Workgroup'),
            onPressed: () => _discoverWorkgroups(),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkgroupItem(Workgroup workgroup) {
    return ExpandableListItem(
      title: workgroup.description,
      subtitle:
          'Network: ${workgroup.networkInterface} • ${workgroup.routers.length} routers • ${workgroup.groups.length} groups',
      leadingIcon: Icons.lan,
      leadingIconColor: Colors.blue,
      showDelete: true,
      onDelete: () => _confirmDeleteWorkgroup(workgroup),
      customTrailingActions: [
        IconButton(
          icon: const Icon(Icons.search, size: 18),
          tooltip: 'Discover More Routers',
          onPressed: () => _discoverMoreRouters(workgroup),
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
      detailRows: [
        // Basic workgroup information
        DetailRow(label: 'ID', value: workgroup.id, showDivider: true),

        DetailRow(
          label: 'Description',
          value: workgroup.description,
          showDivider: true,
        ),

        DetailRow(
          label: 'Network Interface',
          value: workgroup.networkInterface,
          showDivider: true,
        ),

        DetailRow(
          label: 'Gateway Router IP',
          value: workgroup.gatewayRouterIpAddress.isEmpty
              ? 'Not set'
              : workgroup.gatewayRouterIpAddress,
          showDivider: true,
        ),

        StatusDetailRow(
          label: 'Polling Enabled',
          statusText: workgroup.pollEnabled ? 'Yes' : 'No',
          statusColor: workgroup.pollEnabled ? Colors.green : Colors.orange,
          showDivider: true,
        ),

        DetailRow(
          label: 'Refresh Props After Action',
          value: workgroup.refreshPropsAfterAction.toString(),
          showDivider: true,
        ),

        if (workgroup.lastPollTime != null)
          DetailRow(
            label: 'Last Poll Time',
            value: _formatDateTime(workgroup.lastPollTime!),
            showDivider: true,
          ),
      ],
      children: [
        // Groups section
        if (workgroup.groups.isNotEmpty)
          ExpandableListItem(
            title: 'Groups',
            subtitle: '${workgroup.groups.length} groups',
            leadingIcon: Icons.layers,
            leadingIconColor: Colors.green,
            indentLevel: 1,
            children: workgroup.groups
                .map((group) => _buildGroupItem(group, workgroup))
                .toList(),
          ),

        // Routers section
        if (workgroup.routers.isNotEmpty)
          ExpandableListItem(
            title: 'Routers',
            subtitle: '${workgroup.routers.length} routers',
            leadingIcon: Icons.router,
            leadingIconColor: Colors.purple,
            indentLevel: 1,
            children: workgroup.routers
                .map((router) => _buildRouterItem(router, workgroup))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildGroupItem(HelvarGroup group, Workgroup workgroup) {
    return ExpandableListItem(
      title: group.description.isEmpty
          ? "Group ${group.groupId}"
          : group.description,
      subtitle:
          'ID: ${group.groupId} • Power: ${group.powerConsumption.toStringAsFixed(1)}W',
      leadingIcon: Icons.group,
      leadingIconColor: Colors.green,
      indentLevel: 2,
      detailRows: [
        DetailRow(label: 'Group ID', value: group.groupId, showDivider: true),

        DetailRow(label: 'Type', value: group.type, showDivider: true),

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

        if (group.sceneTable.isNotEmpty)
          DetailRow(
            label: 'Scenes',
            value:
                '${group.sceneTable.length} scenes: ${group.sceneTable.join(', ')}',
            showDivider: true,
          ),

        if (group.gatewayRouterIpAddress.isNotEmpty)
          DetailRow(
            label: 'Gateway Router',
            value: group.gatewayRouterIpAddress,
            showDivider: true,
          ),
      ],
    );
  }

  Widget _buildRouterItem(HelvarRouter router, Workgroup workgroup) {
    return ExpandableListItem(
      title: router.description,
      subtitle:
          'IP: ${router.ipAddress} • Address: ${router.address} • ${router.devices.length} devices',
      leadingIcon: Icons.router,
      leadingIconColor: Colors.purple,
      indentLevel: 2,
      detailRows: [
        DetailRow(
          label: 'Description',
          value: router.description,
          showDivider: true,
        ),

        DetailRow(
          label: 'IP Address',
          value: router.ipAddress,
          showDivider: true,
        ),

        DetailRow(label: 'Address', value: router.address, showDivider: true),

        DetailRow(
          label: 'Device Count',
          value: '${router.devices.length} devices',
          showDivider: true,
        ),

        // Device count by subnet
        if (router.devicesBySubnet.isNotEmpty) ...[
          DetailRow(
            label: 'Subnets',
            value: '${router.devicesBySubnet.length} subnets',
            showDivider: true,
          ),

          ...router.devicesBySubnet.entries.map(
            (entry) => DetailRow(
              label: 'Subnet ${entry.key}',
              value: '${entry.value.length} devices',
              showDivider: true,
            ),
          ),
        ],
      ],
      children: [
        // Show subnets and devices if any
        if (router.devicesBySubnet.isNotEmpty)
          ...router.devicesBySubnet.entries.map(
            (entry) => ExpandableListItem(
              title: 'Subnet ${entry.key}',
              subtitle: '${entry.value.length} devices',
              leadingIcon: Icons.hub,
              leadingIconColor: Colors.orange,
              indentLevel: 3,
              children: entry.value
                  .map(
                    (device) => ExpandableListItem(
                      title: device.description.isEmpty
                          ? 'Device ${device.deviceId}'
                          : device.description,
                      subtitle:
                          'Address: ${device.address} • Type: ${device.helvarType}',
                      leadingIcon: Icons.device_hub,
                      leadingIconColor: Colors.teal,
                      indentLevel: 4,
                      detailRows: [
                        DetailRow(
                          label: 'Device ID',
                          value: device.deviceId.toString(),
                          showDivider: true,
                        ),

                        DetailRow(
                          label: 'Address',
                          value: device.address,
                          showDivider: true,
                        ),

                        DetailRow(
                          label: 'Type',
                          value: device.helvarType,
                          showDivider: true,
                        ),

                        DetailRow(
                          label: 'Props',
                          value: device.props,
                          showDivider: true,
                        ),

                        if (device.state.isNotEmpty)
                          DetailRow(
                            label: 'State',
                            value: device.state,
                            showDivider: true,
                          ),

                        StatusDetailRow(
                          label: 'Emergency',
                          statusText: device.emergency ? 'Yes' : 'No',
                          statusColor: device.emergency
                              ? Colors.red
                              : Colors.green,
                          showDivider: true,
                        ),

                        StatusDetailRow(
                          label: 'Button Device',
                          statusText: device.isButtonDevice ? 'Yes' : 'No',
                          statusColor: device.isButtonDevice
                              ? Colors.blue
                              : Colors.grey,
                          showDivider: true,
                        ),

                        StatusDetailRow(
                          label: 'Multisensor',
                          statusText: device.isMultisensor ? 'Yes' : 'No',
                          statusColor: device.isMultisensor
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
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

  void _handleMenuAction(String action) {
    switch (action) {
      case 'discover':
        _discoverWorkgroups();
        break;
      case 'export':
        _exportWorkgroups();
        break;
      case 'import':
        _importWorkgroups();
        break;
    }
  }

  Future<void> _discoverWorkgroups() async {
    discoveryManager = DiscoveryManager();
    final interfaceResult = await selectNetworkInterface(context);
    if (interfaceResult == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await discoveryManager!.start(interfaceResult.ipv4!);
      final discoveryTimeout = ref.read(discoveryTimeoutProvider);
      final broadcastAddress = calculateBroadcastAddress(
        interfaceResult.ipv4!,
        interfaceResult.subnetMask!,
      );
      await discoveryManager!.sendDiscoveryRequest(
        discoveryTimeout,
        broadcastAddress,
      );

      final discoveredRouters = discoveryManager!.getDiscoveredRouters();
      final workgroupNames = discoveredRouters
          .map((router) => router['workgroup'] ?? 'Unknown')
          .toSet()
          .toList();

      final selectedResult = await _selectWorkgroup(workgroupNames);
      if (selectedResult == null) return;

      if (selectedResult == '__ADD_ALL__') {
        for (String workgroupName in workgroupNames) {
          _createWorkgroup(
            workgroupName,
            interfaceResult.name,
            discoveredRouters,
          );
        }
        if (mounted) {
          showSnackBarMsg(
            context,
            'Added all ${workgroupNames.length} workgroups',
          );
        }
      } else {
        _createWorkgroup(
          selectedResult,
          interfaceResult.name,
          discoveredRouters,
        );
      }
    } catch (e) {
      if (mounted) {
        showSnackBarMsg(context, 'Discovery error: $e');
      }
    } finally {
      if (discoveryManager != null) {
        discoveryManager!.stop();
        discoveryManager = null;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<dynamic> _selectWorkgroup(List<String> workgroupNames) async {
    if (workgroupNames.isEmpty) {
      if (!mounted) return null;
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Discovery Result'),
            content: const Text(
              'No Helvar routers were discovered on the network.',
            ),
            actions: [confirmAction(context)],
          );
        },
      );
      return null;
    }

    if (!mounted) return null;
    return showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) {
        return WorkgroupSelectionDialog(workgroups: workgroupNames);
      },
    );
  }

  void _createWorkgroup(
    String workgroupName,
    String networkInterfaceName,
    List<Map<String, String>> discoveredRouters,
  ) {
    final existingWorkgroups = ref.read(workgroupsProvider);
    final existingWorkgroup = existingWorkgroups.firstWhereOrNull(
      (wg) => wg.description == workgroupName,
    );

    if (existingWorkgroup != null) {
      final newRouters = _buildNewRoutersForExistingWorkgroup(
        existingWorkgroup,
        discoveredRouters,
      );

      if (newRouters.isNotEmpty) {
        _updateExistingWorkgroup(existingWorkgroup, newRouters);
      } else if (mounted) {
        showSnackBarMsg(
          context,
          'No new routers found for existing workgroup: $workgroupName',
        );
      }
      return;
    }

    final newRouters = _buildRoutersForNewWorkgroup(
      discoveredRouters,
      workgroupName,
    );

    if (newRouters.isNotEmpty) {
      _createNewWorkgroup(workgroupName, networkInterfaceName, newRouters);
    }
  }

  String _generateUniqueWorkgroupId(List<Workgroup> workgroups) {
    final existingIds = workgroups.map((w) => w.id).toSet();
    int counter = 1;
    while (existingIds.contains(counter.toString())) {
      counter++;
    }
    return counter.toString();
  }

  List<HelvarRouter> _buildNewRoutersForExistingWorkgroup(
    Workgroup workgroup,
    List<Map<String, String>> discoveredRouters,
  ) {
    final existingRouterIps = workgroup.routers.map((r) => r.ipAddress).toSet();

    return discoveredRouters
        .where(
          (router) =>
              router['workgroup'] == workgroup.description &&
              !existingRouterIps.contains(router['ip']),
        )
        .map(
          (router) => HelvarRouter(
            ipAddress: router['ip'] ?? '',
            description: '${router['workgroup']} Router',
          ),
        )
        .toList();
  }

  List<HelvarRouter> _buildRoutersForNewWorkgroup(
    List<Map<String, String>> discoveredRouters,
    String workgroupName,
  ) {
    return discoveredRouters
        .where((router) => router['workgroup'] == workgroupName)
        .map((router) {
          final ipParts = router['ip']!.split('.');
          return HelvarRouter(
            address: '@${ipParts[2]}.${ipParts[3]}',
            ipAddress: router['ip'] ?? '',
            description: '${router['workgroup']} Router',
          );
        })
        .toList();
  }

  void _updateExistingWorkgroup(
    Workgroup existing,
    List<HelvarRouter> newRouters,
  ) {
    final updated = Workgroup(
      id: _generateUniqueWorkgroupId(ref.read(workgroupsProvider)),
      description: existing.description,
      networkInterface: existing.networkInterface,
      routers: [...existing.routers, ...newRouters],
    );

    ref.read(workgroupsProvider.notifier).updateWorkgroup(updated);

    if (mounted) {
      showSnackBarMsg(
        context,
        'Updated workgroup: ${existing.description} with ${newRouters.length} new routers',
      );
    }
  }

  void _createNewWorkgroup(
    String workgroupName,
    String networkInterfaceName,
    List<HelvarRouter> routers,
  ) {
    final workgroup = Workgroup(
      id: _generateUniqueWorkgroupId(ref.read(workgroupsProvider)),
      description: workgroupName,
      networkInterface: networkInterfaceName,
      routers: routers,
    );

    ref.read(workgroupsProvider.notifier).addWorkgroup(workgroup);
    if (mounted) {
      showSnackBarMsg(
        context,
        'Added workgroup: $workgroupName with ${routers.length} routers',
      );
    }
  }

  Future<void> _exportWorkgroups() async {
    try {
      final filePath = await FileDialogHelper.pickJsonFileToSave(
        'helvarnet_workgroups.json',
      );
      if (filePath != null) {
        await ref.read(workgroupsProvider.notifier).exportWorkgroups(filePath);
        if (mounted) {
          showSnackBarMsg(context, 'Workgroups exported to $filePath');
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBarMsg(context, 'Error exporting workgroups: $e');
      }
    }
  }

  Future<void> _importWorkgroups() async {
    try {
      final filePath = await FileDialogHelper.pickJsonFileToOpen();
      if (filePath != null) {
        if (mounted) {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Import Workgroups'),
              content: const Text(
                'Do you want to merge with existing workgroups or replace them?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Replace'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Merge'),
                ),
              ],
            ),
          );
          if (result != null) {
            await ref
                .read(workgroupsProvider.notifier)
                .importWorkgroups(filePath, merge: result);

            if (mounted) {
              showSnackBarMsg(
                context,
                'Workgroups ${result ? 'merged' : 'imported'} from $filePath',
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBarMsg(context, 'Error importing workgroups: $e');
      }
    }
  }

  Future<void> _confirmDeleteWorkgroup(Workgroup workgroup) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Workgroup'),
        content: Text(
          'Are you sure you want to delete the workgroup "${workgroup.description}"?'
          '\n\nThis will remove ${workgroup.routers.length} router(s) from the list.',
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
      ref.read(workgroupsProvider.notifier).removeWorkgroup(workgroup.id);
      if (mounted) {
        showSnackBarMsg(
          context,
          'Workgroup "${workgroup.description}" deleted',
        );
      }
    }
  }

  Future<void> _discoverMoreRouters(Workgroup workgroup) async {
    discoveryManager = DiscoveryManager();
    final interfaceResult = await selectNetworkInterface(context);
    if (interfaceResult == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final discoveredRouters = await _performRouterDiscovery(interfaceResult);
      final matchingRouters = discoveredRouters
          .where((router) => router['workgroup'] == workgroup.description)
          .toList();

      if (matchingRouters.isEmpty) {
        if (mounted) {
          showSnackBarMsg(
            context,
            'No matching routers found for this workgroup',
          );
        }
        return;
      }

      _createWorkgroup(
        workgroup.description,
        workgroup.networkInterface,
        matchingRouters,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, String>>> _performRouterDiscovery(
    NetworkInterfaceDetails interfaceResult,
  ) async {
    try {
      await discoveryManager!.start(interfaceResult.ipv4!);
      final discoveryTimeout = ref.read(discoveryTimeoutProvider);
      final broadcastAddress = calculateBroadcastAddress(
        interfaceResult.ipv4!,
        interfaceResult.subnetMask!,
      );
      await discoveryManager!.sendDiscoveryRequest(
        discoveryTimeout,
        broadcastAddress,
      );
      return discoveryManager!.getDiscoveredRouters();
    } catch (e) {
      if (mounted) {
        showSnackBarMsg(context, 'Discovery error: $e');
      }
      return [];
    } finally {
      if (discoveryManager != null) {
        discoveryManager!.stop();
        discoveryManager = null;
      }
    }
  }

  @override
  void dispose() {
    if (discoveryManager != null) {
      discoveryManager!.stop();
      discoveryManager = null;
    }
    super.dispose();
  }
}
