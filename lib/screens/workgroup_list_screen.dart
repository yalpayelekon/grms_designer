import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/screens/workgroup_detail_screen.dart';

import '../models/workgroup.dart';
import '../models/helvar_router.dart';
import '../comm/discovery_manager.dart';
import 'network_interface_dialog.dart';
import 'workgroup_selection_dialog.dart';
import '../providers/settings_provider.dart';
import '../providers/workgroups_provider.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No network interfaces found')),
        );
        return null;
      }

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

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return WorkgroupSelectionDialog(workgroups: workgroupNames);
      },
    );
  }

  void _createWorkgroup(String workgroupName, String networkInterfaceName,
      List<Map<String, String>> discoveredRouters) {
    List<HelvarRouter> helvarRouters = [];

    for (var routerInfo in discoveredRouters.where(
      (router) => router['workgroup'] == workgroupName,
    )) {
      helvarRouters.add(
        HelvarRouter(
          name: 'Router_${helvarRouters.length + 1}',
          address: '1.${helvarRouters.length + 1}',
          ipAddress: routerInfo['ip'] ?? '',
          description: '${routerInfo['workgroup']} Router',
        ),
      );
    }

    if (helvarRouters.isNotEmpty) {
      final workgroup = Workgroup(
        id: (ref.read(workgroupsProvider).length + 1).toString(),
        description: workgroupName,
        networkInterface: networkInterfaceName,
        routers: helvarRouters,
      );

      // Add workgroup to the provider instead of local state
      ref.read(workgroupsProvider.notifier).addWorkgroup(workgroup);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added workgroup: $workgroupName with ${helvarRouters.length} routers',
          ),
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    print('Error: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
    // Access workgroups from the provider
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
        : ListView.builder(
            itemCount: workgroups.length + 1,
            itemBuilder: (context, index) {
              if (index == workgroups.length) {
                return ElevatedButton(
                    onPressed: isDiscovering ? null : _discoverWorkgroups,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search),
                        Text('Discover Workgroup')
                      ],
                    ));
              }
              final workgroup = workgroups[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ListTile(
                  title: Text(
                    workgroup.description,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Network: ${workgroup.networkInterface}\n'
                    'Routers: ${workgroup.routers.length}',
                  ),
                  isThreeLine: true,
                  onTap: () => _navigateToWorkgroupDetail(workgroup),
                ),
              );
            },
          );
  }

  @override
  void dispose() {
    if (discoveryManager != null) {
      discoveryManager!.stop();
    }
    super.dispose();
  }
}
