import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/models/helvar_models/helvar_device.dart';
import 'package:grms_designer/models/helvar_models/input_device.dart';
import 'package:grms_designer/models/helvar_models/output_point.dart';
import 'package:grms_designer/providers/flowsheet_provider.dart';
import 'package:grms_designer/screens/details/device_detail_screen.dart';
import 'package:grms_designer/utils/date_utils.dart';

import '../comm/models/command_models.dart';
import '../comm/router_command_service.dart';
import 'project_screens/flow_screen.dart';
import '../models/helvar_models/helvar_group.dart';
import '../comm/models/router_connection_status.dart';
import '../models/helvar_models/helvar_router.dart';
import '../models/helvar_models/workgroup.dart';
import '../providers/project_settings_provider.dart';
import '../providers/router_connection_provider.dart';
import '../services/app_directory_service.dart';
import '../utils/general_ui.dart';
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
import '../screens/details/subnet_detail_screen.dart';
import '../screens/details/points_detail_screen.dart';
import '../screens/details/point_detail_screen.dart';
import '../screens/details/output_points_detail_screen.dart';
import '../models/helvar_models/output_device.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  bool openWorkGroups = false;
  bool openWiresheet = false;
  bool openSettings = false;
  bool showingImages = false;
  String? currentFileDirectory;
  String? selectedWiresheetId;
  Workgroup? selectedWorkgroup;
  HelvarGroup? selectedGroup;
  HelvarRouter? selectedRouter;
  bool showingProject = true;
  bool showingWorkgroup = false;
  bool showingGroups = false;
  bool showingProjectSettings = false;
  bool showingSubnetDetail = false;
  int? selectedSubnetNumber;
  bool showingDeviceDetail = false;
  HelvarDevice? selectedDevice;
  bool showingOutputPointsDetail = false;
  OutputPoint? selectedOutputPoint;
  List<HelvarDevice>? selectedSubnetDevices;
  bool showingPointsDetail = false;
  bool showingPointDetail = false;
  ButtonPoint? selectedPoint;
  double _leftPanelWidth = 500;
  bool _isDragging = false;
  AsyncValue<RouterConnectionStatus>? connectionStream;
  Set<int> selectedIndices = <int>{};
  final Map<String, List<QueuedCommand>> _liveQueues = {};

  @override
  Widget build(BuildContext context) {
    final workgroups = ref.watch(workgroupsProvider);
    final wiresheets = ref.watch(flowsheetsProvider);
    final projectName = ref.watch(projectNameProvider);
    connectionStream = ref.watch(routerConnectionStatusStreamProvider);
    ref.listen<AsyncValue<QueuedCommand>>(commandStatusStreamProvider, (
      previous,
      next,
    ) {
      next.whenData((command) {
        final list = _liveQueues.putIfAbsent(command.routerIp, () => []);

        final index = list.indexWhere((c) => c.id == command.id);
        if (index != -1) {
          list[index] = command;
        } else {
          list.add(command);
        }
      });
    });

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
                MaterialPageRoute(builder: (context) => const LogPanelScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
                selectedSubnetNumber: selectedSubnetNumber,
                showingSubnetDetail: showingSubnetDetail,
                showingOutputPointsDetail: showingOutputPointsDetail,
                showingDeviceDetail: showingDeviceDetail,
                showingPointsDetail: showingPointsDetail,
                selectedDevice: selectedDevice,
                wiresheets: wiresheets,
                workgroups: workgroups,
                showingProject: showingProject,
                openSettings: openSettings,
                openWorkGroups: openWorkGroups,
                showingWorkgroup: showingWorkgroup,
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
                    200,
                    MediaQuery.of(context).size.width * 0.7,
                  );
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
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (showingProject) {
      return _buildConnectionMonitor();
    }
    if (openSettings) {
      return const ProjectSettingsScreen();
    }
    if (openWorkGroups) {
      return const WorkgroupListScreen();
    }
    if (showingGroups) {
      return GroupsListScreen(workgroup: selectedWorkgroup!);
    }
    if (showingImages) {
      return const ProjectFilesScreen(
        directoryName: AppDirectoryService.imagesDir,
      );
    }
    if (openWiresheet) {
      return const FlowsheetListScreen();
    }
    if (selectedWiresheetId != null) {
      return FlowScreen(flowsheetId: selectedWiresheetId!);
    }
    if (selectedWorkgroup != null) {
      if (showingDeviceDetail &&
          selectedRouter != null &&
          selectedDevice != null) {
        return DeviceDetailScreen(
          workgroup: selectedWorkgroup!,
          router: selectedRouter!,
          device: selectedDevice!,
        );
      }
      if (showingPointDetail &&
          selectedRouter != null &&
          selectedDevice != null &&
          selectedPoint != null) {
        return PointDetailScreen(
          workgroup: selectedWorkgroup!,
          router: selectedRouter!,
          device: selectedDevice!,
          point: selectedPoint!,
        );
      }
      if (showingPointsDetail &&
          selectedRouter != null &&
          selectedDevice != null) {
        return PointsDetailScreen(
          workgroup: selectedWorkgroup!,
          router: selectedRouter!,
          device: selectedDevice!,
          onNavigate: _setActiveNode,
        );
      }
      if (showingOutputPointsDetail &&
          selectedRouter != null &&
          selectedDevice != null &&
          selectedDevice is HelvarDriverOutputDevice) {
        return OutputPointsDetailScreen(
          workgroup: selectedWorkgroup!,
          router: selectedRouter!,
          device: selectedDevice!,
          onNavigate: _setActiveNode,
        );
      }
      if (showingSubnetDetail &&
          selectedRouter != null &&
          selectedSubnetNumber != null &&
          selectedSubnetDevices != null) {
        return SubnetDetailScreen(
          workgroup: selectedWorkgroup!,
          router: selectedRouter!,
          subnetNumber: selectedSubnetNumber!,
          devices: selectedSubnetDevices!,
          onNavigate: _setActiveNode,
        );
      }
      if (selectedGroup != null) {
        return GroupDetailScreen(
          group: selectedGroup!,
          workgroup: selectedWorkgroup!,
        );
      }
      if (selectedRouter != null) {
        return RouterDetailScreen(
          workgroup: selectedWorkgroup!,
          router: selectedRouter!,
        );
      }
      return WorkgroupDetailScreen(workgroup: selectedWorkgroup!);
    }

    return const FlowsheetListScreen();
  }

  Widget _buildConnectionMonitor() {
    final connectionManager = ref.watch(routerConnectionManagerProvider);
    final stats = connectionManager.getConnectionStats();
    final connections = connectionManager.connections;
    final statuses = connections.values.map((c) => c.status).toList();

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
                _buildStatCard(context, 'Total', stats['total']),
                _buildStatCard(
                  context,
                  'Connected',
                  stats['connected'],
                  Colors.green,
                ),
                _buildStatCard(
                  context,
                  'Connecting',
                  stats['connecting'],
                  Colors.blue,
                ),
                _buildStatCard(
                  context,
                  'Reconnecting',
                  stats['reconnecting'],
                  Colors.orange,
                ),
                _buildStatCard(context, 'Failed', stats['failed'], Colors.red),
                _buildStatCard(
                  context,
                  'Disconnected',
                  stats['disconnected'],
                  Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _connectToExistingRouters(context),
              child: const Text('Connect to Routers'),
            ),
            statuses.isEmpty
                ? const Center(child: Text('No active router connections'))
                : Expanded(
                    child: ListView.builder(
                      itemCount: statuses.length,
                      itemBuilder: (context, index) {
                        return _buildConnectionStatusItem(
                          context,
                          statuses[index],
                        );
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

      final connectionService = ref.read(connectionServiceProvider);

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

      final routersToConnect = selectedRouters
          .map((i) => routersInfo[i]['router'] as HelvarRouter)
          .toList();
      final result = await connectionService.connectToRouters(routersToConnect);

      if (mounted) {
        Navigator.of(context).pop();
        showSnackBarMsg(
          context,
          'Connected to ${result.successCount} routers (${result.failureCount} failed)',
        );
      }
    }
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    int value, [
    Color? color,
  ]) {
    return Card(
      color: color?.withValues(alpha: 0.1 * 255),
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
    BuildContext context,
    RouterConnectionStatus status,
  ) {
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

    final commands = _liveQueues[status.routerIp] ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
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
            ),
            if (commands.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: commands
                      .map(
                        (cmd) => Text(
                          '• [${cmd.status.name}] ${cmd.command}',
                          style: TextStyle(
                            fontSize: 12,
                            color: getStatusColor(cmd.status),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _setActiveNode(
    String nodeName, {
    Workgroup? workgroup,
    HelvarGroup? group,
    HelvarRouter? router,
    String? wiresheetId,
    int? subnetNumber,
    List<HelvarDevice>? subnetDevices,
    HelvarDevice? device,
    ButtonPoint? point,
    OutputPoint? outputPoint,
  }) {
    setState(() {
      showingPointsDetail = false;
      showingPointDetail = false;
      showingOutputPointsDetail = false;
      selectedPoint = null;
      selectedOutputPoint = null;
      openWorkGroups = false;
      openWiresheet = false;
      openSettings = false;
      showingImages = false;
      showingProject = false;
      showingGroups = false;
      showingProjectSettings = false;
      showingSubnetDetail = false;
      showingDeviceDetail = false;
      selectedRouter = null;
      selectedGroup = null;
      selectedWiresheetId = null;
      selectedWorkgroup = null;
      selectedSubnetNumber = null;
      selectedSubnetDevices = null;
      selectedDevice = null;
      currentFileDirectory = null;
      showingWorkgroup = false;

      switch (nodeName) {
        case 'project':
          showingProject = true;
          break;
        case 'settings':
          openSettings = true;
          break;
        case 'workgroups':
          openWorkGroups = true;
          break;
        case 'workgroupDetail':
          showingWorkgroup = true;
          selectedWorkgroup = workgroup;
          break;
        case 'wiresheet':
          selectedWiresheetId = wiresheetId;
          break;
        case 'images':
          currentFileDirectory = AppDirectoryService.imagesDir;
          break;
        case 'files':
          currentFileDirectory = null;
          break;
        case 'wiresheets':
          openWiresheet = true;
          break;
        case 'groups':
          showingGroups = true;
          selectedWorkgroup = workgroup;
          break;
        case 'groupDetail':
          selectedWorkgroup = workgroup;
          selectedGroup = group;
          break;
        case 'projectSettings':
          showingProjectSettings = true;
          break;
        case 'router':
          selectedWorkgroup = workgroup;
          selectedRouter = router;
          break;
        case 'subnetDetail':
          showingSubnetDetail = true;
          selectedWorkgroup = workgroup;
          selectedRouter = router;
          selectedSubnetNumber = subnetNumber;
          selectedSubnetDevices = subnetDevices;
          break;
        case 'deviceDetail':
          showingDeviceDetail = true;
          selectedWorkgroup = workgroup;
          selectedRouter = router;
          selectedDevice = device;
          break;
        case 'pointsDetail':
          showingPointsDetail = true;
          selectedWorkgroup = workgroup;
          selectedRouter = router;
          selectedDevice = device;
          break;
        case 'pointDetail':
          showingPointDetail = true;
          selectedWorkgroup = workgroup;
          selectedRouter = router;
          selectedDevice = device;
          selectedPoint = point;
          break;
        case 'outputPointsDetail':
          showingOutputPointsDetail = true;
          selectedWorkgroup = workgroup;
          selectedRouter = router;
          selectedDevice = device;
          break;
        case 'outputPointDetail':
          showingOutputPointsDetail = true;
          selectedWorkgroup = workgroup;
          selectedRouter = router;
          selectedDevice = device;
          selectedOutputPoint = outputPoint;
          break;
        default:
          showingProject = true;
      }
    });
  }
}
