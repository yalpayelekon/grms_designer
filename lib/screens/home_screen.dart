import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/screens/workgroup_detail_screen.dart';

import '../models/workgroup.dart';
import '../models/helvar_router.dart';
import '../comm/discovery_manager.dart';
import 'network_interface_dialog.dart';
import 'workgroup_selection_dialog.dart';
import 'settings_screen.dart';
import '../providers/settings_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  List<Workgroup> workgroups = [];

  bool isDiscovering = false;
  DiscoveryManager? discoveryManager;

  void _editWorkgroup(Workgroup workgroup) {
    // TODO: Implement workgroup editing logic
    print('Edit Workgroup: ${workgroup.description}');
  }

  void _deleteWorkgroup(Workgroup workgroup) {
    setState(() {
      workgroups.remove(workgroup);
    });
  }

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
      setState(() {
        workgroups.add(
          Workgroup(
            id: (workgroups.length + 1).toString(),
            description: workgroupName,
            networkInterface: networkInterfaceName,
            routers: helvarRouters,
          ),
        );
      });

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('HelvarNet Manager'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: isDiscovering
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
              itemCount: workgroups.length,
              itemBuilder: (context, index) {
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
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _editWorkgroup(workgroup);
                            break;
                          case 'delete':
                            _deleteWorkgroup(workgroup);
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Edit'),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            title: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _navigateToWorkgroupDetail(workgroup),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: isDiscovering ? null : _discoverWorkgroups,
        tooltip: 'Discover Workgroup',
        backgroundColor: isDiscovering ? Colors.grey : null,
        child: isDiscovering
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.search),
      ),
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
