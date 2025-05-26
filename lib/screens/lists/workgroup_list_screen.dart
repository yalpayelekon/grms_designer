import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/screens/details/workgroup_detail_screen.dart';
import 'package:grms_designer/utils/logger.dart';
import 'package:collection/collection.dart';
import 'package:grms_designer/utils/network_utils.dart';

import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../comm/discovery_manager.dart';
import '../../utils/file_dialog_helper.dart';
import '../../utils/general_ui.dart';
import '../dialogs/network_interface_dialog.dart';
import '../dialogs/workgroup_selection_dialog.dart';
import '../../providers/settings_provider.dart';
import '../../providers/workgroups_provider.dart';

class WorkgroupListScreen extends ConsumerStatefulWidget {
  const WorkgroupListScreen({super.key});

  @override
  WorkgroupListScreenState createState() => WorkgroupListScreenState();
}

class WorkgroupListScreenState extends ConsumerState<WorkgroupListScreen> {
  bool isDiscovering = false;
  DiscoveryManager? discoveryManager;

  void _navigateToWorkgroupDetail(Workgroup workgroup) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkgroupDetailScreen(workgroup: workgroup),
      ),
    );
  }

  Future<List<Map<String, String>>> _performRouterDiscovery(
      NetworkInterfaceDetails interfaceResult) async {
    setState(() {
      isDiscovering = true;
    });

    try {
      await discoveryManager!.start(interfaceResult.ipv4!);
      final discoveryTimeout = ref.read(discoveryTimeoutProvider);
      final broadcastAddress = calculateBroadcastAddress(
        interfaceResult.ipv4!,
        interfaceResult.subnetMask!,
      );
      await discoveryManager!
          .sendDiscoveryRequest(discoveryTimeout, broadcastAddress);
      return discoveryManager!.getDiscoveredRouters();
    } catch (e) {
      _showErrorMessage('Discovery error: ${e.toString()}');
      return [];
    } finally {
      if (discoveryManager != null) {
        discoveryManager!.stop();
        discoveryManager = null;
      }

      setState(() {
        isDiscovering = false;
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
            content:
                const Text('No Helvar routers were discovered on the network.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
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
        .where((router) =>
            router['workgroup'] == workgroup.description &&
            !existingRouterIps.contains(router['ip']))
        .map((router) => HelvarRouter(
              ipAddress: router['ip'] ?? '',
              description: '${router['workgroup']} Router',
            ))
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
    }).toList();
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
      showSnackBarMsg(context,
          'Updated workgroup: ${existing.description} with ${newRouters.length} new routers');
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
      logInfo('Added workgroup: $workgroupName with ${routers.length} routers');
    }
  }

  void _createWorkgroup(String workgroupName, String networkInterfaceName,
      List<Map<String, String>> discoveredRouters) {
    final existingWorkgroups = ref.read(workgroupsProvider);
    final existingWorkgroup = existingWorkgroups
        .firstWhereOrNull((wg) => wg.description == workgroupName);

    if (existingWorkgroup != null) {
      final newRouters = _buildNewRoutersForExistingWorkgroup(
          existingWorkgroup, discoveredRouters);

      if (newRouters.isNotEmpty) {
        _updateExistingWorkgroup(existingWorkgroup, newRouters);
      } else if (mounted) {
        showSnackBarMsg(context,
            'No new routers found for existing workgroup: $workgroupName');
      }

      return;
    }

    final newRouters =
        _buildRoutersForNewWorkgroup(discoveredRouters, workgroupName);

    if (newRouters.isNotEmpty) {
      _createNewWorkgroup(workgroupName, networkInterfaceName, newRouters);
    }
  }

  void _showErrorMessage(String message) {
    logError('Error: $message');
    if (mounted) {
      showSnackBarMsg(context, message);
    }
  }

  Future<void> _discoverWorkgroups() async {
    discoveryManager = DiscoveryManager();
    final interfaceResult = await selectNetworkInterface(context);
    if (interfaceResult == null) return;

    List<Map<String, String>> discoveredRouters =
        await _performRouterDiscovery(interfaceResult);

    List<String> workgroupNames = discoveredRouters
        .map((router) => router['workgroup'] ?? 'Unknown')
        .toSet()
        .toList();

    final selectedResult = await _selectWorkgroup(workgroupNames);
    if (selectedResult == null) return;

    if (selectedResult == '__ADD_ALL__') {
      for (String workgroupName in workgroupNames) {
        _createWorkgroup(
            workgroupName, interfaceResult.name, discoveredRouters);
      }

      if (mounted) {
        logInfo('Added all ${workgroupNames.length} workgroups');
      }
    } else {
      _createWorkgroup(selectedResult, interfaceResult.name, discoveredRouters);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workgroups = ref.watch(workgroupsProvider);

    return isDiscovering
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
        : Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.search),
                        label: const Text('Discover New Workgroup'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: isDiscovering ? null : _discoverWorkgroups,
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Export Workgroups'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: () => _exportWorkgroups(context),
                      ),
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Import Workgroups'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: () => _importWorkgroups(context),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: workgroups.length,
                  itemBuilder: (context, index) {
                    final workgroup = workgroups[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(
                              workgroup.description,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Network: ${workgroup.networkInterface}\n'
                              'Routers: ${workgroup.routers.length}',
                            ),
                            isThreeLine: true,
                            onTap: () => _navigateToWorkgroupDetail(workgroup),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  _confirmDeleteWorkgroup(workgroup),
                              tooltip: 'Remove workgroup',
                            ),
                          ),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.search),
                                  label: const Text('Discover More Routers'),
                                  onPressed: () =>
                                      _discoverMoreRouters(workgroup),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Edit'),
                                  onPressed: () =>
                                      _navigateToWorkgroupDetail(workgroup),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
  }

  Future<void> _exportWorkgroups(BuildContext context) async {
    try {
      final filePath = await FileDialogHelper.pickJsonFileToSave(
          'helvarnet_workgroups.json');
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

  Future<void> _importWorkgroups(BuildContext context) async {
    try {
      final filePath = await FileDialogHelper.pickJsonFileToOpen();
      if (filePath != null) {
        if (mounted) {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Import Workgroups'),
              content: const Text(
                  'Do you want to merge with existing workgroups or replace them?'),
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
            await ref.read(workgroupsProvider.notifier).importWorkgroups(
                  filePath,
                  merge: result,
                );

            if (mounted) {
              showSnackBarMsg(context,
                  'Workgroups ${result ? 'merged' : 'imported'} from $filePath');
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
            '\n\nThis will remove ${workgroup.routers.length} router(s) from the list.'),
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
      ref.read(workgroupsProvider.notifier).removeWorkgroup(workgroup.id);

      if (mounted) {
        showSnackBarMsg(
            context, 'Workgroup "${workgroup.description}" deleted');
      }
    }
  }

  Future<void> _discoverMoreRouters(Workgroup workgroup) async {
    discoveryManager = DiscoveryManager();
    final interfaceResult = await selectNetworkInterface(context);
    if (interfaceResult == null) return;

    List<Map<String, String>> discoveredRouters =
        await _performRouterDiscovery(interfaceResult);

    final matchingRouters = discoveredRouters
        .where((router) => router['workgroup'] == workgroup.description)
        .toList();

    if (matchingRouters.isEmpty) {
      if (mounted) {
        showSnackBarMsg(
            context, 'No matching routers found for this workgroup');
      }
      return;
    }

    _createWorkgroup(
        workgroup.description, workgroup.networkInterface, matchingRouters);
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
