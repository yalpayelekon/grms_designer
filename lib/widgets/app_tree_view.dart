import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:grms_designer/models/helvar_models/helvar_device.dart';
import '../models/helvar_models/input_device.dart';
import '../utils/device_icons.dart';
import '../models/helvar_models/helvar_group.dart';
import '../models/helvar_models/helvar_router.dart';
import '../models/helvar_models/workgroup.dart';
import '../niagara/home/utils.dart';
import '../niagara/models/component_type.dart';
import '../models/flowsheet.dart';
import '../providers/flowsheet_provider.dart';
import '../providers/tree_expansion_provider.dart'; // Add this import
import '../screens/actions.dart';
import '../screens/dialogs/device_context_menu.dart';
import '../screens/dialogs/flowsheet_actions.dart';
import '../utils/general_ui.dart';

class AppTreeView extends ConsumerStatefulWidget {
  final List<Flowsheet> wiresheets;
  final List<Workgroup> workgroups;
  final bool showingProject;
  final bool openSettings;
  final bool showingWorkgroup;
  final bool openWorkGroups;
  final bool openWiresheet;
  final bool showingImages;
  final bool showingGroups;
  final String? currentFileDirectory;
  final String? selectedWiresheetId;
  final Workgroup? selectedWorkgroup;
  final HelvarGroup? selectedGroup;
  final HelvarRouter? selectedRouter;
  final Function(String,
      {Workgroup? workgroup,
      HelvarGroup? group,
      HelvarRouter? router,
      String? wiresheetId,
      int? subnetNumber,
      List<HelvarDevice>? subnetDevices,
      HelvarDevice? device,
      ButtonPoint? point}) setActiveNode;

