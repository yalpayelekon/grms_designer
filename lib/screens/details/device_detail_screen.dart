// File: lib/screens/details/device_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/input_device.dart';
import '../../models/helvar_models/output_device.dart';
import '../../utils/device_icons.dart';
import '../../utils/general_ui.dart';
import '../../utils/logger.dart';
import '../../providers/router_connection_provider.dart';
import '../../protocol/query_commands.dart';
import '../../protocol/protocol_parser.dart';
import '../../comm/models/command_models.dart';

class DeviceDetailScreen extends ConsumerStatefulWidget {
  final Workgroup workgroup;
  final HelvarRouter router;
  final HelvarDevice device;

  const DeviceDetailScreen({
    super.key,
    required this.workgroup,
    required this.router,
    required this.device,
  });

  @override
  DeviceDetailScreenState createState() => DeviceDetailScreenState();
}

class DeviceDetailScreenState extends ConsumerState<DeviceDetailScreen> {
  bool _isRefreshing = false;
  Map<String, String> _deviceStatus = {};
  String? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    _refreshDeviceStatus();
  }

  @override
  Widget build(BuildContext context) {
    final deviceName = widget.device.description.isEmpty
        ? 'Device ${widget.device.deviceId}'
        : widget.device.description;

    return Scaffold(
      appBar: AppBar(
        title: Text(deviceName),
        leading: Text('${widget.device.address} - ${widget.device.helvarType}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh Status',
            onPressed: _isRefreshing ? null : _refreshDeviceStatus,
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
            _buildStatusCard(),
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

  Widget _buildStatusCard() {
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
                  'Real-time Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_lastRefreshTime != null)
                  Text(
                    'Last updated: $_lastRefreshTime',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const Divider(),
            if (_deviceStatus.isEmpty && !_isRefreshing)
              const Text('No status data available')
            else if (_isRefreshing)
              const Center(child: CircularProgressIndicator())
            else
              ..._deviceStatus.entries
                  .map((entry) => _buildInfoRow(entry.key, entry.value)),
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

  Future<void> _refreshDeviceStatus() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final commandService = ref.read(routerCommandServiceProvider);
      final deviceAddress = widget.device.address;

      // Query device state
      final stateCommand = HelvarNetCommands.queryDeviceState(deviceAddress);
      final stateResult = await commandService.sendCommand(
        widget.router.ipAddress,
        stateCommand,
        priority: CommandPriority.high,
      );

      Map<String, String> newStatus = {};

      if (stateResult.success && stateResult.response != null) {
        final stateValue =
            ProtocolParser.extractResponseValue(stateResult.response!);
        if (stateValue != null) {
          final stateCode = int.tryParse(stateValue);
          if (stateCode != null) {
            newStatus['Device State'] = 'Code: $stateCode';
            // You can add more detailed state parsing here
          }
        }
      }

      // Query load level for output devices
      if (widget.device.helvarType == 'output') {
        final levelCommand = HelvarNetCommands.queryLoadLevel(deviceAddress);
        final levelResult = await commandService.sendCommand(
          widget.router.ipAddress,
          levelCommand,
          priority: CommandPriority.high,
        );

        if (levelResult.success && levelResult.response != null) {
          final levelValue =
              ProtocolParser.extractResponseValue(levelResult.response!);
          if (levelValue != null) {
            newStatus['Load Level'] = '$levelValue%';
          }
        }
      }

      // Query device type for confirmation
      final typeCommand = HelvarNetCommands.queryDeviceType(deviceAddress);
      final typeResult = await commandService.sendCommand(
        widget.router.ipAddress,
        typeCommand,
        priority: CommandPriority.high,
      );

      if (typeResult.success && typeResult.response != null) {
        final typeValue =
            ProtocolParser.extractResponseValue(typeResult.response!);
        if (typeValue != null) {
          newStatus['Device Type Code'] = typeValue;
        }
      }

      setState(() {
        _deviceStatus = newStatus;
        _lastRefreshTime = DateTime.now().toString().substring(11, 19);
      });
    } catch (e) {
      logError('Error refreshing device status: $e');
      if (mounted) {
        showSnackBarMsg(context, 'Error refreshing device status: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _navigateToPointsDetail() {
    // TODO: Navigate to points detail page
    showSnackBarMsg(context, 'Points Detail page will be implemented next');
  }

  void _navigateToPointDetail(ButtonPoint point) {
    // TODO: Navigate to individual point detail page
    showSnackBarMsg(context, 'Point Detail page will be implemented next');
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
