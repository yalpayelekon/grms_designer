import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/models/helvar_models/output_point.dart';
import 'package:grms_designer/utils/device/device_utils.dart';
import 'package:grms_designer/utils/ui/treeview_utils.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/input_device.dart';
import '../../models/helvar_models/output_device.dart';
import '../../widgets/common/detail_card.dart';
import '../../widgets/common/expandable_list_item.dart';

class SubnetDetailScreen extends ConsumerStatefulWidget {
  final Workgroup workgroup;
  final HelvarRouter router;
  final int subnetNumber;
  final List<HelvarDevice> devices;
  final Function(
    String, {
    Workgroup? workgroup,
    HelvarRouter? router,
    HelvarDevice? device,
  })?
  onNavigate;

  const SubnetDetailScreen({
    super.key,
    required this.workgroup,
    required this.router,
    required this.subnetNumber,
    required this.devices,
    this.onNavigate,
  });

  @override
  SubnetDetailScreenState createState() => SubnetDetailScreenState();
}

class SubnetDetailScreenState extends ConsumerState<SubnetDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final outputDevices = widget.devices
        .where((device) => device.helvarType == 'output')
        .toList();
    final inputDevices = widget.devices
        .where((device) => device.helvarType == 'input')
        .toList();
    final emergencyDevices = widget.devices
        .where((device) => device.emergency || device.helvarType == 'emergency')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.router.description} - Subnet ${widget.subnetNumber}',
        ),
        centerTitle: true,
      ),
      body: widget.devices.isEmpty
          ? _buildEmptyState()
          : ExpandableListView(
              padding: const EdgeInsets.all(8.0),
              children: [
                // Subnet Information
                ExpandableListItem(
                  title: 'Subnet Information',
                  subtitle:
                      'Router: ${widget.router.description} • ${widget.devices.length} devices',
                  leadingIcon: Icons.info_outline,
                  leadingIconColor: Colors.blue,
                  initiallyExpanded: true,
                  detailRows: [
                    DetailRow(
                      label: 'Subnet Number',
                      value: widget.subnetNumber.toString(),
                      showDivider: true,
                    ),
                    DetailRow(
                      label: 'Router',
                      value: widget.router.description,
                      showDivider: true,
                    ),
                    DetailRow(
                      label: 'Router IP',
                      value: widget.router.ipAddress,
                      showDivider: true,
                    ),
                    DetailRow(
                      label: 'Router Address',
                      value: widget.router.address,
                      showDivider: true,
                    ),
                    DetailRow(
                      label: 'Total Devices',
                      value: '${widget.devices.length} devices',
                      showDivider: true,
                    ),
                    DetailRow(
                      label: 'Output Devices',
                      value: '${outputDevices.length} devices',
                      showDivider: true,
                    ),
                    DetailRow(
                      label: 'Input Devices',
                      value: '${inputDevices.length} devices',
                      showDivider: true,
                    ),
                    DetailRow(
                      label: 'Emergency Devices',
                      value: '${emergencyDevices.length} devices',
                    ),
                  ],
                ),
                if (outputDevices.isNotEmpty)
                  ExpandableListItem(
                    title: 'Output Devices',
                    subtitle:
                        '${outputDevices.length} lighting and control devices',
                    leadingIcon: Icons.lightbulb_outline,
                    leadingIconColor: Colors.orange,
                    children: outputDevices
                        .map((device) => _buildDeviceItem(device, 'output'))
                        .toList(),
                  ),
                if (inputDevices.isNotEmpty)
                  ExpandableListItem(
                    title: 'Input Devices',
                    subtitle: '${inputDevices.length} sensors and controls',
                    leadingIcon: Icons.sensors,
                    leadingIconColor: Colors.green,
                    children: inputDevices
                        .map((device) => _buildDeviceItem(device, 'input'))
                        .toList(),
                  ),
                if (emergencyDevices.isNotEmpty)
                  ExpandableListItem(
                    title: 'Emergency Devices',
                    subtitle:
                        '${emergencyDevices.length} emergency lighting devices',
                    leadingIcon: Icons.warning,
                    leadingIconColor: Colors.red,
                    children: emergencyDevices
                        .map((device) => _buildDeviceItem(device, 'emergency'))
                        .toList(),
                  ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.device_unknown, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No devices found in this subnet',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceItem(HelvarDevice device, String deviceType) {
    final deviceName = device.description.isEmpty
        ? 'Device ${device.deviceId}'
        : device.description;

    // Get device-specific icon and color
    IconData deviceIcon;
    Color deviceColor;

    switch (deviceType) {
      case 'output':
        deviceIcon = Icons.lightbulb_outline;
        deviceColor = Colors.orange;
        break;
      case 'input':
        deviceIcon = device.isButtonDevice
            ? Icons.touch_app
            : device.isMultisensor
            ? Icons.sensors
            : Icons.input;
        deviceColor = Colors.green;
        break;
      case 'emergency':
        deviceIcon = Icons.warning;
        deviceColor = Colors.red;
        break;
      default:
        deviceIcon = Icons.device_hub;
        deviceColor = Colors.grey;
    }

    List<Widget> deviceChildren = [];

    if (device is HelvarDriverInputDevice && device.buttonPoints.isNotEmpty) {
      deviceChildren.add(_buildButtonPointsSection(device));
    }

    if (device is HelvarDriverOutputDevice && device.outputPoints.isNotEmpty) {
      deviceChildren.add(_buildOutputPointsSection(device));
    }

    if (device.isMultisensor || device.isButtonDevice || device.emergency) {
      deviceChildren.add(_buildCapabilitiesSection(device));
    }

    return ExpandableListItem(
      title: deviceName,
      subtitle: 'Address: ${device.address} • Type: ${device.helvarType}',
      leadingIcon: deviceIcon,
      leadingIconColor: deviceColor,
      indentLevel: 1,

      detailRows: [
        DetailRow(
          label: 'Device ID',
          value: device.deviceId.toString(),
          showDivider: true,
        ),
        DetailRow(label: 'Address', value: device.address, showDivider: true),
        DetailRow(label: 'Type', value: device.helvarType, showDivider: true),
        DetailRow(
          label: 'Props',
          value: device.props.isEmpty ? 'No properties' : device.props,
          showDivider: true,
        ),
        if (device.state.isNotEmpty)
          DetailRow(label: 'State', value: device.state, showDivider: true),
        if (device.deviceTypeCode != null)
          DetailRow(
            label: 'Type Code',
            value: '0x${device.deviceTypeCode!.toRadixString(16)}',
            showDivider: true,
          ),
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
      children: deviceChildren,
    );
  }

  Widget _buildButtonPointsSection(HelvarDriverInputDevice device) {
    return ExpandableListItem(
      title: 'Button Points',
      subtitle: '${device.buttonPoints.length} input points',
      leadingIcon: Icons.touch_app,
      leadingIconColor: Colors.blue,
      indentLevel: 2,
      children: device.buttonPoints
          .map((point) => _buildButtonPointItem(point))
          .toList(),
    );
  }

  Widget _buildButtonPointItem(ButtonPoint point) {
    return ExpandableListItem(
      title: point.name.split('_').last,
      leadingIcon:
          point.function.contains('Status') || point.name.contains('Missing')
          ? Icons.info_outline
          : point.function.contains('IR')
          ? Icons.settings_remote
          : Icons.touch_app,
      leadingIconColor:
          point.function.contains('Status') || point.name.contains('Missing')
          ? Colors.orange
          : point.function.contains('IR')
          ? Colors.purple
          : Colors.blue,
      indentLevel: 3,
      detailRows: [
        DetailRow(label: 'Point Name', value: point.name, showDivider: true),
        DetailRow(label: 'Function', value: point.function, showDivider: true),
        DetailRow(label: 'Button ID', value: point.buttonId.toString()),
      ],
    );
  }

  Widget _buildOutputPointsSection(HelvarDriverOutputDevice device) {
    if (device.outputPoints.isEmpty) {
      device.generateOutputPoints();
    }

    return ExpandableListItem(
      title: 'Output Points',
      subtitle: '${device.outputPoints.length} output points',
      leadingIcon: Icons.output,
      leadingIconColor: Colors.orange,
      indentLevel: 2,
      children: device.outputPoints
          .map((point) => _buildOutputPointItem(point))
          .toList(),
    );
  }

  Widget _buildOutputPointItem(OutputPoint outputPoint) {
    return ExpandableListItem(
      title: outputPoint.function,
      subtitle: 'ID: ${outputPoint.pointId} • Type: ${outputPoint.pointType}',
      leadingIcon: getOutputPointIcon(outputPoint),
      leadingIconColor: getOutputPointColor(outputPoint),
      indentLevel: 3,
      detailRows: [
        DetailRow(
          label: 'Point Name',
          value: outputPoint.name,
          showDivider: true,
        ),
        DetailRow(
          label: 'Function',
          value: outputPoint.function,
          showDivider: true,
        ),
        DetailRow(
          label: 'Point Type',
          value: outputPoint.pointType,
          showDivider: true,
        ),
        DetailRow(
          label: 'Current Value',
          value: formatOutputPointValue(outputPoint),
        ),
      ],
    );
  }

  Widget _buildCapabilitiesSection(HelvarDevice device) {
    List<DetailRow> capabilities = [];

    if (device.isMultisensor && device.sensorInfo.isNotEmpty) {
      capabilities.add(
        DetailRow(
          label: 'Sensor Capabilities',
          value: '${device.sensorInfo.length} sensors',
          showDivider: true,
        ),
      );

      for (var entry in device.sensorInfo.entries) {
        capabilities.add(
          DetailRow(
            label: '  ${entry.key}',
            value: entry.value.toString(),
            showDivider: entry != device.sensorInfo.entries.last,
          ),
        );
      }
    }

    if (device.isButtonDevice) {
      capabilities.add(
        DetailRow(
          label: 'Button Capability',
          value: 'Input control device',
          showDivider: device.isMultisensor,
        ),
      );
    }

    if (device.emergency) {
      capabilities.add(
        const DetailRow(
          label: 'Emergency Function',
          value: 'Emergency lighting device',
        ),
      );
    }

    if (capabilities.isEmpty) {
      return const SizedBox.shrink();
    }

    return ExpandableListItem(
      title: 'Device Capabilities',
      subtitle: 'Special features and sensors',
      leadingIcon: Icons.featured_play_list,
      leadingIconColor: Colors.indigo,
      indentLevel: 2,
      detailRows: capabilities,
    );
  }
}