  const AppTreeView({
    super.key,
    required this.wiresheets,
    required this.workgroups,
    required this.showingProject,
    required this.openSettings,
    required this.openWorkGroups,
    required this.showingWorkgroup,
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
  AppTreeViewState createState() => AppTreeViewState();
}

class AppTreeViewState extends ConsumerState<AppTreeView> {
  late TreeController _treeController;

  @override
  void initState() {
    super.initState();
    _treeController = TreeController(allNodesExpanded: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(treeExpansionProvider.notifier).resetExpansionState();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          ref.read(treeExpansionProvider.notifier).clearNewlyAddedNodes();
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(treeExpansionProvider);

    return SingleChildScrollView(
      child: Column(
        children: [
          TreeView(treeController: _treeController, nodes: [
            TreeNode(
              content: GestureDetector(
                onDoubleTap: () {
                  widget.setActiveNode('project');
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Project",
                    style: TextStyle(
                      fontWeight: widget.showingProject
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: widget.showingProject ? Colors.blue : null,
                    ),
                  ),
                ),
              ),
              children: [
                TreeNode(
                  content: GestureDetector(
                    onDoubleTap: () {
                      widget.setActiveNode('settings');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Settings",
                        style: TextStyle(
                          fontWeight: widget.openSettings
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: widget.openSettings ? Colors.blue : null,
                        ),
                      ),
                    ),
                  ),
                ),
                TreeNode(
                  content: GestureDetector(
                    onDoubleTap: () {
                      widget.setActiveNode('files');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Files",
                        style: TextStyle(
                          fontWeight: widget.currentFileDirectory != null &&
                                  !widget.showingImages
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: widget.currentFileDirectory != null &&
                                  !widget.showingImages
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
                          widget.setActiveNode('images');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Images",
                            style: TextStyle(
                              fontWeight: widget.showingImages
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: widget.showingImages ? Colors.blue : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    TreeNode(
                      content: GestureDetector(
                        onDoubleTap: () {
                          widget.setActiveNode('graphics');
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
                              widget.setActiveNode('graphicsDetail');
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
                              widget.setActiveNode('wiresheets');
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "Flowsheets",
                                style: TextStyle(
                                  fontWeight: widget.openWiresheet
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color:
                                      widget.openWiresheet ? Colors.blue : null,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            tooltip: 'Create New Flowsheet',
                            onPressed: () => createNewFlowsheet(context, ref),
                          ),
                        ],
                      ),
                      children: [
                        ...widget.wiresheets.map((wiresheet) => TreeNode(
                              content: GestureDetector(
                                onDoubleTap: () {
                                  final activeFlowsheetId = ref
                                      .read(flowsheetsProvider.notifier)
                                      .activeFlowsheetId;

                                  if (activeFlowsheetId != null &&
                                      activeFlowsheetId != wiresheet.id) {
                                    ref
                                        .read(flowsheetsProvider.notifier)
                                        .saveActiveFlowsheet();
                                  }

                                  widget.setActiveNode('wiresheet',
                                      wiresheetId: wiresheet.id);
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
                                          fontWeight:
                                              widget.selectedWiresheetId ==
                                                      wiresheet.id
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                          color: widget.selectedWiresheetId ==
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
                                          if (widget.selectedWiresheetId ==
                                              wiresheet.id) {
                                            widget.setActiveNode('wiresheets');
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
                  widget.setActiveNode('workgroups');
                },
                child: Row(
                  children: [
                    const Icon(Icons.group_work),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Workgroups',
                        style: TextStyle(
                          fontWeight: widget.openWorkGroups
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: widget.openWorkGroups ? Colors.blue : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              children: widget.workgroups
                  .map(
                    (workgroup) => TreeNode(
                      content: GestureDetector(
                        onDoubleTap: () {
                          widget.setActiveNode('workgroupDetail',
                              workgroup: workgroup);
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.lan),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                workgroup.description,
                                style: TextStyle(
                                  fontWeight:
                                      widget.selectedWorkgroup == workgroup &&
                                              widget.showingWorkgroup
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  color:
                                      widget.selectedWorkgroup == workgroup &&
                                              widget.showingWorkgroup
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
                              widget.setActiveNode(
                                'groups',
                                workgroup: workgroup,
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
                                      fontWeight: widget.selectedWorkgroup ==
                                                  workgroup &&
                                              widget.showingGroups
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: widget.selectedWorkgroup ==
                                                  workgroup &&
                                              widget.showingGroups
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
                                      widget.setActiveNode('groupDetail',
                                          workgroup: workgroup, group: group);
                                    },
                                    onSecondaryTap: () {
                                      showGroupContextMenu(
                                          context, group, workgroup);
                                    },
                                    child: Row(
                                      children: [
                                        const Icon(Icons.group),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            group.description.isEmpty
                                                ? "Group ${group.groupId}"
                                                : group.description,
                                            style: TextStyle(
                                              fontWeight:
                                                  widget.selectedGroup == group
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                              color:
                                                  widget.selectedGroup == group
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
                                widget.setActiveNode('router',
                                    workgroup: workgroup, router: router);
                              },
                              onSecondaryTap: () {
                                widget.setActiveNode('router',
                                    workgroup: workgroup, router: router);
                              },
                              child: Row(
                                children: [
                                  const Icon(Icons.router),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      router.description,
                                      style: TextStyle(
                                        fontWeight:
                                            widget.selectedRouter == router
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                        color: widget.selectedRouter == router
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
                                  content: GestureDetector(
                                    onDoubleTap: () {
                                      widget.setActiveNode(
                                        'subnetDetail',
                                        workgroup: workgroup,
                                        router: router,
                                        subnetNumber: subnet,
                                        subnetDevices: subnetDevices,
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        const Icon(Icons.hub),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                              "Subnet $subnet (${subnetDevices.length} devices)"),
                                        ),
                                      ],
                                    ),
                                  ),
                                  children: subnetDevices
                                      .map(
                                        (device) => _buildDeviceTreeNode(
                                            device, context, workgroup, router),
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

  TreeNode _buildDeviceTreeNode(HelvarDevice device, BuildContext context,
      Workgroup workgroup, HelvarRouter router) {
    final deviceName = device.description.isEmpty
        ? "Device_${device.deviceId}"
        : device.description;

    final List<TreeNode> deviceChildren = [];

    if (device is HelvarDriverInputDevice &&
        device.isButtonDevice &&
        device.buttonPoints.isNotEmpty) {
      deviceChildren.add(TreeNode(
        content: GestureDetector(
          onDoubleTap: () {
            widget.setActiveNode(
              'pointsDetail',
              workgroup: workgroup,
              router: router,
              device: device,
            );
          },
          child: const Row(
            children: [
              Icon(Icons.add_circle_outline, size: 18),
              SizedBox(width: 4),
              Text("Points"),
            ],
          ),
        ),
        children: device.buttonPoints
            .map((point) => _buildDraggableButtonPointNode(point, device))
            .toList(),
      ));
    }

    if (device.helvarType == 'input' || device.emergency) {
      deviceChildren.add(TreeNode(
        content: const Row(
          children: [
            Icon(Icons.warning_amber, size: 18),
            SizedBox(width: 4),
            Text("Alarm Source Info"),
          ],
        ),
        children: [
          TreeNode(
            content: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text('State: ${device.state}'),
            ),
          ),
          if (device.deviceStateCode != null)
            TreeNode(
              content: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                    'State Code: 0x${device.deviceStateCode!.toRadixString(16)}'),
              ),
            ),
        ],
      ));
    }

    return TreeNode(
      content: GestureDetector(
        onDoubleTap: () {
          widget.setActiveNode(
            'deviceDetail',
            workgroup: workgroup,
            router: router,
            device: device,
          );
        },
        onSecondaryTap: () => showDeviceContextMenu(context, device),
        child: _buildDraggable(deviceName, device, context),
      ),
      children: deviceChildren.isEmpty ? null : deviceChildren,
    );
  }

  TreeNode _buildDraggableButtonPointNode(
      ButtonPoint buttonPoint, HelvarDevice parentDevice) {
    return TreeNode(
      content: GestureDetector(
        onDoubleTap: () {
          Workgroup? workgroup;
          HelvarRouter? router;

          for (final wg in widget.workgroups) {
            for (final r in wg.routers) {
              if (r.devices.any((d) => d.address == parentDevice.address)) {
                workgroup = wg;
                router = r;
                break;
              }
            }
            if (workgroup != null) break;
          }

          if (workgroup != null && router != null) {
            widget.setActiveNode(
              'pointDetail',
              workgroup: workgroup,
              router: router,
              device: parentDevice,
              point: buttonPoint,
            );
          }
        },
        child: Draggable<Map<String, dynamic>>(
          data: {
            "componentType": "BooleanPoint",
            "buttonPoint": buttonPoint,
            "parentDevice": parentDevice,
            "pointData": {
              "name": buttonPoint.name,
              "function": buttonPoint.function,
              "buttonId": buttonPoint.buttonId,
              "deviceAddress": parentDevice.address,
              "deviceId": parentDevice.deviceId,
              "isButtonPoint": true,
            }
          },
          feedback: Material(
            elevation: 4.0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getButtonPointIcon(buttonPoint),
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    _getButtonPointDisplayName(buttonPoint),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          childWhenDragging: Row(
            children: [
              Icon(
                _getButtonPointIcon(buttonPoint),
                size: 16,
                color: Colors.grey[400],
              ),
              const SizedBox(width: 4),
              Text(
                _getButtonPointDisplayName(buttonPoint),
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                _getButtonPointIcon(buttonPoint),
                size: 16,
                color: Colors.green,
              ),
              const SizedBox(width: 4),
              Text(_getButtonPointDisplayName(buttonPoint)),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getButtonPointIcon(ButtonPoint buttonPoint) {
    if (buttonPoint.function.contains('Status') ||
        buttonPoint.name.contains('Missing')) {
      return Icons.info_outline;
    } else if (buttonPoint.function.contains('IR')) {
      return Icons.settings_remote;
    } else {
      return Icons.touch_app;
    }
  }

  String _getButtonPointDisplayName(ButtonPoint buttonPoint) {
    return buttonPoint.name.split('_').last;
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
      String label, HelvarDevice? device, BuildContext context) {
    return Draggable<Map<String, dynamic>>(
      data: {
        "componentType": label,
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
            children: [
              getDeviceIconWidget(device),
              const SizedBox(width: 8.0),
              Text(label)
            ],
          ),
        ),
      ),
      childWhenDragging: Row(
        children: [
          getDeviceIconWidget(device, size: 20.0),
          const SizedBox(width: 8.0),
          Text(label, style: TextStyle(color: Colors.grey[600]))
        ],
      ),
      child: Row(
        children: [
          getDeviceIconWidget(device),
          const SizedBox(width: 8.0),
          Text(label)
        ],
      ),
    );
  }
}
