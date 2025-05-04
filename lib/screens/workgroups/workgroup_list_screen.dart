import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/screens/workgroups/workgroup_detail_screen.dart';

import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../comm/discovery_manager.dart';
import '../network_interface_dialog.dart';
import 'workgroup_selection_dialog.dart';
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

  Future<NetworkInterfaceDetails?> _selectNetworkInterface() async {
    try {
      List<NetworkInterfaceDetails> interfaces =
          await discoveryManager!.getNetworkInterfaces();

      if (interfaces.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No network interfaces found')),
          );
        }
        return null;
      }

      if (!mounted) return null;

      final result = await showDialog<NetworkInterfaceDetails>(
        context: context,
        builder: (BuildContext context) {
          return NetworkInterfaceDialog(interfaces: interfaces);
        },
      );

      if (result == null) {
        return null;
      }

      return result;
    } catch (e) {
      _showErrorMessage('Error finding network interfaces: ${e.toString()}');
      return null;
    }
  }

  Future<List<Map<String, String>>> _performRouterDiscovery(
      NetworkInterfaceDetails interfaceResult) async {
    setState(() {
      isDiscovering = true;
    });

    try {
      await discoveryManager!.start(interfaceResult.ipv4!);
      final discoveryTimeout = ref.read(discoveryTimeoutProvider);
      final broadcastAddress = discoveryManager!.calculateBroadcastAddress(
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

  Future<String?> _selectWorkgroup(List<String> workgroupNames) async {
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

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return WorkgroupSelectionDialog(workgroups: workgroupNames);
      },
    );
  }

  void _createWorkgroup(String workgroupName, String networkInterfaceName,
      List<Map<String, String>> discoveredRouters) {
    final existingWorkgroups = ref.read(workgroupsProvider);
    final existingWorkgroup = existingWorkgroups
        .where((wg) => wg.description == workgroupName)
        .toList();

    if (existingWorkgroup.isNotEmpty) {
      final workgroup = existingWorkgroup.first;
      final existingRouterIps =
          workgroup.routers.map((r) => r.ipAddress).toSet();

      List<HelvarRouter> newRouters = [];
      for (var routerInfo in discoveredRouters.where(
        (router) =>
            router['workgroup'] == workgroupName &&
            !existingRouterIps.contains(router['ip']),
      )) {
        newRouters.add(
          HelvarRouter(
            address: '1.${workgroup.routers.length + newRouters.length + 1}',
            ipAddress: routerInfo['ip'] ?? '',
            description: '${routerInfo['workgroup']} Router',
          ),
        );
      }

      if (newRouters.isNotEmpty) {
        final updatedWorkgroup = Workgroup(
          id: workgroup.id,
          description: workgroup.description,
          networkInterface: workgroup.networkInterface,
          routers: [...workgroup.routers, ...newRouters],
        );

        ref.read(workgroupsProvider.notifier).updateWorkgroup(updatedWorkgroup);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Updated workgroup: $workgroupName with ${newRouters.length} new routers',
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No new routers found for existing workgroup: $workgroupName',
              ),
            ),
          );
        }
      }

      return;
    }

    List<HelvarRouter> helvarRouters = [];

    for (var routerInfo in discoveredRouters.where(
      (router) => router['workgroup'] == workgroupName,
    )) {
      helvarRouters.add(
        HelvarRouter(
          address: '1.${helvarRouters.length + 1}',
          ipAddress: routerInfo['ip'] ?? '',
          description: '${routerInfo['workgroup']} Router',
        ),
      );
    }

    if (helvarRouters.isNotEmpty) {
      final workgroup = Workgroup(
        id: (existingWorkgroups.length + 1).toString(),
        description: workgroupName,
        networkInterface: networkInterfaceName,
        routers: helvarRouters,
      );

      ref.read(workgroupsProvider.notifier).addWorkgroup(workgroup);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added workgroup: $workgroupName with ${helvarRouters.length} routers',
            ),
          ),
        );
      }
    }
  }

  void _showErrorMessage(String message) {
    print('Error: $message');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _discoverWorkgroups() async {
    discoveryManager = DiscoveryManager();
    final interfaceResult = await _selectNetworkInterface();
    if (interfaceResult == null) return;

    List<Map<String, String>> discoveredRouters =
        await _performRouterDiscovery(interfaceResult);

    List<String> workgroupNames = discoveredRouters
        .map((router) => router['workgroup'] ?? 'Unknown')
        .toSet()
        .toList();

    final selectedWorkgroup = await _selectWorkgroup(workgroupNames);
    if (selectedWorkgroup == null) return;

    _createWorkgroup(
        selectedWorkgroup, interfaceResult.name, discoveredRouters);
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
              Padding(
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
            ],
          );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workgroup "${workgroup.description}" deleted'),
          ),
        );
      }
    }
  }

  Future<void> _discoverMoreRouters(Workgroup workgroup) async {
    discoveryManager = DiscoveryManager();
    final interfaceResult = await _selectNetworkInterface();
    if (interfaceResult == null) return;

    List<Map<String, String>> discoveredRouters =
        await _performRouterDiscovery(interfaceResult);

    final matchingRouters = discoveredRouters
        .where((router) => router['workgroup'] == workgroup.description)
        .toList();

    if (matchingRouters.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No matching routers found for this workgroup'),
          ),
        );
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
