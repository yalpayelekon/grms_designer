import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/utils/date_utils.dart';
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
  late TextEditingController _deviceIdController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _deviceIdController = TextEditingController(
      text: widget.device.deviceId.toString(),
    );
    _addressController = TextEditingController(text: widget.device.address);
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceName = widget.device.description.isEmpty
        ? 'Device ${widget.device.deviceId}'
        : widget.device.description;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.device.address} - $deviceName'),
        centerTitle: true,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: ElevatedButton.icon(
        onPressed: () => _queryRealTimeStatus(),
        icon: const Icon(Icons.refresh, size: 16),
        label: const Text('Query Live Status'),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 120,
                              child: Text(
                                'Device ID:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _deviceIdController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                ),
                                onFieldSubmitted: (val) => _updateDeviceId(val),
                                onChanged: (val) {},
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 120,
                              child: Text(
                                'Address:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _addressController,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                ),
                                onFieldSubmitted: (val) =>
                                    _updateDeviceAddress(val),
                                onChanged: (val) {},
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            buildInfoRow('Type', widget.device.helvarType),
            buildInfoRow('Props', widget.device.props),
            if (widget.device.deviceTypeCode != null)
              buildInfoRow(
                'Type Code',
                '0x${widget.device.deviceTypeCode!.toRadixString(16)}',
              ),
            buildInfoRow('Emergency', widget.device.emergency ? 'Yes' : 'No'),
            buildInfoRow('Block ID', widget.device.blockId),
            if (widget.device.sceneId.isNotEmpty)
              buildInfoRow('Scene ID', widget.device.sceneId),
          ],
        ),
      ),
    );
  }

  void _updateDeviceId(String val) {
    final id = int.tryParse(val);
    if (id != null && id > 0) {
      setState(() {
        widget.device.deviceId = id;
      });
      logInfo("Device ID updated");
    } else {
      showSnackBarMsg(context, "Invalid Device ID");
    }
  }

  void _updateDeviceAddress(String val) {
    setState(() {
      widget.device.address = val;
    });
    logInfo("Address updated");
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
              ],
            ),
            const Divider(),
            if (widget.device.state.isNotEmpty)
              buildInfoRow('State', widget.device.state),
            if (widget.device.deviceStateCode != null)
              buildInfoRow(
                'State Code',
                '0x${widget.device.deviceStateCode!.toRadixString(16)}',
              ),
            buildInfoRow(
              'Button Device',
              widget.device.isButtonDevice ? 'Yes' : 'No',
            ),
            buildInfoRow(
              'Multisensor',
              widget.device.isMultisensor ? 'Yes' : 'No',
            ),

            if (widget.device is HelvarDriverOutputDevice)
              ..._buildOutputDeviceStatus(),

            if (widget.device is HelvarDriverInputDevice)
              ..._buildInputDeviceStatus(),

            buildInfoRow('Last Updated', getLastUpdateTime()),
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
      buildInfoRow('Current Level', '${outputDevice.level}%'),
      buildInfoRow('Proportion', '${outputDevice.proportion}'),
      buildInfoRow(
        'Missing',
        outputDevice.missing.isEmpty ? 'No' : outputDevice.missing,
      ),
      buildInfoRow(
        'Faulty',
        outputDevice.faulty.isEmpty ? 'No' : outputDevice.faulty,
      ),
      buildInfoRow(
        'Power Consumption',
        '${outputDevice.powerConsumption.toStringAsFixed(1)}W',
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
        buildInfoRow('Button Points', '${inputDevice.buttonPoints.length}'),
      );
    }

    if (inputDevice.isMultisensor) {
      widgets.add(
        buildInfoRow('Sensor Capabilities', '${inputDevice.sensorInfo.length}'),
      );
      inputDevice.sensorInfo.forEach((key, value) {
        widgets.add(buildInfoRow('  $key', value.toString()));
      });
    }

    return widgets;
  }

  Future<void> _queryRealTimeStatus() async {
    try {
      if (widget.device is HelvarDriverOutputDevice) {
        await _queryOutputDevice();
      } else if (widget.device is HelvarDriverInputDevice) {
        await _queryInputDevice();
      } else {
        await _queryBasicDeviceStatus();
      }

      if (mounted) {
        setState(() {});
        logInfo('Device status updated successfully');
      }
    } catch (e) {
      logError('Error querying device status: $e');
      if (mounted) {
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
