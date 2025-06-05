import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../widgets/common/detail_card.dart';
import '../../widgets/common/expandable_list_item.dart';
import 'device_detail_screen.dart';

class SubnetDetailScreen extends ConsumerStatefulWidget {
  final Workgroup workgroup;
  final HelvarRouter router;
  final int subnetNumber;
  final List<HelvarDevice> devices;
  final bool asWidget;
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
    this.asWidget = false,
    this.onNavigate,
  });

  @override
  SubnetDetailScreenState createState() => SubnetDetailScreenState();
}

class SubnetDetailScreenState extends ConsumerState<SubnetDetailScreen> {
  Widget _buildSubnetInfo() {
    final outputDevices = widget.devices
        .where((device) => device.helvarType == 'output')
        .toList();
    final inputDevices = widget.devices
        .where((device) => device.helvarType == 'input')
        .toList();
    final emergencyDevices = widget.devices
        .where((device) => device.emergency || device.helvarType == 'emergency')
        .toList();

    return ExpandableListItem(
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
    );
  }

  Widget _buildDevicesSection() {
    final outputDevices = widget.devices
        .where((device) => device.helvarType == 'output')
        .toList();
    final inputDevices = widget.devices
        .where((device) => device.helvarType == 'input')
        .toList();
    final emergencyDevices = widget.devices
        .where((device) => device.emergency || device.helvarType == 'emergency')
        .toList();

    List<Widget> sections = [];

    if (outputDevices.isNotEmpty) {
      sections.add(
        ExpandableListItem(
          title: 'Output Devices',
          subtitle: '${outputDevices.length} lighting and control devices',
          leadingIcon: Icons.lightbulb_outline,
          leadingIconColor: Colors.orange,
          lazyChildren: () => outputDevices
              .map((device) => _buildDeviceItem(device, 'output'))
              .toList(),
        ),
      );
    }

    if (inputDevices.isNotEmpty) {
      sections.add(
        ExpandableListItem(
          title: 'Input Devices',
          subtitle: '${inputDevices.length} sensors and controls',
          leadingIcon: Icons.sensors,
          leadingIconColor: Colors.green,
          lazyChildren: () => inputDevices
              .map((device) => _buildDeviceItem(device, 'input'))
              .toList(),
        ),
      );
    }

    if (emergencyDevices.isNotEmpty) {
      sections.add(
        ExpandableListItem(
          title: 'Emergency Devices',
          subtitle: '${emergencyDevices.length} emergency lighting devices',
          leadingIcon: Icons.warning,
          leadingIconColor: Colors.red,
          lazyChildren: () => emergencyDevices
              .map((device) => _buildDeviceItem(device, 'emergency'))
              .toList(),
        ),
      );
    }

    return Column(children: sections);
  }

  Widget _buildDeviceItem(HelvarDevice device, String deviceType) {
    final deviceName = device.description.isEmpty
        ? 'Device ${device.deviceId}'
        : device.description;

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

    return ExpandableListItem(
      title: deviceName,
      subtitle: 'Address: ${device.address} • Type: ${device.helvarType}',
      leadingIcon: deviceIcon,
      leadingIconColor: deviceColor,
      indentLevel: 1,
      lazyChildren: () => [
        DeviceDetailScreen(
          workgroup: widget.workgroup,
          router: widget.router,
          device: device,
          asWidget: true,
        ),
      ],
      onSecondaryTap: () => _navigateToDeviceDetail(device),
    );
  }

  void _navigateToDeviceDetail(HelvarDevice device) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(
        'deviceDetail',
        workgroup: widget.workgroup,
        router: widget.router,
        device: device,
      );
    }
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

  Widget _buildContent() {
    if (widget.devices.isEmpty) {
      return _buildEmptyState();
    }

    if (widget.asWidget) {
      return _buildDevicesSection();
    }

    return ExpandableListView(
      padding: const EdgeInsets.all(8.0),
      children: [_buildSubnetInfo(), _buildDevicesSection()],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.asWidget) {
      return _buildContent();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.router.description} - Subnet ${widget.subnetNumber}',
        ),
        centerTitle: true,
      ),
      body: _buildContent(),
    );
  }
}
