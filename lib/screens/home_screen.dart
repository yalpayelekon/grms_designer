import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/providers/flowsheet_provider.dart';

import '../niagara/home/utils.dart';
import 'project_screens/flow_screen.dart';
import '../models/helvar_models/helvar_group.dart';
import '../comm/models/router_connection_status.dart';
import '../models/helvar_models/helvar_router.dart';
import '../models/helvar_models/workgroup.dart';
import '../providers/project_settings_provider.dart';
import '../providers/router_connection_provider.dart';
import '../services/app_directory_service.dart';
import '../utils/general_ui.dart';
import '../utils/logger.dart';
import '../widgets/app_tree_view.dart';
import 'details/group_detail_screen.dart';
import 'details/router_detail_screen.dart';
import 'dialogs/router_selection.dart';
import 'lists/groups_list_screen.dart';
import 'lists/flowsheet_list_screen.dart';
import 'log_panel_screen.dart';
import 'project_screens/settings_screen.dart';
import 'details/workgroup_detail_screen.dart';
import 'lists/workgroup_list_screen.dart';
import '../providers/workgroups_provider.dart';
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
  HelvarRouter? selectedRouter;
  bool showingProject = true;
  bool showingGroups = false;
  bool showingGroupDetail = false;
  bool showingRouterDetail = false;
  bool showingProjectSettings = false;
  double _leftPanelWidth = 500;
  bool _isDragging = false;
  List<RouterConnectionStatus>? connectionStatuses;
  Map<String, dynamic>? connectionStats;
  AsyncValue<RouterConnectionStatus>? connectionStream;
  Set<int> selectedIndices = <int>{};

  @override
  Widget build(BuildContext context) {
    final workgroups = ref.watch(workgroupsProvider);
    final wiresheets = ref.watch(flowsheetsProvider);
    final projectName = ref.watch(projectNameProvider);
    connectionStream = ref.watch(routerConnectionStatusStreamProvider);

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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LogPanelScreen(),
                ),
              );
            },
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
              child: AppTreeView(
                wiresheets: wiresheets,
                workgroups: workgroups,
                showingProject: showingProject,
                openSettings: openSettings,
                openWorkGroup: openWorkGroup,
                openWiresheet: openWiresheet,
                showingImages: showingImages,
                showingGroups: showingGroups,
                currentFileDirectory: currentFileDirectory,
                selectedWiresheetId: selectedWiresheetId,
                selectedWorkgroup: selectedWorkgroup,
                selectedGroup: selectedGroup,
                selectedRouter: selectedRouter,
                setActiveNode: _setActiveNode,
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
    if (showingRouterDetail &&
        selectedRouter != null &&
        selectedWorkgroup != null) {
      return RouterDetailScreen(
        workgroup: selectedWorkgroup!,
        router: selectedRouter!,
      );
    }
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
        return const FlowsheetListScreen();
      }
      return FlowScreen(
        flowsheetId: selectedWiresheetId!,
      );
    }

    if (showingProject) {
      return _buildConnectionMonitor();
    }

    return const FlowsheetListScreen();
  }

  Widget _buildConnectionMonitor() {
    if (connectionStats == null) return const SizedBox.shrink();
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
            ElevatedButton(
              onPressed: () {
                _connectToExistingRouters(context);
              },
              child: const Text('Connect to Routers'),
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
        showSnackBarMsg(context, 'No routers found in workgroups');
      }
      return;
    }

    if (mounted) {
      final selectedRouters = await showDialog<List<int>>(
        context: context,
        builder: (context) =>
            buildRouterSelectionDialog(routersInfo, selectedIndices),
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

      for (final index in selectedRouters) {
        try {
          final routerInfo = routersInfo[index];
          final router = routerInfo['router'] as HelvarRouter;

          if (router.ipAddress.isNotEmpty) {
            await connectionManager.getConnection(
              router.ipAddress,
            );
            connectedCount++;
          }
        } catch (e) {
          logError('Error connecting to router: $e');
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        showSnackBarMsg(context, 'Connected to $connectedCount routers');
      }
    }
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
          setState(() {
            openWorkGroup = false;
            openWiresheet = false;
            openSettings = false;
            showingImages = false;
            showingProject = false;
            showingGroups = false;
            showingGroupDetail = false;
            showingProjectSettings = false;
            showingRouterDetail = true;

            if (additionalData is Map<String, dynamic>) {
              if (additionalData['workgroup'] is Workgroup) {
                selectedWorkgroup = additionalData['workgroup'];
              }
              if (additionalData['router'] is HelvarRouter) {
                selectedRouter = additionalData['router'];
              }
            }
          });
          break;
        default:
          showingProject = true;
      }
    });
  }
}
