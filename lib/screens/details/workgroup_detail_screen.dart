import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/models/helvar_models/helvar_device.dart';
import 'package:grms_designer/models/helvar_models/helvar_group.dart';
import 'package:grms_designer/models/helvar_models/input_device.dart';
import 'package:grms_designer/providers/centralized_polling_provider.dart';
import 'package:grms_designer/utils/core/date_utils.dart';
import 'package:grms_designer/utils/ui/ui_helpers.dart';
import 'package:grms_designer/widgets/point_polling_config_widget.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../providers/workgroups_provider.dart';
import '../../widgets/common/detail_card.dart';
import '../../widgets/common/expandable_list_item.dart';

class WorkgroupDetailScreen extends ConsumerStatefulWidget {
  final Workgroup workgroup;

  const WorkgroupDetailScreen({super.key, required this.workgroup});

  @override
  WorkgroupDetailScreenState createState() => WorkgroupDetailScreenState();
}

class WorkgroupDetailScreenState extends ConsumerState<WorkgroupDetailScreen> {
  bool _isLoading = false;

  Workgroup get currentWorkgroup {
    final workgroups = ref.watch(workgroupsProvider);
    return workgroups.firstWhere(
      (wg) => wg.id == widget.workgroup.id,
      orElse: () => widget.workgroup,
    );
  }

  Widget _buildRouterItem(HelvarRouter router) {
    return ExpandableListItem(
      title: router.description,
      subtitle:
          'IP: ${router.ipAddress} • Address: ${router.address} • ${router.devices.length} devices',
      leadingIcon: Icons.router,
      leadingIconColor: Colors.purple,
      indentLevel: 1,
      detailRows: [
        DetailRow(
          label: 'Description',
          value: router.description,
          showDivider: true,
        ),
        DetailRow(
          label: 'IP Address',
          value: router.ipAddress,
          showDivider: true,
        ),
        DetailRow(label: 'Address', value: router.address, showDivider: true),
        DetailRow(
          label: 'Device Count',
          value: '${router.devices.length} devices',
          showDivider: true,
        ),
        if (router.devicesBySubnet.isNotEmpty)
          DetailRow(
            label: 'Subnets',
            value: '${router.devicesBySubnet.length} subnets',
          ),
      ],
      children: [
        if (router.devicesBySubnet.isNotEmpty)
          ...router.devicesBySubnet.entries.map(
            (entry) => _buildSubnetItem(entry.key, entry.value),
          ),
      ],
    );
  }

  Widget _buildSubnetItem(int subnetId, List devices) {
    final outputDevices = devices.where((d) => d.helvarType == 'output').length;
    final inputDevices = devices.where((d) => d.helvarType == 'input').length;

    return ExpandableListItem(
      title: 'Subnet $subnetId',
      subtitle:
          '${devices.length} devices • $outputDevices output • $inputDevices input',
      leadingIcon: Icons.hub,
      leadingIconColor: Colors.orange,
      indentLevel: 2,
      children: devices.map((device) => _buildDeviceItem(device)).toList(),
    );
  }

