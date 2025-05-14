import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:grms_designer/models/helvar_models/helvar_device.dart';

import '../models/canvas_item.dart';
import '../models/helvar_models/helvar_group.dart';
import '../models/helvar_models/workgroup.dart';
import '../models/widget_type.dart';
import '../models/wiresheet.dart';
import '../niagara/models/component_type.dart';
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
                                              WidgetType.treenode,
                                              device,
                                              null,
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
            _buildLogicComponents(context),
          ]),
        ],
      ),
    );
  }

  TreeNode _buildLogicComponents(BuildContext context) {
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
                content: _buildDraggable(
                    "IF",
                    Icons.compare_arrows,
                    WidgetType.treenode,
                    null,
                    ComponentCategory.logic,
                    context)),
            TreeNode(
                content: _buildDraggable(
                    "AND",
                    Icons.add_link,
                    WidgetType.treenode,
                    null,
                    ComponentCategory.logic,
                    context)),
            TreeNode(
                content: _buildDraggable(
                    "OR",
                    Icons.call_split,
                    WidgetType.treenode,
                    null,
                    ComponentCategory.logic,
                    context)),
            TreeNode(
                content: _buildDraggable(
                    "GreaterThan",
                    Icons.trending_up,
                    WidgetType.treenode,
                    null,
                    ComponentCategory.logic,
                    context)),
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
                content: _buildDraggable("ADD", Icons.add, WidgetType.treenode,
                    null, ComponentCategory.math, context)),
            TreeNode(
                content: _buildDraggable(
                    "SUBTRACT",
                    Icons.remove,
                    WidgetType.treenode,
                    null,
                    ComponentCategory.math,
                    context)),
            TreeNode(
                content: _buildDraggable(
                    "MULTIPLY",
                    Icons.close,
                    WidgetType.treenode,
                    null,
                    ComponentCategory.math,
                    context)),
            TreeNode(
                content: _buildDraggable(
                    "DIVIDE",
                    Icons.diamond, // find a suitable one
                    WidgetType.treenode,
                    null,
                    ComponentCategory.math,
                    context)),
            TreeNode(
                content: _buildDraggable(
                    "MODULO",
                    Icons.mode, // find a suitable one
                    WidgetType.treenode,
                    null,
                    ComponentCategory.math,
                    context)),
            TreeNode(
                content: _buildDraggable(
                    "POWER",
                    Icons.star, // find a suitable one
                    WidgetType.treenode,
                    null,
                    ComponentCategory.math,
                    context)),
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
                content: _buildDraggable("Button", Icons.touch_app,
                    WidgetType.treenode, null, ComponentCategory.ui, context)),
            TreeNode(
                content: _buildDraggable("Text", Icons.text_fields,
                    WidgetType.treenode, null, ComponentCategory.ui, context)),
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
                content: _buildDraggable(
                    "Ramp",
                    Icons.trending_up,
                    WidgetType.treenode,
                    null,
                    ComponentCategory.util,
                    context)),
            TreeNode(
                content: _buildDraggable(
                    "Toggle",
                    Icons.toggle_on,
                    WidgetType.treenode,
                    null,
                    ComponentCategory.util,
                    context)),
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
                content: _buildDraggable(
                    "BooleanPoint",
                    Icons.toggle_off,
                    WidgetType.treenode,
                    null,
                    ComponentCategory.point,
                    context)),
            TreeNode(
                content: _buildDraggable(
                    "BooleanWritable",
                    Icons.toggle_on,
                    WidgetType.treenode,
                    null,
                    ComponentCategory.point,
                    context)),
            TreeNode(
                content: _buildDraggable(
                    "StringPoint",
                    Icons.text_fields,
                    WidgetType.treenode,
                    null,
                    ComponentCategory.point,
                    context)),
            TreeNode(
                content: _buildDraggable(
                    "StringWritable",
                    Icons.edit_note,
                    WidgetType.treenode,
                    null,
                    ComponentCategory.point,
                    context)),
            TreeNode(
                content: _buildDraggable(
                    "NumericPoint",
                    Icons.numbers,
                    WidgetType.treenode,
                    null,
                    ComponentCategory.point,
                    context)),
            TreeNode(
                content: _buildDraggable(
                    "NumericWritable",
                    Icons.edit,
                    WidgetType.treenode,
                    null,
                    ComponentCategory.point,
                    context)),
          ],
        ),
      ],
    );
  }

  Widget _buildDraggable(String label, IconData icon, WidgetType type,
      HelvarDevice? device, ComponentCategory? category, BuildContext context) {
    String componentTypeString = "";
    if (device != null) {
      componentTypeString = ComponentType.HELVAR_DEVICE;
    } else if (category != null) {
      switch (category) {
        case ComponentCategory.logic:
          switch (label) {
            case "AND":
              componentTypeString = ComponentType.AND_GATE;
              break;
            case "OR":
              componentTypeString = ComponentType.OR_GATE;
              break;
            case "GreaterThan":
              componentTypeString = ComponentType.IS_GREATER_THAN;
              break;
            default:
              componentTypeString =
                  ComponentType.AND_GATE; // Default to AND if unknown
          }
          break;
        case ComponentCategory.math:
          switch (label) {
            case "ADD":
              componentTypeString = ComponentType.ADD;
              break;
            case "SUBTRACT":
              componentTypeString = ComponentType.SUBTRACT;
              break;
            case "MULTIPLY":
              componentTypeString = ComponentType.MULTIPLY;
              break;
            case "DIVIDE":
              componentTypeString = ComponentType.DIVIDE;
              break;
            case "MODULO":
              componentTypeString = ComponentType.MIN;
              break; // Mapping to available type
            case "POWER":
              componentTypeString = ComponentType.POWER;
              break;
            default:
              componentTypeString =
                  ComponentType.ADD; // Default to ADD if unknown
          }
          break;
        case ComponentCategory.point:
          switch (label) {
            case "NumericPoint":
              componentTypeString = ComponentType.NUMERIC_POINT;
              break;
            case "NumericWritable":
              componentTypeString = ComponentType.NUMERIC_WRITABLE;
              break;
            case "BooleanPoint":
              componentTypeString = ComponentType.BOOLEAN_POINT;
              break;
            case "BooleanWritable":
              componentTypeString = ComponentType.BOOLEAN_WRITABLE;
              break;
            case "StringPoint":
              componentTypeString = ComponentType.STRING_POINT;
              break;
            case "StringWritable":
              componentTypeString = ComponentType.STRING_WRITABLE;
              break;
            default:
              componentTypeString = ComponentType.NUMERIC_POINT; // Default
          }
          break;
        default:
          componentTypeString = ComponentType.NUMERIC_POINT; // Default fallback
      }
    }

    return Draggable<Map<String, dynamic>>(
      data: {
        "componentType": componentTypeString,
        "label": label,
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
