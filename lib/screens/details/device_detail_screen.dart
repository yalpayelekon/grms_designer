import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/input_device.dart';
import '../../models/helvar_models/output_device.dart';
import '../../utils/device_icons.dart';
import '../../utils/general_ui.dart';

class DeviceDetailScreen extends ConsumerStatefulWidget {
  final Workgroup workgroup;
  final HelvarRouter router;
  final HelvarDevice device;
  final Function(String,
      {Workgroup? workgroup,
      HelvarRouter? router,
      HelvarDevice? device,
      ButtonPoint? point})? onNavigate;

  const DeviceDetailScreen({
    super.key,
    required this.workgroup,
    required this.router,
    required this.device,
    this.onNavigate,
  });

  @override
  DeviceDetailScreenState createState() => DeviceDetailScreenState();
}

class DeviceDetailScreenState extends ConsumerState<DeviceDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final deviceName = widget.device.description.isEmpty
        ? 'Device ${widget.device.deviceId}'
        : widget.device.description;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.device.address} - $deviceName'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Query Real-time Status',
            onPressed: () => _showQueryDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeviceInfoCard(),
            const SizedBox(height: 16),
            _buildStaticStatusCard(),
            const SizedBox(height: 16),
            if (widget.device.helvarType == 'output')
              _buildOutputControlsCard(),
            if (widget.device is HelvarDriverInputDevice &&
                (widget.device as HelvarDriverInputDevice).isButtonDevice)
              _buildPointsCard(),
            if (widget.device.isMultisensor) _buildSensorCard(),
            if (widget.device.emergency) _buildEmergencyCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage:
                      AssetImage(getDeviceIconAsset(widget.device)),
                  backgroundColor: Colors.transparent,
                  radius: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.device.description.isEmpty
                            ? 'Device ${widget.device.deviceId}'
                            : widget.device.description,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Address: ${widget.device.address}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Device ID', widget.device.deviceId.toString()),
            _buildInfoRow('Type', widget.device.helvarType),
            _buildInfoRow('Props', widget.device.props),
            if (widget.device.deviceTypeCode != null)
              _buildInfoRow('Type Code',
                  '0x${widget.device.deviceTypeCode!.toRadixString(16)}'),
            _buildInfoRow('Emergency', widget.device.emergency ? 'Yes' : 'No'),
            _buildInfoRow('Block ID', widget.device.blockId),
            if (widget.device.sceneId.isNotEmpty)
              _buildInfoRow('Scene ID', widget.device.sceneId),
            _buildInfoRow('Fade Time', '${widget.device.fadeTime}ms'),
            if (widget.device.hexId.isNotEmpty)
              _buildInfoRow('Hex ID', widget.device.hexId),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Device Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ElevatedButton.icon(
                  onPressed: () => _showQueryDialog(),
                  icon: const Icon(Icons.cloud_download, size: 16),
                  label: const Text('Query Live Status'),
                ),
              ],
            ),
            const Divider(),
            if (widget.device.state.isNotEmpty)
              _buildInfoRow('State', widget.device.state),
            if (widget.device.deviceStateCode != null)
              _buildInfoRow('State Code',
                  '0x${widget.device.deviceStateCode!.toRadixString(16)}'),
            _buildInfoRow(
                'Button Device', widget.device.isButtonDevice ? 'Yes' : 'No'),
            _buildInfoRow(
                'Multisensor', widget.device.isMultisensor ? 'Yes' : 'No'),
            _buildInfoRow(
                'Points Created', widget.device.pointsCreated ? 'Yes' : 'No'),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputControlsCard() {
    if (widget.device.helvarType != 'output') return const SizedBox.shrink();

    final outputDevice = widget.device as HelvarDriverOutputDevice;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Output Controls',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            _buildInfoRow('Current Level', '${outputDevice.level}%'),
            _buildInfoRow('Proportion', '${outputDevice.proportion}'),
            _buildInfoRow('Missing',
                outputDevice.missing.isEmpty ? 'No' : outputDevice.missing),
            _buildInfoRow('Faulty',
                outputDevice.faulty.isEmpty ? 'No' : outputDevice.faulty),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('Direct Level'),
                  onPressed: () => _showDirectLevelDialog(),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.tune),
                  label: const Text('Direct Proportion'),
                  onPressed: () => _showDirectProportionDialog(),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.movie_creation),
                  label: const Text('Recall Scene'),
                  onPressed: () => _showRecallSceneDialog(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsCard() {
    final inputDevice = widget.device as HelvarDriverInputDevice;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Points (${inputDevice.buttonPoints.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () => _navigateToPointsDetail(),
                  child: const Text('View All'),
                ),
              ],
            ),
            const Divider(),
            if (inputDevice.buttonPoints.isEmpty)
              const Text('No points available')
            else
              ...inputDevice.buttonPoints.take(3).map(
                    (point) => ListTile(
                      leading: Icon(_getPointIcon(point)),
                      title: Text(point.name),
                      subtitle: Text(point.function),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _navigateToPointDetail(point),
                    ),
                  ),
            if (inputDevice.buttonPoints.length > 3)
              Center(
                child: TextButton(
                  onPressed: () => _navigateToPointsDetail(),
                  child: Text(
                      'View ${inputDevice.buttonPoints.length - 3} more points'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sensor Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            if (widget.device.sensorInfo.isEmpty)
              const Text('No sensor data available')
            else
              ...widget.device.sensorInfo.entries.map(
                  (entry) => _buildInfoRow(entry.key, entry.value.toString())),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            _buildInfoRow('Emergency Device', 'Yes'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.warning),
                  label: const Text('Function Test'),
                  onPressed: () => _performEmergencyFunctionTest(),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.timer),
                  label: const Text('Duration Test'),
                  onPressed: () => _performEmergencyDurationTest(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  IconData _getPointIcon(ButtonPoint point) {
    if (point.function.contains('Status') || point.name.contains('Missing')) {
      return Icons.info_outline;
    } else if (point.function.contains('IR')) {
      return Icons.settings_remote;
    } else {
      return Icons.touch_app;
    }
  }

  void _showQueryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Query Real-time Status'),
        content: const Text(
          'This will query the router for current device status. '
          'This may take a few seconds and requires an active connection to the router.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              showSnackBarMsg(context,
                  'Real-time query functionality will be implemented later');
            },
            child: const Text('Query Status'),
          ),
        ],
      ),
    );
  }

  void _navigateToPointsDetail() {
    if (widget.onNavigate != null) {
      widget.onNavigate!(
        'pointsDetail',
        workgroup: widget.workgroup,
        router: widget.router,
        device: widget.device,
      );
    } else {
      showSnackBarMsg(context, 'Points Detail navigation not available');
    }
  }

  void _navigateToPointDetail(ButtonPoint point) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(
        'pointDetail',
        workgroup: widget.workgroup,
        router: widget.router,
        device: widget.device,
        point: point,
      );
    } else {
      showSnackBarMsg(context, 'Point Detail navigation not available');
    }
  }

  void _showDirectLevelDialog() {
    showSnackBarMsg(context, 'Direct Level control coming soon');
  }

  void _showDirectProportionDialog() {
    showSnackBarMsg(context, 'Direct Proportion control coming soon');
  }

  void _showRecallSceneDialog() {
    showSnackBarMsg(context, 'Recall Scene control coming soon');
  }

  void _performEmergencyFunctionTest() {
    showSnackBarMsg(context, 'Emergency Function Test coming soon');
  }

  void _performEmergencyDurationTest() {
    showSnackBarMsg(context, 'Emergency Duration Test coming soon');
  }
}
