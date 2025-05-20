import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:grms_designer/models/helvar_models/helvar_device.dart';

import '../models/helvar_models/helvar_group.dart';
import '../models/helvar_models/helvar_router.dart';
import '../models/helvar_models/workgroup.dart';
import '../niagara/home/utils.dart';
import '../niagara/models/component_type.dart';
import '../models/flowsheet.dart';
import '../providers/flowsheet_provider.dart';
import '../screens/actions.dart';
import '../screens/dialogs/device_context_menu.dart';
import '../screens/dialogs/flowsheet_actions.dart';
import '../utils/general_ui.dart';

class AppTreeView extends ConsumerWidget {
  final List<Flowsheet> wiresheets;
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
  final HelvarRouter? selectedRouter;
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
    this.selectedRouter,
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
                      content: GestureDetector(
                        onDoubleTap: () {
                          setActiveNode('graphics');
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Graphics",
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      children: [
                        TreeNode(
                          content: GestureDetector(
                            onDoubleTap: () {
//
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "Graphics 1",
                                style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
                                "Flowsheets", // Updated to use "Flowsheets" for consistency
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
                            tooltip: 'Create New Flowsheet',
                            onPressed: () => createNewFlowsheet(context,
                                ref), // Updated to use flowsheet function
                          ),
                        ],
                      ),
                      children: [
                        ...wiresheets.map((wiresheet) => TreeNode(
                              content: GestureDetector(
                                onDoubleTap: () {
                                  if (ref
                                          .read(flowsheetsProvider.notifier)
                                          .activeFlowsheetId !=
                                      null) {
                                    ref
                                        .read(flowsheetsProvider.notifier)
                                        .saveActiveFlowsheet();
                                  }

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
                                      tooltip: 'Delete Flowsheet',
                                      onPressed: () async {
                                        final result =
                                            await confirmDeleteFlowsheet(
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
                                                    Text('Flowsheet deleted')),
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
                                          selectedGroup == null &&
                                          selectedRouter == null
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
                                setActiveNode('router', additionalData: {
                                  'workgroup': workgroup,
                                  'router': router,
                                });
                              },
                              child: Row(
                                children: [
                                  const Icon(Icons.router),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      router.description,
                                      style: TextStyle(
                                        fontWeight: selectedRouter == router
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: selectedRouter == router
                                            ? Colors.blue
                                            : null,
                                      ),
                                    ),
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
                                              device,
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
            _buildLogicComponentsNode(context),
          ]),
        ],
      ),
    );
  }

  TreeNode _buildLogicComponentsNode(BuildContext context) {
    return TreeNode(
      content: GestureDetector(
        onDoubleTap: () {
// Expandable section logic if needed
        },
        child: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "Components",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      children: [
        TreeNode(
          content: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Logic",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          children: [
            TreeNode(
                content: _buildDraggableComponentItem(
                    const ComponentType(ComponentType.AND_GATE))),
            TreeNode(
                content: _buildDraggableComponentItem(
                    const ComponentType(ComponentType.OR_GATE))),
            TreeNode(
                content: _buildDraggableComponentItem(
                    const ComponentType(ComponentType.IS_GREATER_THAN))),
          ],
        ),
        TreeNode(
          content: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Math",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          children: [
            TreeNode(
                content: _buildDraggableComponentItem(
                    const ComponentType(ComponentType.ADD))),
            TreeNode(
                content: _buildDraggableComponentItem(
                    const ComponentType(ComponentType.SUBTRACT))),
            TreeNode(
                content: _buildDraggableComponentItem(
                    const ComponentType(ComponentType.MULTIPLY))),
            TreeNode(
                content: _buildDraggableComponentItem(
                    const ComponentType(ComponentType.DIVIDE))),
            TreeNode(
                content: _buildDraggableComponentItem(
                    const ComponentType(ComponentType.MAX))),
            TreeNode(
                content: _buildDraggableComponentItem(
                    const ComponentType(ComponentType.MIN))),
            TreeNode(
                content: _buildDraggableComponentItem(
                    const ComponentType(ComponentType.POWER))),
            TreeNode(
                content: _buildDraggableComponentItem(
                    const ComponentType(ComponentType.ABS))),
          ],
        ),
        TreeNode(
          content: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "UI",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          children: [
            TreeNode(
                content: _buildDraggableComponentItem(
                    const ComponentType("Button"))),
            TreeNode(
                content:
                    _buildDraggableComponentItem(const ComponentType("Text"))),
          ],
        ),
        TreeNode(
          content: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Util",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          children: [
            TreeNode(
                content:
                    _buildDraggableComponentItem(const ComponentType("Ramp"))),
            TreeNode(
                content: _buildDraggableComponentItem(
                    const ComponentType("Toggle"))),
          ],
        ),
        TreeNode(
          content: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Points",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          children: [
            TreeNode(
                content: _buildDraggableComponentItem(
                    const ComponentType(ComponentType.BOOLEAN_POINT))),
            TreeNode(
                content: _buildDraggableComponentItem(
                    const ComponentType(ComponentType.BOOLEAN_WRITABLE))),
            TreeNode(
                content: _buildDraggableComponentItem(
                    const ComponentType(ComponentType.STRING_POINT))),
            TreeNode(
                content: _buildDraggableComponentItem(
                    const ComponentType(ComponentType.STRING_WRITABLE))),
            TreeNode(
                content: _buildDraggableComponentItem(
                    const ComponentType(ComponentType.NUMERIC_POINT))),
            TreeNode(
                content: _buildDraggableComponentItem(
                    const ComponentType(ComponentType.NUMERIC_WRITABLE))),
          ],
        ),
      ],
    );
  }

  Widget _buildDraggableComponentItem(ComponentType type) {
    final comp = Column(
      children: [
        Icon(getIconForComponentType(type)),
        const SizedBox(height: 4.0),
        Text(getNameForComponentType(type),
            style: const TextStyle(fontSize: 12)),
      ],
    );
    return Draggable<ComponentType>(
      data: type,
      feedback: Material(
        elevation: 4.0,
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(color: Colors.indigo),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(getIconForComponentType(type), size: 24),
              const SizedBox(height: 4.0),
              Text(
                getNameForComponentType(type),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: comp,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: comp,
      ),
    );
  }

  Widget _buildDraggable(
      String label, IconData icon, HelvarDevice? device, BuildContext context) {
    return Draggable<Map<String, dynamic>>(
      data: {
        "componentType": label,
        "icon": icon,
        "device": device,
        "deviceData": device != null
            ? {
                "deviceId": device.deviceId,
                "deviceAddress": device.address,
                "deviceType": device.helvarType,
                "description": device.description
              }
            : null,
      },
      feedback: Material(
        elevation: 4.0,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(icon), const SizedBox(width: 8.0), Text(label)],
          ),
        ),
      ),
      childWhenDragging: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 8.0),
          Text(label, style: TextStyle(color: Colors.grey[600]))
        ],
      ),
      child: Row(
        children: [Icon(icon), const SizedBox(width: 8.0), Text(label)],
      ),
    );
  }
}
