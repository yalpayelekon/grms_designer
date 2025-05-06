import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:grms_designer/models/helvar_models/helvar_group.dart';
import '../comm/discovery_manager.dart';
import '../comm/models/router_connection_status.dart';
import '../models/helvar_models/helvar_router.dart';
import '../models/helvar_models/workgroup.dart';
import '../providers/project_settings_provider.dart';
import '../providers/router_connection_provider.dart';
import '../providers/settings_provider.dart';
import '../services/app_directory_service.dart';
import '../screens/dialogs/network_interface_dialog.dart';
import '../utils/general_ui.dart';
import 'actions.dart';
import 'dialogs/device_context_menu.dart';
import 'details/group_detail_screen.dart';
import 'dialogs/wiresheet_actions.dart';
import 'lists/groups_list_screen.dart';
import 'project_screens/settings_screen.dart';
import 'details/workgroup_detail_screen.dart';
import 'lists/workgroup_list_screen.dart';
import 'project_screens/wiresheet_screen.dart';
import '../models/widget_type.dart';
import '../providers/workgroups_provider.dart';
import '../providers/wiresheets_provider.dart';
import 'project_screens/project_settings_screen.dart';
import 'project_screens/project_files_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  bool openWorkGroup = false;
  bool openWiresheet = false;
  bool openSettings = false;
  bool showingImages = false;
  String? currentFileDirectory;
  String? selectedWiresheetId;
  Workgroup? selectedWorkgroup;
  HelvarGroup? selectedGroup;
  bool showingProject = true;
  bool showingGroups = false;
  bool showingGroupDetail = false;
  bool showingProjectSettings = false;
  double _leftPanelWidth = 400;
  bool _isDragging = false;
  List<RouterConnectionStatus>? connectionStatuses;
  Map<String, dynamic>? connectionStats;
  AsyncValue<RouterConnectionStatus>? connectionStream;

  @override
  Widget build(BuildContext context) {
    final workgroups = ref.watch(workgroupsProvider);
    final wiresheets = ref.watch(wiresheetsProvider);
    final projectName = ref.watch(projectNameProvider);
    connectionStream = ref.watch(routerConnectionStatusStreamProvider);
    connectionStatuses = ref.watch(routerConnectionStatusesProvider);
    connectionStats = ref.watch(connectionStatsProvider);

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 300,
        toolbarHeight: 100,
        leading: Image.asset("assets/logo.jpg"),
        title: Text('HelvarNet Manager - $projectName'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.note),
            tooltip: 'Application Director',
            onPressed: () {},
          ),
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
      body: Row(
        children: [
          SizedBox(
            width: _leftPanelWidth,
            height: MediaQuery.of(context).size.height - 56,
            child: Container(
              color: Colors.grey[400],
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TreeView(nodes: [
                      TreeNode(
                        content: GestureDetector(
                          onDoubleTap: () {
                            _setActiveNode('project');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "Project",
                              style: TextStyle(
                                fontWeight: showingProject
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: showingProject ? Colors.blue : null,
                              ),
                            ),
                          ),
                        ),
                        children: [
                          TreeNode(
                            content: GestureDetector(
                              onDoubleTap: () {
                                _setActiveNode('settings');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "Settings",
                                  style: TextStyle(
                                    fontWeight: openSettings
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: openSettings ? Colors.blue : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          TreeNode(
                            content: GestureDetector(
                              onDoubleTap: () {
                                _setActiveNode('files');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "Files",
                                  style: TextStyle(
                                    fontWeight: currentFileDirectory != null &&
                                            !showingImages
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: currentFileDirectory != null &&
                                            !showingImages
                                        ? Colors.blue
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                            children: [
                              TreeNode(
                                content: GestureDetector(
                                  onDoubleTap: () {
                                    _setActiveNode('images');
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      "Images",
                                      style: TextStyle(
                                        fontWeight: showingImages
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color:
                                            showingImages ? Colors.blue : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              TreeNode(
                                content: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onDoubleTap: () {
                                        _setActiveNode('wiresheets');
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          "Wiresheets",
                                          style: TextStyle(
                                            fontWeight: openWiresheet &&
                                                    selectedWiresheetId == null
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: openWiresheet &&
                                                    selectedWiresheetId == null
                                                ? Colors.blue
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 18),
                                      tooltip: 'Create New Wiresheet',
                                      onPressed: () =>
                                          createNewWiresheet(context, ref),
                                    ),
                                  ],
                                ),
                                children: [
                                  ...wiresheets.map((wiresheet) => TreeNode(
                                        content: GestureDetector(
                                          onDoubleTap: () {
                                            _setActiveNode('wiresheet',
                                                additionalData: wiresheet.id);
                                          },
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                  wiresheet.name,
                                                  style: TextStyle(
                                                    fontWeight:
                                                        selectedWiresheetId ==
                                                                wiresheet.id
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                    color:
                                                        selectedWiresheetId ==
                                                                wiresheet.id
                                                            ? Colors.blue
                                                            : null,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    size: 18),
                                                tooltip: 'Delete Wiresheet',
                                                onPressed: () async {
                                                  final result =
                                                      await confirmDeleteWiresheet(
                                                          context,
                                                          wiresheet.id,
                                                          wiresheet.name,
                                                          ref);
                                                  setState(() {
                                                    if (result) {
                                                      selectedWiresheetId =
                                                          null;
                                                    }
                                                  });
                                                  if (result && mounted) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                              'Wiresheet deleted')),
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      )),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      TreeNode(
                        content: GestureDetector(
                          onDoubleTap: () {
                            _setActiveNode('workgroups');
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.group_work),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'Workgroups',
                                  style: TextStyle(
                                    fontWeight: openWorkGroup &&
                                            selectedWorkgroup == null
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: openWorkGroup &&
                                            selectedWorkgroup == null
                                        ? Colors.blue
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        children: workgroups
                            .map(
                              (workgroup) => TreeNode(
                                content: GestureDetector(
                                  onDoubleTap: () {
                                    _setActiveNode('workgroups',
                                        additionalData: workgroup);
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(Icons.lan),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          workgroup.description,
                                          style: TextStyle(
                                            fontWeight: selectedWorkgroup ==
                                                        workgroup &&
                                                    !showingGroups &&
                                                    selectedGroup == null
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: selectedWorkgroup ==
                                                        workgroup &&
                                                    !showingGroups &&
                                                    selectedGroup == null
                                                ? Colors.blue
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                children: [
                                  TreeNode(
                                    content: GestureDetector(
                                      onDoubleTap: () {
                                        _setActiveNode(
                                          'groups',
                                          additionalData: workgroup,
                                        );
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(Icons.group_work,
                                              color: Colors.blue),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              "Groups",
                                              style: TextStyle(
                                                fontWeight: showingGroups &&
                                                        selectedWorkgroup ==
                                                            workgroup &&
                                                        selectedGroup == null
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: showingGroups &&
                                                        selectedWorkgroup ==
                                                            workgroup &&
                                                        selectedGroup == null
                                                    ? Colors.blue
                                                    : null,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    children: workgroup.groups
                                        .map(
                                          (group) => TreeNode(
                                            content: GestureDetector(
                                              onDoubleTap: () {
                                                _setActiveNode('groupDetail',
                                                    additionalData: {
                                                      'workgroup': workgroup,
                                                      'group': group,
                                                    });
                                              },
                                              onSecondaryTap: () {
                                                showGroupContextMenu(
                                                    context, group, workgroup);
                                              },
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.layers,
                                                      color: Colors.green),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      group.description.isEmpty
                                                          ? "Group ${group.groupId}"
                                                          : group.description,
                                                      style: TextStyle(
                                                        fontWeight: selectedWorkgroup ==
                                                                    workgroup &&
                                                                selectedGroup ==
                                                                    group
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                        color: selectedWorkgroup ==
                                                                    workgroup &&
                                                                selectedGroup ==
                                                                    group
                                                            ? Colors.blue
                                                            : null,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  ...workgroup.routers.map(
                                    (router) => TreeNode(
                                      content: GestureDetector(
                                        onDoubleTap: () {
                                          _setActiveNode('router',
                                              additionalData: {
                                                'workgroup': workgroup,
                                                'router': router,
                                              });
                                        },
                                        onSecondaryTap: () {
                                          _setActiveNode('router');
                                        },
                                        child: Row(
                                          children: [
                                            const Icon(Icons.router),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(router.description),
                                            ),
                                          ],
                                        ),
                                      ),
                                      children: [
                                        ...router.devicesBySubnet.entries
                                            .map((entry) {
                                          final subnet = entry.key;
                                          final subnetDevices = entry.value;
                                          return TreeNode(
                                            content: Row(
                                              children: [
                                                const Icon(Icons.hub),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Text("Subnet$subnet"),
                                                ),
                                              ],
                                            ),
                                            children: subnetDevices
                                                .map(
                                                  (device) => TreeNode(
                                                    content: GestureDetector(
                                                      onSecondaryTap: () =>
                                                          showDeviceContextMenu(
                                                              context, device),
                                                      child: _buildDraggable(
                                                        device.description
                                                                .isEmpty
                                                            ? "Device_${device.deviceId}"
                                                            : device
                                                                .description,
                                                        getDeviceIcon(device),
                                                        WidgetType.text,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          );
                                        }),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.resizeLeftRight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) {
                setState(() => _isDragging = true);
              },
              onPanUpdate: (details) {
                setState(() {
                  _leftPanelWidth += details.delta.dx;
                  _leftPanelWidth = _leftPanelWidth.clamp(
                      200, MediaQuery.of(context).size.width * 0.7);
                });
              },
              onPanEnd: (details) {
                setState(() => _isDragging = false);
              },
              child: Container(
                width: 8,
                color: _isDragging ? Colors.blue : Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (showingGroups) {
      return GroupsListScreen(
        workgroup: selectedWorkgroup!,
      );
    }
    if (showingGroupDetail) {
      return GroupDetailScreen(
        group: selectedGroup!,
        workgroup: selectedWorkgroup!,
      );
    }
    if (openSettings) {
      return const ProjectSettingsScreen();
    }
    if (openWorkGroup) {
      if (selectedWorkgroup == null) {
        return const WorkgroupListScreen();
      }
      return WorkgroupDetailScreen(workgroup: selectedWorkgroup!);
    }
    if (showingImages) {
      return const ProjectFilesScreen(
          directoryName: AppDirectoryService.imagesDir);
    }

    if (openWiresheet) {
      if (selectedWiresheetId == null) {
        return const Text("Wiresheet list will be added here");
      }
      return WiresheetScreen(
        wiresheetId: selectedWiresheetId!,
      );
    }

    return connectionStream!.when(
      data: (latestStatus) {
        return _buildConnectionMonitor();
      },
      loading: () => Center(
          child: Column(
        children: [
          const Text("Click on routers to start connection"),
          _buildConnectionMonitor(),
        ],
      )),
      error: (e, st) => Text('Error: $e'),
    );
  }

  Widget _buildConnectionMonitor() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Router Connections',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                    context, 'Total', connectionStats!['total'] ?? 0),
                _buildStatCard(context, 'Connected',
                    connectionStats!['connected'] ?? 0, Colors.green),
                _buildStatCard(context, 'Reconnecting',
                    connectionStats!['reconnecting'] ?? 0, Colors.orange),
                _buildStatCard(context, 'Failed',
                    connectionStats!['failed'] ?? 0, Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    _connectToExistingRouters(context);
                  },
                  child: const Text('Connect to Existing Routers'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    _discoverAndConnectRouters(context);
                  },
                  child: const Text('Discover New Routers'),
                ),
              ],
            ),
            if (connectionStatuses!.isEmpty)
              const Center(
                child: Text('No active router connections'),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: connectionStatuses!.length,
                  itemBuilder: (context, index) {
                    final status = connectionStatuses![index];
                    return _buildConnectionStatusItem(context, status);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _connectToExistingRouters(BuildContext context) async {
    final workgroups = ref.read(workgroupsProvider);

    final List<Map<String, dynamic>> routersInfo = [];
    for (final workgroup in workgroups) {
      for (final router in workgroup.routers) {
        routersInfo.add({
          'workgroup': workgroup.description,
          'router': router,
          'workgroupId': workgroup.id,
        });
      }
    }

    if (routersInfo.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No routers found in workgroups')),
        );
      }
      return;
    }

    if (mounted) {
      final selectedRouters = await showDialog<List<int>>(
        context: context,
        builder: (context) => _buildRouterSelectionDialog(routersInfo),
      );

      if (selectedRouters == null || selectedRouters.isEmpty) {
        return;
      }

      final connectionManager = ref.read(routerConnectionManagerProvider);
      final settings = ref.read(projectSettingsProvider);
      int connectedCount = 0;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting to routers...'),
            ],
          ),
        ),
      );

      // Connect to selected routers
      for (final index in selectedRouters) {
        try {
          final routerInfo = routersInfo[index];
          final router = routerInfo['router'] as HelvarRouter;

          if (router.ipAddress.isNotEmpty) {
            await connectionManager.getConnection(
              router.ipAddress,
              heartbeatInterval:
                  Duration(seconds: settings.heartbeatIntervalSeconds),
              connectionTimeout:
                  Duration(milliseconds: settings.socketTimeoutMs),
            );
            connectedCount++;
          }
        } catch (e) {
          debugPrint('Error connecting to router: $e');
        }
      }

      // Close progress dialog and show result
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected to $connectedCount routers')),
        );
      }
    }
  }

  Widget _buildRouterSelectionDialog(List<Map<String, dynamic>> routersInfo) {
    return StatefulBuilder(
      builder: (context, setState) {
        Set<int> selectedIndices = <int>{};

        return AlertDialog(
          title: const Text('Connect to Routers'),
          content: SizedBox(
            width: 400,
            height: 300,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: routersInfo.length,
                    itemBuilder: (context, index) {
                      final routerInfo = routersInfo[index];
                      final router = routerInfo['router'] as HelvarRouter;

                      return CheckboxListTile(
                        title: Text(router.description +
                            index.toString() +
                            selectedIndices.toString()),
                        subtitle: Text(
                            '${routerInfo['workgroup']} - ${router.ipAddress}'),
                        value: selectedIndices.contains(index),
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              selectedIndices.add(index);
                            } else {
                              selectedIndices.remove(index);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (selectedIndices.length == routersInfo.length) {
                            selectedIndices.clear();
                          } else {
                            selectedIndices.clear();
                            selectedIndices.addAll(
                                List.generate(routersInfo.length, (i) => i));
                          }
                        });
                      },
                      child: Text(
                        selectedIndices.length == routersInfo.length
                            ? 'Deselect All'
                            : 'Select All',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(selectedIndices.toList()),
              child: const Text('Connect'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _discoverAndConnectRouters(BuildContext context) async {
    DiscoveryManager? discoveryManager;

    try {
      discoveryManager = DiscoveryManager();
      List<NetworkInterfaceDetails> interfaces =
          await discoveryManager.getNetworkInterfaces();

      if (interfaces.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No network interfaces found')),
          );
        }
        return;
      }

      if (!mounted) return;

      final interfaceResult = await showDialog<NetworkInterfaceDetails>(
        context: context,
        builder: (BuildContext context) {
          return NetworkInterfaceDialog(interfaces: interfaces);
        },
      );

      if (interfaceResult == null) {
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Discovering routers...'),
            ],
          ),
        ),
      );

      await discoveryManager.start(interfaceResult.ipv4!);
      final discoveryTimeout = ref.read(discoveryTimeoutProvider);
      final broadcastAddress = discoveryManager.calculateBroadcastAddress(
        interfaceResult.ipv4!,
        interfaceResult.subnetMask!,
      );
      await discoveryManager.sendDiscoveryRequest(
          discoveryTimeout, broadcastAddress);
      List<Map<String, String>> discoveredRouters =
          discoveryManager.getDiscoveredRouters();

      if (mounted) {
        Navigator.of(context).pop();
      }

      if (discoveredRouters.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No Helvar routers discovered')),
          );
        }
        return;
      }

      if (mounted) {
        final shouldConnect = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Routers Discovered'),
            content: SizedBox(
              width: 300,
              height: 200,
              child: ListView.builder(
                itemCount: discoveredRouters.length,
                itemBuilder: (context, index) {
                  final router = discoveredRouters[index];
                  return ListTile(
                    title: Text(router['workgroup'] ?? 'Unknown'),
                    subtitle: Text(router['ip'] ?? 'No IP'),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Connect'),
              ),
            ],
          ),
        );

        if (shouldConnect == true) {
          final connectionManager = ref.read(routerConnectionManagerProvider);
          final settings = ref.read(projectSettingsProvider);
          int connectedCount = 0;

          for (final router in discoveredRouters) {
            try {
              final ipAddress = router['ip'];
              if (ipAddress != null && ipAddress.isNotEmpty) {
                await connectionManager.getConnection(
                  ipAddress,
                  heartbeatInterval:
                      Duration(seconds: settings.heartbeatIntervalSeconds),
                  connectionTimeout:
                      Duration(milliseconds: settings.socketTimeoutMs),
                );
                connectedCount++;
              }
            } catch (e) {
              debugPrint('Error connecting to router: $e');
            }
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Connected to $connectedCount routers')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Discovery error: $e');
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during discovery: $e')),
        );
      }
    } finally {
      if (discoveryManager != null) {
        discoveryManager.stop();
      }
    }
  }

  Widget _buildDraggable(String label, IconData icon, WidgetType type) {
    return Draggable<WidgetData>(
      data: WidgetData(type: type),
      feedback: Material(
        elevation: 4.0,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [Icon(icon), const SizedBox(width: 8.0), Text(label)],
          ),
        ),
      ),
      childWhenDragging: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 8.0),
          Text(label, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
      child: Row(
        children: [Icon(icon), const SizedBox(width: 8.0), Text(label)],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, int value,
      [Color? color]) {
    return Card(
      color: color?.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatusItem(
      BuildContext context, RouterConnectionStatus status) {
    IconData icon;
    Color color;

    switch (status.state) {
      case RouterConnectionState.connected:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case RouterConnectionState.connecting:
        icon = Icons.pending;
        color = Colors.blue;
        break;
      case RouterConnectionState.reconnecting:
        icon = Icons.sync;
        color = Colors.orange;
        break;
      case RouterConnectionState.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
      case RouterConnectionState.disconnected:
        icon = Icons.cancel;
        color = Colors.grey;
        break;
    }

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(status.routerIp),
      subtitle: Text(
        status.errorMessage != null
            ? 'Error: ${status.errorMessage}'
            : 'Last change: ${formatDateTime(status.lastStateChange)}',
      ),
      trailing: status.reconnectAttempts > 0
          ? Chip(label: Text('Retry: ${status.reconnectAttempts}'))
          : null,
    );
  }

  void _setActiveNode(String nodeName, {dynamic additionalData}) {
    setState(() {
      openWorkGroup = false;
      openWiresheet = false;
      openSettings = false;
      showingImages = false;
      showingProject = false;
      showingGroups = false;
      showingGroupDetail = false;
      showingProjectSettings = false;

      switch (nodeName) {
        case 'project':
          selectedGroup = null;
          selectedWiresheetId = null;
          selectedWorkgroup = null;
          currentFileDirectory = null;
          showingProject = true;
          break;
        case 'settings':
          selectedGroup = null;
          selectedWiresheetId = null;
          selectedWorkgroup = null;
          currentFileDirectory = null;
          openSettings = true;
          break;
        case 'workgroups':
          openWorkGroup = true;
          selectedGroup = null;
          selectedWiresheetId = null;
          currentFileDirectory = null;
          if (additionalData is Workgroup) {
            selectedWorkgroup = additionalData;
          } else {
            selectedWorkgroup = null;
          }
          break;
        case 'wiresheet':
          selectedGroup = null;
          selectedWiresheetId = null;
          selectedWorkgroup = null;
          currentFileDirectory = null;
          openWiresheet = true;
          if (additionalData is String) {
            selectedWiresheetId = additionalData;
          }
          break;
        case 'images':
          selectedGroup = null;
          selectedWiresheetId = null;
          selectedWorkgroup = null;
          currentFileDirectory = null;
          showingImages = true;
          currentFileDirectory = AppDirectoryService.imagesDir;
          break;
        case 'files':
          selectedGroup = null;
          selectedWiresheetId = null;
          selectedWorkgroup = null;
          currentFileDirectory = null;
          break;
        case 'wiresheets':
          openWiresheet = true;
          selectedGroup = null;
          selectedWiresheetId = null;
          selectedWorkgroup = null;
          currentFileDirectory = null;
          break;

        case 'groups':
          showingGroups = true;
          selectedGroup = null;
          selectedWiresheetId = null;
          currentFileDirectory = null;
          if (additionalData is Workgroup) {
            selectedWorkgroup = additionalData;
          }
          break;
        case 'groupDetail':
          selectedWiresheetId = null;
          currentFileDirectory = null;
          showingGroupDetail = true;
          if (additionalData is Map<String, dynamic>) {
            if (additionalData['workgroup'] is Workgroup) {
              selectedWorkgroup = additionalData['workgroup'];
            }
            if (additionalData['group'] is HelvarGroup) {
              selectedGroup = additionalData['group'];
            }
          }
          break;
        case 'projectSettings':
          selectedGroup = null;
          selectedWiresheetId = null;
          selectedWorkgroup = null;
          currentFileDirectory = null;
          showingProjectSettings = true;
          break;
        case 'router':
          if (additionalData is Map<String, dynamic>) {
            final workgroup = additionalData['workgroup'] as Workgroup;
            final router = additionalData['router'] as HelvarRouter;
            ref.read(workgroupsProvider.notifier).getRouterConnection(
                  workgroup.id,
                  router.address,
                );
          }
          break;
        default:
          showingProject = true;
      }
    });
  }
}
