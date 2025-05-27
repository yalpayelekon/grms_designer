import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../utils/device_icons.dart';
import '../../utils/general_ui.dart';

class SubnetDetailScreen extends ConsumerStatefulWidget {
  final Workgroup workgroup;
  final HelvarRouter router;
  final int subnetNumber;
  final List<HelvarDevice> devices;
  final Function(String,
      {Workgroup? workgroup,
      HelvarRouter? router,
      HelvarDevice? device})? onNavigate;

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
    return Scaffold(
      appBar: AppBar(
        leading:
            Text('${widget.router.description} Subnet ${widget.subnetNumber}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Devices',
            onPressed: _refreshDevices,
          ),
        ],
      ),
      body: widget.devices.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.device_unknown,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No devices found in this subnet',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            )
          : _buildDevicesList(),
    );
  }

  Widget _buildDevicesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: widget.devices.length,
      itemBuilder: (context, index) {
        final device = widget.devices[index];
        return _buildDeviceCard(device);
      },
    );
  }

  Widget _buildDeviceCard(HelvarDevice device) {
    final deviceName = device.description.isEmpty
        ? 'Device ${device.deviceId}'
        : device.description;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(getDeviceIconAsset(device)),
              backgroundColor: Colors.transparent,
            ),
            title: Text(
              deviceName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Address: ${device.address}'),
                Text('Type: ${device.helvarType}'),
                if (device.state.isNotEmpty) Text('State: ${device.state}'),
              ],
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (device.emergency)
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                if (device.isButtonDevice)
                  const Icon(Icons.touch_app, color: Colors.blue, size: 20),
                if (device.isMultisensor)
                  const Icon(Icons.sensors, color: Colors.green, size: 20),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
            onTap: () => _navigateToDeviceDetail(device),
          ),
          if (device.helvarType == 'output')
            Padding(
              padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.power_settings_new, size: 16),
                    label: const Text('Control'),
                    onPressed: () => _showDeviceControls(device),
                  ),
                ],
              ),
            ),
        ],
      ),
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
    } else {
      showSnackBarMsg(context, 'Device Detail navigation not available');
    }
  }

  void _showDeviceControls(HelvarDevice device) {
    // Show quick device controls
    showSnackBarMsg(context, 'Device controls coming soon');
  }

  void _refreshDevices() {
    // TODO: Implement device refresh functionality
    showSnackBarMsg(context, 'Refresh functionality coming soon');
  }
}
