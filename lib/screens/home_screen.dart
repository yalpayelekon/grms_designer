import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/helvar_models/helvar_group.dart';
import '../models/helvar_models/helvar_router.dart';
import '../models/helvar_models/workgroup.dart';
import '../providers/project_settings_provider.dart';
import '../services/app_directory_service.dart';
import '../widgets/app_tree_view.dart';
import 'details/group_detail_screen.dart';
import 'details/router_detail_screen.dart';
import 'lists/groups_list_screen.dart';
import 'lists/wiresheet_list_screen.dart';
import 'log_panel_screen.dart';
import 'project_screens/settings_screen.dart';
import 'details/workgroup_detail_screen.dart';
import 'lists/workgroup_list_screen.dart';
import 'project_screens/wiresheet_screen.dart';
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
  double _leftPanelWidth = 500;
  bool _isDragging = false;
  Map<String, dynamic>? connectionStats;
  Set<int> selectedIndices = <int>{};

  @override
  Widget build(BuildContext context) {
    final workgroups = ref.watch(workgroupsProvider);
    final wiresheets = ref.watch(wiresheetsProvider);
    final projectName = ref.watch(projectNameProvider);

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
        return const WiresheetListScreen();
      }
      return WiresheetScreen(
        wiresheetId: selectedWiresheetId!,
      );
    }

    return _buildConnectionMonitor();
  }

  Widget _buildConnectionMonitor() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Router Connections will be added later',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
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
          final workgroup = additionalData['workgroup'] as Workgroup;
          final router = additionalData['router'] as HelvarRouter;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RouterDetailScreen(
                workgroup: workgroup,
                router: router,
              ),
            ),
          );
          break;
        default:
          showingProject = true;
      }
    });
  }
}
