import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:grms_designer/models/helvar_models/helvar_device.dart';
import 'package:grms_designer/models/helvar_models/output_device.dart';
import 'package:grms_designer/utils/treeview_utils.dart';
import 'package:grms_designer/widgets/logics_treenode.dart';
import 'package:grms_designer/widgets/project_treenode.dart';
import '../models/helvar_models/input_device.dart';
import '../models/helvar_models/helvar_group.dart';
import '../models/helvar_models/helvar_router.dart';
import '../models/helvar_models/workgroup.dart';
import '../models/flowsheet.dart';
import '../providers/tree_expansion_provider.dart';
import '../screens/actions.dart';
import '../screens/dialogs/device_context_menu.dart';

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
  final Function(
    String, {
    Workgroup? workgroup,
    HelvarGroup? group,
    HelvarRouter? router,
    String? wiresheetId,
    int? subnetNumber,
    List<HelvarDevice>? subnetDevices,
    HelvarDevice? device,
    OutputPoint? outputPoint,
    ButtonPoint? point,
  })
  setActiveNode;

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
          TreeView(
            treeController: _treeController,
            nodes: [
              buildProjectNode(widget, context, ref),
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
                            widget.setActiveNode(
                              'workgroupDetail',
                              workgroup: workgroup,
                            );
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
                                  const Icon(
                                    Icons.group_work,
                                    color: Colors.blue,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      "Groups",
                                      style: TextStyle(
                                        fontWeight:
                                            widget.selectedWorkgroup ==
                                                    workgroup &&
                                                widget.showingGroups
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color:
                                            widget.selectedWorkgroup ==
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
                                        widget.setActiveNode(
                                          'groupDetail',
                                          workgroup: workgroup,
                                          group: group,
                                        );
                                      },
                                      onSecondaryTap: () {
                                        showGroupContextMenu(
                                          context,
                                          group,
                                          workgroup,
                                        );
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
                                                    widget.selectedGroup ==
                                                        group
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color:
                                                    widget.selectedGroup ==
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
                                  widget.setActiveNode(
                                    'router',
                                    workgroup: workgroup,
                                    router: router,
                                  );
                                },
                                onSecondaryTap: () {
                                  widget.setActiveNode(
                                    'router',
                                    workgroup: workgroup,
                                    router: router,
                                  );
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
                                              "Subnet $subnet (${subnetDevices.length} devices)",
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    children: subnetDevices
                                        .map(
                                          (device) => _buildDeviceTreeNode(
                                            device,
                                            context,
                                            workgroup,
                                            router,
                                          ),
                                        )
                                        .toList(),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
              buildLogicComponentsNode(context),
            ],
          ),
        ],
      ),
    );
  }

  TreeNode _buildDeviceTreeNode(
    HelvarDevice device,
    BuildContext context,
    Workgroup workgroup,
    HelvarRouter router,
  ) {
    final deviceName = device.description.isEmpty
        ? "Device_${device.deviceId}"
        : device.description;

    final List<TreeNode> deviceChildren = [];

    if (device is HelvarDriverInputDevice &&
        device.isButtonDevice &&
        device.buttonPoints.isNotEmpty) {
      deviceChildren.add(
        TreeNode(
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
        ),
      );
    }

    if (device is HelvarDriverOutputDevice) {
      if (device.outputPoints.isEmpty) {
        device.generateOutputPoints();
      }

      if (device.outputPoints.isNotEmpty) {
        deviceChildren.add(
          TreeNode(
            content: GestureDetector(
              onDoubleTap: () {
                widget.setActiveNode(
                  'outputPointsDetail',
                  workgroup: workgroup,
                  router: router,
                  device: device,
                );
                print('Output points tapped for ${device.address}');
              },
              child: const Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 18,
                    color: Colors.orange,
                  ),
                  SizedBox(width: 4),
                  Text("Points"),
                ],
              ),
            ),
            children: device.outputPoints
                .map((point) => _buildOutputPointNode(point, device))
                .toList(),
          ),
        );
      }
    }

    if (device.helvarType == 'input' || device.emergency) {
      deviceChildren.add(
        TreeNode(
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
                    'State Code: 0x${device.deviceStateCode!.toRadixString(16)}',
                  ),
                ),
              ),
          ],
        ),
      );
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
        child: buildDraggable(deviceName, device, context),
      ),
      children: deviceChildren.isEmpty ? null : deviceChildren,
    );
  }

  TreeNode _buildOutputPointNode(
    OutputPoint outputPoint,
    HelvarDevice parentDevice,
  ) {
    return TreeNode(
      content: Row(
        children: [
          Icon(getOutputPointIcon(outputPoint), size: 16, color: Colors.orange),
          const SizedBox(width: 4),
          Text(outputPoint.function),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: getOutputPointValueColor(outputPoint),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              formatOutputPointValue(outputPoint),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TreeNode _buildDraggableButtonPointNode(
    ButtonPoint buttonPoint,
    HelvarDevice parentDevice,
  ) {
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
            },
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
                    getButtonPointIcon(buttonPoint),
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    getButtonPointDisplayName(buttonPoint),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          childWhenDragging: Row(
            children: [
              Icon(
                getButtonPointIcon(buttonPoint),
                size: 16,
                color: Colors.grey[400],
              ),
              const SizedBox(width: 4),
              Text(
                getButtonPointDisplayName(buttonPoint),
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                getButtonPointIcon(buttonPoint),
                size: 16,
                color: Colors.green,
              ),
              const SizedBox(width: 4),
              Text(getButtonPointDisplayName(buttonPoint)),
            ],
          ),
        ),
      ),
    );
  }
}
