import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/input_device.dart';
import '../../models/helvar_models/output_device.dart';
import '../../utils/device_icons.dart';
import '../../utils/general_ui.dart';
import '../../protocol/query_commands.dart';
import '../../protocol/protocol_parser.dart';
import '../../protocol/protocol_constants.dart';
import '../../providers/router_connection_provider.dart';
import '../../utils/logger.dart';

class DeviceDetailScreen extends ConsumerStatefulWidget {
  final Workgroup workgroup;
  final HelvarRouter router;
  final HelvarDevice device;
  final Function(
    String, {
    Workgroup? workgroup,
    HelvarRouter? router,
    HelvarDevice? device,
    ButtonPoint? point,
  })?
  onNavigate;

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
                  backgroundImage: AssetImage(
                    getDeviceIconAsset(widget.device),
                  ),
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
              _buildInfoRow(
                'Type Code',
                '0x${widget.device.deviceTypeCode!.toRadixString(16)}',
              ),
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
              _buildInfoRow(
                'State Code',
                '0x${widget.device.deviceStateCode!.toRadixString(16)}',
              ),
            _buildInfoRow(
              'Button Device',
              widget.device.isButtonDevice ? 'Yes' : 'No',
            ),
            _buildInfoRow(
              'Multisensor',
              widget.device.isMultisensor ? 'Yes' : 'No',
            ),
            _buildInfoRow(
              'Points Created',
              widget.device.pointsCreated ? 'Yes' : 'No',
            ),

            if (widget.device is HelvarDriverOutputDevice)
              ..._buildOutputDeviceStatus(),

            if (widget.device is HelvarDriverInputDevice)
              ..._buildInputDeviceStatus(),

            _buildInfoRow('Last Updated', _getLastUpdateTime()),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOutputDeviceStatus() {
    final outputDevice = widget.device as HelvarDriverOutputDevice;
    return [
      const SizedBox(height: 8),
      Text(
        'Output Status',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
      const SizedBox(height: 4),
      _buildInfoRow('Current Level', '${outputDevice.level}%'),
      _buildInfoRow('Proportion', '${outputDevice.proportion}'),
      _buildInfoRow(
        'Missing',
        outputDevice.missing.isEmpty ? 'No' : outputDevice.missing,
      ),
      _buildInfoRow(
        'Faulty',
        outputDevice.faulty.isEmpty ? 'No' : outputDevice.faulty,
      ),
    ];
  }

  List<Widget> _buildInputDeviceStatus() {
    final inputDevice = widget.device as HelvarDriverInputDevice;
    List<Widget> widgets = [];

    widgets.add(const SizedBox(height: 8));
    widgets.add(
      Text(
        'Input Status',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.green[700],
        ),
      ),
    );
    widgets.add(const SizedBox(height: 4));

    if (inputDevice.isButtonDevice) {
      widgets.add(
        _buildInfoRow('Button Points', '${inputDevice.buttonPoints.length}'),
      );
    }

    if (inputDevice.isMultisensor) {
      widgets.add(
        _buildInfoRow(
          'Sensor Capabilities',
          '${inputDevice.sensorInfo.length}',
        ),
      );
      inputDevice.sensorInfo.forEach((key, value) {
        widgets.add(_buildInfoRow('  $key', value.toString()));
      });
    }

    return widgets;
  }

  String _getLastUpdateTime() {
    return DateTime.now().toString().substring(11, 19);
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
          Expanded(child: Text(value)),
        ],
      ),
    );
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
              _queryRealTimeStatus();
            },
            child: const Text('Query Status'),
          ),
        ],
      ),
    );
  }

  Future<void> _queryRealTimeStatus() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Querying device status...'),
          ],
        ),
      ),
    );

    try {
      if (widget.device is HelvarDriverOutputDevice) {
        await _queryOutputDevice();
      } else if (widget.device is HelvarDriverInputDevice) {
        await _queryInputDevice();
      } else {
        await _queryBasicDeviceStatus();
      }

      if (mounted) {
        Navigator.of(context).pop();
        setState(() {});
        showSnackBarMsg(context, 'Device status updated successfully');
      }
    } catch (e) {
      logError('Error querying device status: $e');
      if (mounted) {
        Navigator.of(context).pop();
        showSnackBarMsg(context, 'Error querying device status: $e');
      }
    }
  }

  Future<void> _queryOutputDevice() async {
    final deviceQueryService = ref.read(deviceQueryServiceProvider);
    final outputDevice = widget.device as HelvarDriverOutputDevice;

    final success = await deviceQueryService.queryOutputDevicePoints(
      widget.router.ipAddress,
      outputDevice,
    );

    if (!success) {
      throw Exception('Failed to query output device points');
    }

    logInfo('Successfully queried output device: ${widget.device.address}');
  }

  Future<void> _queryInputDevice() async {
    await _queryBasicDeviceStatus();

    final inputDevice = widget.device as HelvarDriverInputDevice;
    logInfo('Successfully queried input device: ${inputDevice.address}');

    if (inputDevice.isButtonDevice) {
      logInfo('Button device detected - button points available');
    }

    if (inputDevice.isMultisensor) {
      logInfo('Multisensor detected - sensor data available');
    }
  }

  Future<void> _queryBasicDeviceStatus() async {
    final commandService = ref.read(routerCommandServiceProvider);

    final stateCommand = HelvarNetCommands.queryDeviceState(
      widget.device.address,
    );
    final stateResult = await commandService.sendCommand(
      widget.router.ipAddress,
      stateCommand,
    );

    if (stateResult.success && stateResult.response != null) {
      final stateValue = ProtocolParser.extractResponseValue(
        stateResult.response!,
      );
      if (stateValue != null) {
        final stateCode = int.tryParse(stateValue) ?? 0;
        widget.device.deviceStateCode = stateCode;
        widget.device.state = getStateFlagsDescription(stateCode);
        logInfo('Device ${widget.device.address} state updated: $stateCode');
      }
    }

    if (widget.device.deviceTypeCode == null) {
      final typeCommand = HelvarNetCommands.queryDeviceType(
        widget.device.address,
      );
      final typeResult = await commandService.sendCommand(
        widget.router.ipAddress,
        typeCommand,
      );

      if (typeResult.success && typeResult.response != null) {
        final typeValue = ProtocolParser.extractResponseValue(
          typeResult.response!,
        );
        if (typeValue != null) {
          final typeCode = int.tryParse(typeValue) ?? 0;
          widget.device.deviceTypeCode = typeCode;
          logInfo('Device ${widget.device.address} type updated: $typeCode');
        }
      }
    }
  }
}
