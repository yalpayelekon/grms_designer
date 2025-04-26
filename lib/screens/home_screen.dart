import 'package:flutter/material.dart';
import 'dart:io';
import '../models/workgroup.dart';
import '../models/helvar_router.dart';
import '../comm/discovery_manager.dart';
import 'network_interface_dialog.dart';
import 'workgroup_selection_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  List<Workgroup> workgroups = [
    Workgroup(
      id: '1',
      description: 'Main Office Network',
      networkInterface: 'eth0',
    ),
    Workgroup(
      id: '2',
      description: 'Warehouse Lighting',
      networkInterface: 'eth1',
    ),
  ];

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
    // TODO: Implement navigation to workgroup detail page
    print('Navigate to Workgroup: ${workgroup.description}');
  }

  Future<void> _discoverWorkgroups() async {
    try {
      List<NetworkInterface> interfaces =
          await DiscoveryManager.getNetworkInterfaces();

      if (interfaces.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No network interfaces found')),
        );
        return;
      }

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (BuildContext context) {
          return NetworkInterfaceDialog(interfaces: interfaces);
        },
      );

      if (result == null || result['address'] == null) {
        return;
      }

      NetworkInterface selectedInterface = result['interface'];
      String selectedAddress = result['address'];

      String subnetMask = "255.255.255.0";
      String broadcastAddress = DiscoveryManager.getBroadcastAddress(
        selectedAddress,
        subnetMask,
      );

      setState(() {
        isDiscovering = true;
      });

      discoveryManager = DiscoveryManager(broadcastAddress);
      await discoveryManager!.start();

      await discoveryManager!.sendDiscoveryRequest(5000); // 5 second timeout

      List<Map<String, String>> discoveredRouters =
          discoveryManager!.getDiscoveredRouters();

      setState(() {
        isDiscovering = false;
      });

      if (discoveredRouters.isEmpty) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Discovery Result'),
              content: const Text(
                'No Helvar routers were discovered on the network.',
              ),
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
        return;
      }

      List<String> workgroupNames =
          discoveredRouters
              .map((router) => router['workgroup'] ?? 'Unknown')
              .toSet()
              .toList();

      final selectedWorkgroup = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return WorkgroupSelectionDialog(workgroups: workgroupNames);
        },
      );

      if (selectedWorkgroup == null) {
        return;
      }

      List<HelvarRouter> helvarRouters = [];

      for (var routerInfo in discoveredRouters.where(
        (router) => router['workgroup'] == selectedWorkgroup,
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
              description: selectedWorkgroup,
              networkInterface: selectedInterface.name,
              routers: helvarRouters,
            ),
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added workgroup: $selectedWorkgroup with '
              '${helvarRouters.length} routers',
            ),
          ),
        );
      }
    } catch (e) {
      print('Error during discovery: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Discovery error: ${e.toString()}')),
      );
    } finally {
      // Cleanup
      if (discoveryManager != null) {
        discoveryManager!.stop();
        discoveryManager = null;
      }

      setState(() {
        isDiscovering = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HelvarNet Manager'), centerTitle: true),
      body:
          isDiscovering
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
                        itemBuilder:
                            (BuildContext context) => <PopupMenuEntry<String>>[
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
      // Changed floating action button to perform discovery instead of add workgroup
      floatingActionButton: FloatingActionButton(
        onPressed: isDiscovering ? null : _discoverWorkgroups,
        tooltip: 'Discover Workgroup',
        backgroundColor: isDiscovering ? Colors.grey : null,
        child:
            isDiscovering
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
