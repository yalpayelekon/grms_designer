import 'package:flutter/material.dart';
import 'dart:io';
import '../models/workgroup.dart';
import '../models/helvar_router.dart';
import '../comm/discovery_manager.dart';
import 'network_interface_dialog.dart';
import 'workgroup_selection_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  void _addWorkgroup() {
    // TODO: Implement workgroup addition logic
    print('Add Workgroup clicked');
  }

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
      // Step 1: Get available network interfaces
      List<NetworkInterface> interfaces =
          await DiscoveryManager.getNetworkInterfaces();

      if (interfaces.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No network interfaces found')),
        );
        return;
      }

      // Step 2: Show interface selection dialog
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (BuildContext context) {
          return NetworkInterfaceDialog(interfaces: interfaces);
        },
      );

      if (result == null || result['address'] == null) {
        return;
      }

      // Step 3: Calculate broadcast address for the selected interface
      NetworkInterface selectedInterface = result['interface'];
      String selectedAddress = result['address'];

      // Calculate broadcast address for the selected interface's subnet
      // For simplicity, using /24 subnet mask (255.255.255.0)
      String subnetMask = "255.255.255.0";
      String broadcastAddress =
          DiscoveryManager.getBroadcastAddress(selectedAddress, subnetMask);

      setState(() {
        isDiscovering = true;
      });

      // Step 4: Create discovery manager
      discoveryManager = DiscoveryManager(broadcastAddress);
      await discoveryManager!.start();

      // Step 5: Send discovery request
      await discoveryManager!.sendDiscoveryRequest(5000); // 5 second timeout

      // Step 6: Process discovery results
      List<Map<String, String>> discoveredRouters =
          discoveryManager!.getDiscoveredRouters();

      setState(() {
        isDiscovering = false;
      });

      if (discoveredRouters.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No Helvar routers discovered')),
        );
        return;
      }

      // Step 7: Extract workgroup names
      List<String> workgroupNames = discoveredRouters
          .map((router) => router['workgroup'] ?? 'Unknown')
          .toSet()
          .toList();

      // Step 8: Show workgroup selection dialog
      final selectedWorkgroup = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return WorkgroupSelectionDialog(workgroups: workgroupNames);
        },
      );

      if (selectedWorkgroup == null) {
        return;
      }

      // Step 9: Create workgroup with discovered routers
      List<HelvarRouter> helvarRouters = [];

      for (var routerInfo in discoveredRouters
          .where((router) => router['workgroup'] == selectedWorkgroup)) {
        helvarRouters.add(HelvarRouter(
          name: 'Router_${helvarRouters.length + 1}',
          address: '1.${helvarRouters.length + 1}',
          ipAddress: routerInfo['ip'] ?? '',
          description: '${routerInfo['workgroup']} Router',
        ));
      }

      if (helvarRouters.isNotEmpty) {
        setState(() {
          workgroups.add(Workgroup(
            id: (workgroups.length + 1).toString(),
            description: selectedWorkgroup,
            networkInterface: selectedInterface.name,
            routers: helvarRouters,
          ));
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Added workgroup: $selectedWorkgroup with '
                  '${helvarRouters.length} routers')),
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
      appBar: AppBar(
        title: const Text('HelvarNet Manager'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Discover Workgroups',
            onPressed: isDiscovering ? null : _discoverWorkgroups,
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
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                            leading: Icon(Icons.delete, color: Colors.red),
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
        onPressed: _addWorkgroup,
        tooltip: 'Add Workgroup',
        child: const Icon(Icons.add),
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
