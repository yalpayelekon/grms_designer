import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/providers/centralized_polling_provider.dart';
import 'package:grms_designer/services/polling/polling_task.dart';
import 'package:grms_designer/utils/core/date_utils.dart';
import 'package:grms_designer/utils/device/device_utils.dart';
import 'package:grms_designer/utils/ui/ui_helpers.dart';
import 'package:grms_designer/widgets/common/detail_card.dart';
import 'package:grms_designer/widgets/common/expandable_list_item.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/input_device.dart';
import '../../models/helvar_models/output_device.dart';
import '../../models/helvar_models/output_point.dart';
import '../../utils/ui/treeview_utils.dart';
import '../../protocol/query_commands.dart';
import '../../protocol/protocol_parser.dart';
import '../../protocol/protocol_constants.dart';
import '../../providers/router_connection_provider.dart';
import '../../utils/core/logger.dart';

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
  bool _devicePollingEnabled = false;
  @override
  void initState() {
    super.initState();
    _deviceIdController = TextEditingController(
      text: widget.device.deviceId.toString(),
    );
    _addressController = TextEditingController(text: widget.device.address);

    if (widget.device is HelvarDriverOutputDevice) {
      final outputDevice = widget.device as HelvarDriverOutputDevice;
      if (outputDevice.outputPoints.isEmpty) {
        outputDevice.generateOutputPoints();
      }
    }
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
        actions: [
          ElevatedButton.icon(
            onPressed: () => _queryRealTimeStatus(),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Query Live Status'),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(_devicePollingEnabled ? Icons.pause : Icons.play_arrow),
            tooltip: _devicePollingEnabled
                ? 'Stop Device Polling'
                : 'Start Device Polling',
            onPressed: _toggleDevicePolling,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: DetailRowsList(
          children: [
            ..._buildBasicDeviceRows(),
            ..._buildDeviceStatusRows(),
            if (_hasPoints()) _buildPointsSection(),
            ExpandableListItem(
              title: 'Device Status Polling',
              subtitle: widget.workgroup.pollEnabled
                  ? 'Active - Groups being polled automatically'
                  : 'Disabled - No automatic polling',
              leadingIcon: widget.workgroup.pollEnabled
                  ? Icons.autorenew
                  : Icons.pause_circle_outline,
              leadingIconColor: widget.workgroup.pollEnabled
                  ? Colors.green
                  : Colors.orange,
              initiallyExpanded: true,
              detailRows: [
                DetailRow(
                  label: 'Polling Enabled',
                  customValue: DropdownButton<bool>(
                    value:
                        _isDevicePollingActive(), // Use the active state instead of workgroup setting
                    isExpanded: true,
                    onChanged: (bool? newValue) {
                      if (newValue != null) {
                        _toggleDevicePolling();
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
                  statusText: _isDevicePollingActive()
                      ? 'Polling Active'
                      : 'Disabled',
                  statusColor: _isDevicePollingActive()
                      ? Colors.green
                      : Colors.grey,
                  showDivider: true,
                ),
                DetailRow(
                  label: 'Active Groups',
                  value: '${widget.workgroup.groups.length} groups',
                  showDivider: true,
                ),
                if (widget.workgroup.lastPollTime != null)
                  DetailRow(
                    label: 'Last Poll Started',
                    value: getLastUpdateTime(
                      dateTime: widget.workgroup.lastPollTime!,
                    ),
                    showDivider: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isDevicePollingActive() {
    final pollingTasks = ref.watch(pollingTasksProvider);
    final deviceTaskId =
        'device_status_${widget.router.address}_${widget.device.address}';
    final taskInfo = pollingTasks[deviceTaskId];
    return taskInfo?.state == PollingTaskState.running;
  }

  void _toggleDevicePolling() async {
    final pollingManager = ref.read(pollingManagerProvider.notifier);
    final isCurrentlyActive = _isDevicePollingActive();

    if (isCurrentlyActive) {
      pollingManager.stopDevicePolling(
        widget.router.address,
        widget.device.address,
      );
    } else {
      await pollingManager.startDevicePolling(
        widget.workgroup.id,
        widget.router.address,
        widget.device.address,
        interval: const Duration(minutes: 2),
      );
    }
  }

  List<Widget> _buildBasicDeviceRows() {
    return [
      EditableDetailRow(
        label: 'Device ID',
        controller: _deviceIdController,
        keyboardType: TextInputType.number,
        onSubmitted: _updateDeviceId,
        showDivider: true,
      ),
      EditableDetailRow(
        label: 'Address',
        controller: _addressController,
        onSubmitted: _updateDeviceAddress,
        showDivider: true,
      ),
      DetailRow(
        label: 'Description',
        value: widget.device.description.isEmpty
            ? 'No description'
            : widget.device.description,
        showDivider: true,
      ),
      DetailRow(
        label: 'Type',
        value: widget.device.helvarType,
        showDivider: true,
      ),
      DetailRow(
        label: 'Props',
        value: widget.device.props.isEmpty
            ? 'No properties'
            : widget.device.props,
        showDivider: true,
      ),
      if (widget.device.deviceTypeCode != null)
        DetailRow(
          label: 'Type Code',
          value: '0x${widget.device.deviceTypeCode!.toRadixString(16)}',
          showDivider: true,
        ),
      DetailRow(
        label: 'Block ID',
        value: widget.device.blockId,
        showDivider: true,
      ),
      if (widget.device.sceneId.isNotEmpty)
        DetailRow(
          label: 'Scene ID',
          value: widget.device.sceneId,
          showDivider: true,
        ),
      if (widget.device.hexId.isNotEmpty)
        DetailRow(
          label: 'Hex ID',
          value: widget.device.hexId,
          showDivider: true,
        ),
    ];
  }

  List<Widget> _buildDeviceStatusRows() {
    List<Widget> statusRows = [];

    if (widget.device.state.isNotEmpty) {
      statusRows.add(
        DetailRow(
          label: 'State',
          value: widget.device.state,
          showDivider: true,
        ),
      );
    }

    if (widget.device.deviceStateCode != null) {
      statusRows.add(
        DetailRow(
          label: 'State Code',
          value: '0x${widget.device.deviceStateCode!.toRadixString(16)}',
          showDivider: true,
        ),
      );
    }

    statusRows.addAll([
      StatusDetailRow(
        label: 'Emergency',
        statusText: widget.device.emergency ? 'Yes' : 'No',
        statusColor: widget.device.emergency ? Colors.red : Colors.green,
        showDivider: true,
      ),
      StatusDetailRow(
        label: 'Button Device',
        statusText: widget.device.isButtonDevice ? 'Yes' : 'No',
        statusColor: widget.device.isButtonDevice ? Colors.blue : Colors.grey,
        showDivider: true,
      ),
      StatusDetailRow(
        label: 'Multisensor',
        statusText: widget.device.isMultisensor ? 'Yes' : 'No',
        statusColor: widget.device.isMultisensor ? Colors.green : Colors.grey,
        showDivider: true,
      ),
    ]);

    if (widget.device is HelvarDriverOutputDevice) {
      final outputDevice = widget.device as HelvarDriverOutputDevice;
      statusRows.addAll([
        DetailRow(
          label: 'Current Level',
          value: '${outputDevice.level}%',
          showDivider: true,
        ),
        DetailRow(
          label: 'Proportion',
          value: '${outputDevice.proportion}',
          showDivider: true,
        ),
        DetailRow(
          label: 'Missing',
          value: outputDevice.missing.isEmpty ? 'No' : outputDevice.missing,
          showDivider: true,
        ),
        DetailRow(
          label: 'Faulty',
          value: outputDevice.faulty.isEmpty ? 'No' : outputDevice.faulty,
          showDivider: true,
        ),
        DetailRow(
          label: 'Power Consumption',
          value: '${outputDevice.powerConsumption.toStringAsFixed(1)}W',
          showDivider: true,
        ),
      ]);
    }

    if (widget.device is HelvarDriverInputDevice) {
      final inputDevice = widget.device as HelvarDriverInputDevice;

      if (inputDevice.isButtonDevice) {
        statusRows.add(
          DetailRow(
            label: 'Button Points',
            value: '${inputDevice.buttonPoints.length}',
            showDivider: true,
          ),
        );
      }

      if (inputDevice.isMultisensor && inputDevice.sensorInfo.isNotEmpty) {
        statusRows.add(
          DetailRow(
            label: 'Sensor Capabilities',
            value: '${inputDevice.sensorInfo.length}',
            showDivider: true,
          ),
        );

        inputDevice.sensorInfo.forEach((key, value) {
          statusRows.add(
            DetailRow(
              label: '  $key',
              value: value.toString(),
              showDivider: true,
            ),
          );
        });
      }
    }

    statusRows.add(
      DetailRow(
        label: 'Last Updated',
        value: getLastUpdateTime(),
        showDivider: _hasPoints(),
      ),
    );

    return statusRows;
  }

  bool _hasPoints() {
    if (widget.device is HelvarDriverInputDevice) {
      final inputDevice = widget.device as HelvarDriverInputDevice;
      return inputDevice.buttonPoints.isNotEmpty;
    } else if (widget.device is HelvarDriverOutputDevice) {
      final outputDevice = widget.device as HelvarDriverOutputDevice;
      return outputDevice.outputPoints.isNotEmpty;
    }
    return false;
  }

  Widget _buildPointsSection() {
    return ExpandableListItem(
      title: 'Points',
      leadingIcon: widget.device is HelvarDriverInputDevice
          ? Icons.input
          : Icons.output,
      leadingIconColor: widget.device is HelvarDriverInputDevice
          ? Colors.green
          : Colors.orange,
      children: widget.device is HelvarDriverInputDevice
          ? _buildInputPointsList()
          : _buildOutputPointsList(),
    );
  }

  List<Widget> _buildInputPointsList() {
    final inputDevice = widget.device as HelvarDriverInputDevice;
    return inputDevice.buttonPoints
        .map((point) => _buildInputPointItem(point))
        .toList();
  }

  List<Widget> _buildOutputPointsList() {
    final outputDevice = widget.device as HelvarDriverOutputDevice;
    return outputDevice.outputPoints
        .map((point) => _buildOutputPointItem(point))
        .toList();
  }

  Widget _buildInputPointItem(ButtonPoint point) {
    return ExpandableListItem(
      title: getButtonPointDisplayName(point),
      subtitle: 'Function: ${point.function} • ID: ${point.buttonId}',
      leadingIcon: getButtonPointIcon(point),
      leadingIconColor: _getInputPointColor(point),
      indentLevel: 1,
      detailRows: [
        DetailRow(label: 'Point Name', value: point.name, showDivider: true),
        DetailRow(
          label: 'Function Type',
          value: point.function,
          showDivider: true,
        ),
        DetailRow(
          label: 'Button ID',
          value: point.buttonId.toString(),
          showDivider: true,
        ),
        DetailRow(label: 'Point Type', value: getPointTypeDescription(point)),
      ],
    );
  }

  Widget _buildOutputPointItem(OutputPoint point) {
    return ExpandableListItem(
      title: point.function,
      subtitle: 'Type: ${point.pointType} • ID: ${point.pointId}',
      leadingIcon: getOutputPointIcon(point),
      leadingIconColor: getOutputPointColor(point),
      indentLevel: 1,
      detailRows: [
        DetailRow(label: 'Point Name', value: point.name, showDivider: true),
        DetailRow(label: 'Function', value: point.function, showDivider: true),
        DetailRow(
          label: 'Point ID',
          value: point.pointId.toString(),
          showDivider: true,
        ),
        DetailRow(
          label: 'Point Type',
          value: point.pointType,
          showDivider: true,
        ),
        DetailRow(
          label: 'Current Value',
          customValue: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: getOutputPointValueColor(point),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              formatOutputPointValue(point),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getInputPointColor(ButtonPoint point) {
    if (point.function.contains('Status') || point.name.contains('Missing')) {
      return Colors.orange;
    } else if (point.function.contains('IR')) {
      return Colors.purple;
    } else if (point.function.contains('Button')) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
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
      _deviceIdController.text = widget.device.deviceId.toString();
    }
  }

  void _updateDeviceAddress(String val) {
    if (val.trim().isNotEmpty) {
      setState(() {
        widget.device.address = val.trim();
      });
      logInfo("Address updated");
    } else {
      showSnackBarMsg(context, "Address cannot be empty");
      _addressController.text = widget.device.address;
    }
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
