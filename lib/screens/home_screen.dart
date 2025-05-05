import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:grms_designer/models/helvar_models/helvar_group.dart';
import '../models/helvar_models/helvar_device.dart';
import '../models/helvar_models/helvar_router.dart';
import '../models/helvar_models/workgroup.dart';
import '../providers/project_settings_provider.dart';
import '../services/app_directory_service.dart';
import 'actions.dart';
import 'dialogs/home_screen_dialogs.dart';
import 'details/group_detail_screen.dart';
import 'lists/groups_list_screen.dart';
import 'project_screens/settings_screen.dart';
import 'details/workgroup_detail_screen.dart';
import 'lists/workgroup_list_screen.dart';
import 'project_screens/wiresheet_screen.dart';
import '../models/widget_type.dart';
import '../providers/workgroups_provider.dart';
import '../providers/wiresheets_provider.dart';
import '../utils/file_dialog_helper.dart';
import 'project_screens/project_settings_screen.dart';
import 'project_screens/project_files_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  HelvarRouter? exampleRouter;
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

  @override
  Widget build(BuildContext context) {
    final workgroups = ref.watch(workgroupsProvider);
    final wiresheets = ref.watch(wiresheetsProvider);
    final projectName = ref.watch(projectNameProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('HelvarNet Manager - $projectName'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Export Workgroups',
            onPressed: () => _exportWorkgroups(context),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Import Workgroups',
            onPressed: () => _importWorkgroups(context),
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
                                          _createNewWiresheet(context),
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
                                                onPressed: () =>
                                                    _confirmDeleteWiresheet(
                                                  context,
                                                  wiresheet.id,
                                                  wiresheet.name,
                                                ),
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
                                      content: Row(
                                        children: [
                                          const Icon(Icons.router),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(router.description),
                                          ),
                                        ],
                                      ),
                                      children: [
                                        ...router.devicesBySubnet.entries
                                            .map((entry) {
                                          final subnet = entry.key;
                                          final subnetDevices = entry.value;
                                          exampleRouter = router;
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
                                                          _showDeviceContextMenu(
                                                              context, device),
                                                      child: _buildDraggable(
                                                        device.description
                                                                .isEmpty
                                                            ? "Device_${device.deviceId}"
                                                            : device
                                                                .description,
                                                        _getDeviceIcon(device),
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

  IconData _getDeviceIcon(HelvarDevice device) {
    if (device.isButtonDevice) {
      return Icons.touch_app;
    } else if (device.isMultisensor) {
      return Icons.sensors;
    } else if (device.helvarType == 'emergency') {
      return Icons.emergency;
    } else if (device.helvarType == 'output') {
      return Icons.lightbulb;
    } else {
      return Icons.device_unknown;
    }
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

    return const Text("Welcome to Helvarnet!");
  }

  Future<void> _exportWorkgroups(BuildContext context) async {
    try {
      final filePath = await FileDialogHelper.pickJsonFileToSave();
      if (filePath != null) {
        await ref.read(workgroupsProvider.notifier).exportWorkgroups(filePath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Workgroups exported to $filePath')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting workgroups: $e')),
        );
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Workgroups ${result ? 'merged' : 'imported'} from $filePath'),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing workgroups: $e')),
        );
      }
    }
  }

  void _createNewWiresheet(BuildContext context) {
    final nameController = TextEditingController(text: 'New Wiresheet');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Wiresheet'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Wiresheet Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final wiresheet = await ref
                    .read(wiresheetsProvider.notifier)
                    .createWiresheet(name);
                Navigator.of(context).pop();

                setState(() {
                  showingProject = false;
                  openWorkGroup = false;
                  openWiresheet = true;
                  selectedWiresheetId = wiresheet.id;
                });
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteWiresheet(
      BuildContext context, String wiresheetId, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Wiresheet'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref.read(wiresheetsProvider.notifier).deleteWiresheet(wiresheetId);
      if (selectedWiresheetId == wiresheetId) {
        setState(() {
          selectedWiresheetId = null;
          openWiresheet = false;
          showingProject = true;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wiresheet deleted')),
        );
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

  void _showDeviceContextMenu(BuildContext context, HelvarDevice device) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;

    final buttonBottomCenter = button.localToGlobal(
      Offset(300, button.size.height / 3),
      ancestor: overlay,
    );

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
          buttonBottomCenter, buttonBottomCenter + const Offset(1, 1)),
      Offset.zero & overlay.size,
    );

    final List<PopupMenuEntry<String>> menuItems = [];

    menuItems.add(
      const PopupMenuItem(
        value: 'clear_result',
        child: Text('Clear Result'),
      ),
    );

    if (device.helvarType == 'output') {
      menuItems.addAll([
        const PopupMenuItem(
          value: 'recall_scene',
          child: Text('Recall Scene'),
        ),
        const PopupMenuItem(
          value: 'direct_level',
          child: Text('Direct Level'),
        ),
        const PopupMenuItem(
          value: 'direct_proportion',
          child: Text('Direct Proportion'),
        ),
        const PopupMenuItem(
          value: 'modify_proportion',
          child: Text('Modify Proportion'),
        ),
      ]);
    }

    showMenu<String>(context: context, position: position, items: menuItems)
        .then((String? value) {
      if (value == null) return;

      switch (value) {
        case 'clear_result':
          _clearDeviceResult(context, device);
          break;
        case 'recall_scene':
          showDeviceRecallSceneDialog(context, device);
          break;
        case 'direct_level':
          showDeviceDirectLevelDialog(context, device);
          break;
        case 'direct_proportion':
          showDeviceDirectProportionDialog(context, device);
          break;
        case 'modify_proportion':
          showDeviceModifyProportionDialog(context, device);
          break;
      }
    });
  }

  void _clearDeviceResult(BuildContext context, HelvarDevice device) {
    device.clearResult();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cleared result for device ${device.deviceId}')),
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
        default:
          showingProject = true;
      }
    });
  }
}
