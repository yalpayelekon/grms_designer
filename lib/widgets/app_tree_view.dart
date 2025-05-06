// lib/widgets/app_tree_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';

import '../models/helvar_models/helvar_group.dart';
import '../models/helvar_models/workgroup.dart';
import '../models/widget_type.dart';
import '../models/wiresheet.dart';
import '../screens/actions.dart';
import '../screens/dialogs/device_context_menu.dart';
import '../screens/dialogs/wiresheet_actions.dart';
import '../utils/general_ui.dart';

class AppTreeView extends ConsumerWidget {
  final List<Wiresheet> wiresheets;
  final List<Workgroup> workgroups;
  final bool showingProject;
  final bool openSettings;
  final bool openWorkGroup;
  final bool openWiresheet;
  final bool showingImages;
  final bool showingGroups;
  final String? currentFileDirectory;
  final String? selectedWiresheetId;
  final Workgroup? selectedWorkgroup;
  final HelvarGroup? selectedGroup;
  final Function(String, {dynamic additionalData}) setActiveNode;

  const AppTreeView({
    super.key,
    required this.wiresheets,
    required this.workgroups,
    required this.showingProject,
    required this.openSettings,
    required this.openWorkGroup,
    required this.openWiresheet,
    required this.showingImages,
    required this.showingGroups,
    required this.currentFileDirectory,
    required this.selectedWiresheetId,
    required this.selectedWorkgroup,
    required this.selectedGroup,
    required this.setActiveNode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        children: [
          TreeView(nodes: [
            TreeNode(
              content: GestureDetector(
                onDoubleTap: () {
                  setActiveNode('project');
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Project",
                    style: TextStyle(
                      fontWeight:
                          showingProject ? FontWeight.bold : FontWeight.normal,
                      color: showingProject ? Colors.blue : null,
                    ),
                  ),
                ),
              ),
              children: [
                TreeNode(
                  content: GestureDetector(
                    onDoubleTap: () {
                      setActiveNode('settings');
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
                      setActiveNode('files');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Files",
                        style: TextStyle(
                          fontWeight:
                              currentFileDirectory != null && !showingImages
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                          color: currentFileDirectory != null && !showingImages
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
                          setActiveNode('images');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Images",
                            style: TextStyle(
                              fontWeight: showingImages
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: showingImages ? Colors.blue : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    TreeNode(
                      content: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onDoubleTap: () {
                              setActiveNode('wiresheets');
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
                            onPressed: () => createNewWiresheet(context, ref),
                          ),
                        ],
                      ),
                      children: [
                        ...wiresheets.map((wiresheet) => TreeNode(
                              content: GestureDetector(
                                onDoubleTap: () {
                                  setActiveNode('wiresheet',
                                      additionalData: wiresheet.id);
                                },
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        wiresheet.name,
                                        style: TextStyle(
                                          fontWeight: selectedWiresheetId ==
                                                  wiresheet.id
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: selectedWiresheetId ==
                                                  wiresheet.id
                                              ? Colors.blue
                                              : null,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 18),
                                      tooltip: 'Delete Wiresheet',
                                      onPressed: () async {
                                        final result =
                                            await confirmDeleteWiresheet(
                                                context,
                                                wiresheet.id,
                                                wiresheet.name,
                                                ref);

                                        if (result && context.mounted) {
                                          if (selectedWiresheetId ==
                                              wiresheet.id) {
                                            setActiveNode('wiresheets');
                                          }

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content:
                                                    Text('Wiresheet deleted')),
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
                  setActiveNode('workgroups');
                },
                child: Row(
                  children: [
                    const Icon(Icons.group_work),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Workgroups',
                        style: TextStyle(
                          fontWeight: openWorkGroup && selectedWorkgroup == null
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: openWorkGroup && selectedWorkgroup == null
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
                          setActiveNode('workgroups',
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
                                  fontWeight: selectedWorkgroup == workgroup &&
                                          !showingGroups &&
                                          selectedGroup == null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: selectedWorkgroup == workgroup &&
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
                              setActiveNode(
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
                                              selectedWorkgroup == workgroup &&
                                              selectedGroup == null
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: showingGroups &&
                                              selectedWorkgroup == workgroup &&
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
                                      setActiveNode('groupDetail',
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
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            group.description.isEmpty
                                                ? "Group ${group.groupId}"
                                                : group.description,
                                            style: TextStyle(
                                              fontWeight: selectedWorkgroup ==
                                                          workgroup &&
                                                      selectedGroup == group
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: selectedWorkgroup ==
                                                          workgroup &&
                                                      selectedGroup == group
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
                                setActiveNode('router', additionalData: {
                                  'workgroup': workgroup,
                                  'router': router,
                                });
                              },
                              onSecondaryTap: () {
                                setActiveNode('router');
                              },
                              child: Row(
                                children: [
                                  const Icon(Icons.router),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(router.description),
                                  ),
                                ],
                              ),
                            ),
                            children: [
                              ...router.devicesBySubnet.entries.map((entry) {
                                final subnet = entry.key;
                                final subnetDevices = entry.value;
                                return TreeNode(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.hub),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
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
                                              device.description.isEmpty
                                                  ? "Device_${device.deviceId}"
                                                  : device.description,
                                              getDeviceIcon(device),
                                              WidgetType.text,
                                              context,
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
    );
  }

  Widget _buildDraggable(
      String label, IconData icon, WidgetType type, BuildContext context) {
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
}