  Widget _buildDeviceItem(HelvarDevice device) {
    int pointCount = 0;
    if (device.helvarType == 'output') {
      pointCount = 6;
    } else if (device.helvarType == 'input' && device.isButtonDevice) {
      if (device is HelvarDriverInputDevice) {
        pointCount = device.buttonPoints.length;
      }
    }

    return ExpandableListItem(
      title: device.description.isEmpty
          ? 'Device ${device.deviceId}'
          : device.description,
      subtitle:
          'Address: ${device.address} • Type: ${device.helvarType} • $pointCount points',
      leadingIcon: Icons.device_hub,
      leadingIconColor: Colors.teal,
      indentLevel: 3,
      detailRows: [
        DetailRow(
          label: 'Device ID',
          value: device.deviceId.toString(),
          showDivider: true,
        ),
        DetailRow(label: 'Address', value: device.address, showDivider: true),
        DetailRow(label: 'Type', value: device.helvarType, showDivider: true),
        DetailRow(
          label: 'Points',
          value: '$pointCount polling points',
          showDivider: true,
        ),
        if (device.state.isNotEmpty)
          DetailRow(label: 'State', value: device.state, showDivider: true),
        StatusDetailRow(
          label: 'Emergency',
          statusText: device.emergency ? 'Yes' : 'No',
          statusColor: device.emergency ? Colors.red : Colors.green,
          showDivider: true,
        ),
        StatusDetailRow(
          label: 'Button Device',
          statusText: device.isButtonDevice ? 'Yes' : 'No',
          statusColor: device.isButtonDevice ? Colors.blue : Colors.grey,
          showDivider: true,
        ),
        StatusDetailRow(
          label: 'Multisensor',
          statusText: device.isMultisensor ? 'Yes' : 'No',
          statusColor: device.isMultisensor ? Colors.green : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildGroupItem(HelvarGroup group) {
    return ExpandableListItem(
      title: group.description.isEmpty
          ? "Group ${group.groupId}"
          : group.description,
      subtitle:
          'ID: ${group.groupId} • Power: ${group.powerConsumption.toStringAsFixed(1)}W',
      leadingIcon: Icons.group,
      leadingIconColor: Colors.green,
      indentLevel: 1,
      detailRows: [
        DetailRow(label: 'Group ID', value: group.groupId, showDivider: true),
        DetailRow(label: 'Type', value: group.type, showDivider: true),
        DetailRow(
          label: 'Current Power',
          value: '${group.powerConsumption.toStringAsFixed(2)} W',
          showDivider: true,
        ),
        DetailRow(
          label: 'Polling Minutes',
          value: '${group.powerPollingMinutes} minutes',
          showDivider: true,
        ),
        if (group.sceneTable.isNotEmpty)
          DetailRow(
            label: 'Scenes',
            value:
                '${group.sceneTable.length} scenes: ${group.sceneTable.join(', ')}',
            showDivider: true,
          ),
        if (group.gatewayRouterIpAddress.isNotEmpty)
          DetailRow(
            label: 'Gateway Router',
            value: group.gatewayRouterIpAddress,
          ),
      ],
    );
  }

  void _togglePolling(bool enabled) async {
    setState(() => _isLoading = true);

    try {
      await ref
          .read(workgroupsProvider.notifier)
          .toggleWorkgroupPolling(widget.workgroup.id, enabled);

      final pollingManager = ref.read(pollingManagerProvider.notifier);
      if (enabled) {
        await pollingManager.startWorkgroupPolling(widget.workgroup.id);
      } else {
        pollingManager.stopWorkgroupPolling(widget.workgroup.id);
      }

      final message = enabled
          ? 'Device point polling enabled'
          : 'Device point polling disabled';

      if (mounted) {
        showSnackBarMsg(context, message);
      }
    } catch (e) {
      if (mounted) {
        showSnackBarMsg(context, 'Error toggling polling: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    final workgroup = currentWorkgroup;
    final pollingManagerState = ref.watch(pollingManagerProvider);
    final isPollingActive = pollingManagerState[workgroup.id] ?? false;

    int totalDevicesWithPoints = 0;
    int totalPoints = 0;
    for (final router in workgroup.routers) {
      for (final device in router.devices) {
        if (device.helvarType == 'output') {
          totalDevicesWithPoints++;
          totalPoints += 6;
        } else if (device.helvarType == 'input' && device.isButtonDevice) {
          totalDevicesWithPoints++;
          if (device is HelvarDriverInputDevice) {
            totalPoints += device.buttonPoints.length;
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(workgroup.description), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ExpandableListView(
              padding: const EdgeInsets.all(8.0),
              children: [
                ExpandableListItem(
                  title: 'Workgroup Details',
                  subtitle: 'Basic configuration and settings',
                  leadingIcon: Icons.info_outline,
                  leadingIconColor: Colors.blue,
                  initiallyExpanded: true,
                  detailRows: [
                    DetailRow(
                      label: 'ID',
                      value: workgroup.id,
                      showDivider: true,
                    ),
                    DetailRow(
                      label: 'Description',
                      value: workgroup.description,
                      showDivider: true,
                    ),
                    DetailRow(
                      label: 'Gateway Router IP',
                      value: workgroup.gatewayRouterIpAddress.isEmpty
                          ? 'Not set'
                          : workgroup.gatewayRouterIpAddress,
                      showDivider: true,
                    ),
                    DetailRow(
                      label: 'Refresh Props After Action',
                      value: workgroup.refreshPropsAfterAction.toString(),
                    ),
                  ],
                ),

                // Device Point Polling Configuration
                ExpandableListItem(
                  title: 'Device Point Polling',
                  subtitle: workgroup.pollEnabled
                      ? 'Active - $totalDevicesWithPoints devices, $totalPoints points'
                      : 'Disabled - No automatic point polling',
                  leadingIcon: workgroup.pollEnabled
                      ? Icons.autorenew
                      : Icons.pause_circle_outline,
                  leadingIconColor: workgroup.pollEnabled
                      ? Colors.green
                      : Colors.orange,
                  initiallyExpanded: true,
                  detailRows: [
                    DetailRow(
                      label: 'Point Polling Enabled',
                      customValue: DropdownButton<bool>(
                        value: workgroup.pollEnabled,
                        isExpanded: true,
                        onChanged: (bool? newValue) {
                          if (newValue != null) {
                            _togglePolling(newValue);
                          }
                        },
                        items: const [
                          DropdownMenuItem<bool>(
                            value: false,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.pause_circle_outline,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 8),
                                Text('Disabled'),
                              ],
                            ),
                          ),
                          DropdownMenuItem<bool>(
                            value: true,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.autorenew,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 8),
                                Text('Enabled'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      showDivider: true,
                    ),
                    StatusDetailRow(
                      label: 'Current Status',
                      statusText: isPollingActive
                          ? 'Polling Active'
                          : workgroup.pollEnabled
                          ? 'Starting Polling...'
                          : 'Disabled',
                      statusColor: isPollingActive
                          ? Colors.green
                          : workgroup.pollEnabled
                          ? Colors.orange
                          : Colors.grey,
                      showDivider: true,
                    ),
                    DetailRow(
                      label: 'Devices with Points',
                      value: '$totalDevicesWithPoints devices',
                      showDivider: true,
                    ),
                    DetailRow(
                      label: 'Total Points',
                      value: '$totalPoints points',
                      showDivider: true,
                    ),
                    if (workgroup.lastPollTime != null)
                      DetailRow(
                        label: 'Last Poll Started',
                        value: formatDateTime(workgroup.lastPollTime!),
                      ),
                  ],
                  children: [
                    // Point Polling Configuration Widget
                    PointPollingConfigWidget(workgroup: workgroup),
                  ],
                ),

                // Groups Section
                if (workgroup.groups.isNotEmpty)
                  ExpandableListItem(
                    title: 'Groups',
                    subtitle: '${workgroup.groups.length} groups configured',
                    leadingIcon: Icons.layers,
                    leadingIconColor: Colors.green,
                    children: workgroup.groups
                        .map((group) => _buildGroupItem(group))
                        .toList(),
                  ),

                // Routers Section
                if (workgroup.routers.isNotEmpty)
                  ExpandableListItem(
                    title: 'Routers and Devices',
                    subtitle:
                        '${workgroup.routers.length} routers, $totalDevicesWithPoints devices with points',
                    leadingIcon: Icons.router,
                    leadingIconColor: Colors.purple,
                    children: workgroup.routers
                        .map((router) => _buildRouterItem(router))
                        .toList(),
                  ),
              ],
            ),
    );
  }
}
