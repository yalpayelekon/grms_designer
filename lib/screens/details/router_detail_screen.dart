import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/models/helvar_models/output_point.dart';
import 'package:grms_designer/utils/device/device_utils.dart';
import 'package:grms_designer/utils/ui/treeview_utils.dart';
import 'package:grms_designer/widgets/common/detail_card.dart';
import 'package:grms_designer/widgets/common/expandable_list_item.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/input_device.dart';
import '../../models/helvar_models/output_device.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../providers/router_connection_provider.dart';
import '../../providers/workgroups_provider.dart';
import '../../utils/file/file_dialog_helper.dart';
import 'package:grms_designer/utils/ui/ui_helpers.dart';
import '../../utils/core/logger.dart';
import '../dialogs/add_device_dialog.dart';

class RouterDetailScreen extends ConsumerStatefulWidget {
  final Workgroup workgroup;
  final HelvarRouter router;

  const RouterDetailScreen({
    super.key,
    required this.workgroup,
    required this.router,
  });

  @override
  RouterDetailScreenState createState() => RouterDetailScreenState();
}

class RouterDetailScreenState extends ConsumerState<RouterDetailScreen> {
  late List<HelvarDevice> _devices;
  bool _isLoading = false;
  final Map<String, List<HelvarDevice>> _devicesBySubnet = {};

  @override
  void initState() {
    super.initState();
    _devices = widget.router.devices;
    _organizeDevicesBySubnet();
  }

  void _organizeDevicesBySubnet() {
    _devicesBySubnet.clear();

    for (final device in _devices) {
      final addressParts = device.address.split('.');
      if (addressParts.length >= 3) {
        final subnetId = addressParts.sublist(0, 3).join('.');

        if (!_devicesBySubnet.containsKey(subnetId)) {
          _devicesBySubnet[subnetId] = [];
        }

        _devicesBySubnet[subnetId]!.add(device);
      }
    }
  }

  void _addOutputDevice() {
    _showAddDeviceDialog(DeviceType.output);
  }

  void _addInputDevice() {
    _showAddDeviceDialog(DeviceType.input);
  }

  void _addEmergencyDevice() {
    _showAddDeviceDialog(DeviceType.emergency);
  }

  Future<void> _showAddDeviceDialog(DeviceType initialType) async {
    final existingSubnets = _devicesBySubnet.keys.toList();

    final device = await showDialog<HelvarDevice>(
      context: context,
      builder: (context) => AddDeviceDialog(
        nextDeviceId: _devices.length + 1,
        existingSubnets: existingSubnets,
      ),
    );

    if (device != null) {
      await ref
          .read(workgroupsProvider.notifier)
          .addDeviceToRouter(
            widget.workgroup.id,
            widget.router.address,
            device,
          );

      setState(() {
        _devices = widget.router.devices;
        _organizeDevicesBySubnet();
      });

      if (mounted) {
        showSnackBarMsg(context, 'Device added successfully');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Router: ${widget.router.description}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi),
            tooltip: 'Connect',
            onPressed: () {
              ref
                  .read(workgroupsProvider.notifier)
                  .getRouterConnection(
                    widget.workgroup.id,
                    widget.router.address,
                  );
            },
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'discover',
                child: Text('Discover Devices'),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Text('Import Devices from File'),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Text('Export Devices to File'),
              ),
              const PopupMenuItem(
                value: 'add_output',
                child: Text('Add Output Device'),
              ),
              const PopupMenuItem(
                value: 'add_input',
                child: Text('Add Input Device'),
              ),
              const PopupMenuItem(
                value: 'add_emergency',
                child: Text('Add Emergency Device'),
              ),
              const PopupMenuItem(
                value: 'delete_all',
                child: Text('Delete All Devices'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _devices.isEmpty
          ? _buildEmptyState()
          : ExpandableListView(
              padding: const EdgeInsets.all(8.0),
              children: [
                ExpandableListItem(
                  title: 'Router Information',
                  subtitle: 'Network details and configuration',
                  leadingIcon: Icons.router,
                  leadingIconColor: Colors.purple,
                  initiallyExpanded: true,
                  detailRows: [
                    DetailRow(
                      label: 'Description',
                      value: widget.router.description,
                      showDivider: true,
                    ),
                    DetailRow(
                      label: 'IP Address',
                      value: widget.router.ipAddress,
                      showDivider: true,
                    ),
                    DetailRow(
                      label: 'Address',
                      value: widget.router.address,
                      showDivider: true,
                    ),
                    DetailRow(
                      label: 'Workgroup',
                      value: widget.workgroup.description,
                    ),
                  ],
                ),

                if (_devicesBySubnet.isNotEmpty)
                  ExpandableListItem(
                    title: 'Subnets and Devices',

                    leadingIcon: Icons.hub,
                    leadingIconColor: Colors.indigo,
                    children: _devicesBySubnet.entries
                        .map(
                          (entry) => _buildSubnetItem(entry.key, entry.value),
                        )
                        .toList(),
                  ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.device_unknown, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No devices found for this router',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Discover Devices'),
                onPressed: _discoverDevices,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubnetItem(String subnetId, List<HelvarDevice> devices) {
    final outputCount = devices.where((d) => d.helvarType == 'output').length;
    final inputCount = devices.where((d) => d.helvarType == 'input').length;
    final emergencyCount = devices.where((d) => d.emergency).length;

    return ExpandableListItem(
      title: 'Subnet $subnetId',
      subtitle:
          '${devices.length} devices • $outputCount output • $inputCount input • $emergencyCount emergency',
      leadingIcon: Icons.hub,
      leadingIconColor: Colors.orange,
      indentLevel: 1,
      detailRows: [
        DetailRow(label: 'Subnet ID', value: subnetId, showDivider: true),
      ],
      children: devices.map((device) => _buildDeviceItem(device)).toList(),
    );
  }

  Widget _buildDeviceItem(HelvarDevice device) {
    final deviceName = device.description.isEmpty
        ? 'Device ${device.deviceId}'
        : device.description;

    IconData deviceIcon;
    Color deviceColor;

    if (device.emergency || device.helvarType == 'emergency') {
      deviceIcon = Icons.warning;
      deviceColor = Colors.red;
    } else if (device.helvarType == 'output') {
      deviceIcon = Icons.lightbulb_outline;
      deviceColor = Colors.orange;
    } else if (device.helvarType == 'input') {
      deviceIcon = device.isButtonDevice
          ? Icons.touch_app
          : device.isMultisensor
          ? Icons.sensors
          : Icons.input;
      deviceColor = Colors.green;
    } else {
      deviceIcon = Icons.device_hub;
      deviceColor = Colors.grey;
    }

    List<Widget> deviceChildren = [];
    if (device.helvarType == 'input' || device.emergency) {
      deviceChildren.add(_buildAlarmSourceInfo(device));
    }

    if (device is HelvarDriverInputDevice && device.buttonPoints.isNotEmpty) {
      deviceChildren.add(_buildButtonPointsSection(device));
    }

    if (device.isMultisensor && device.sensorInfo.isNotEmpty) {
      deviceChildren.add(_buildSensorDataSection(device));
    }

    if (device is HelvarDriverOutputDevice) {
      if (device.outputPoints.isEmpty) {
        device.generateOutputPoints();
      }
      if (device.outputPoints.isNotEmpty) {
        deviceChildren.add(_buildOutputPointsSection(device));
      }
    }

    return ExpandableListItem(
      title: deviceName,
      subtitle:
          'Address: ${device.address} • Type: ${device.helvarType} • Props: ${device.props}',
      leadingIcon: deviceIcon,
      leadingIconColor: deviceColor,
      indentLevel: 2,
      showDelete: true,
      onDelete: () => _confirmDeleteDevice(device),

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
        if (device.deviceTypeCode != null)
          DetailRow(
            label: 'Type Code',
            value: '0x${device.deviceTypeCode!.toRadixString(16)}',
            showDivider: true,
          ),
        if (device.hexId.isNotEmpty)
          DetailRow(label: 'Hex ID', value: device.hexId, showDivider: true),
        DetailRow(label: 'Block ID', value: device.blockId, showDivider: true),
        DetailRow(
          label: 'Scene ID',
          value: device.sceneId.isEmpty ? 'None' : device.sceneId,
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
      children: deviceChildren,
    );
  }

  Widget _buildAlarmSourceInfo(HelvarDevice device) {
    return ExpandableListItem(
      title: 'Alarm Source Info',
      subtitle: 'Device state and alarm information',
      leadingIcon: Icons.warning_amber,
      leadingIconColor: Colors.orange,
      indentLevel: 3,
      detailRows: [
        DetailRow(
          label: 'State',
          value: device.state.isEmpty ? 'Unknown' : device.state,
          showDivider: true,
        ),
        if (device.deviceStateCode != null)
          DetailRow(
            label: 'State Code',
            value: '0x${device.deviceStateCode!.toRadixString(16)}',
          ),
      ],
    );
  }

  Widget _buildButtonPointsSection(HelvarDriverInputDevice device) {
    return ExpandableListItem(
      title: 'Button Points',
      subtitle: '${device.buttonPoints.length} input points',
      leadingIcon: Icons.touch_app,
      leadingIconColor: Colors.blue,
      indentLevel: 3,
      children: device.buttonPoints
          .map((point) => _buildButtonPointItem(point))
          .toList(),
    );
  }

  Widget _buildButtonPointItem(ButtonPoint point) {
    return ExpandableListItem(
      title: point.name,
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
          : Colors.green,
      indentLevel: 4,
      detailRows: [
        DetailRow(label: 'Function', value: point.function, showDivider: true),
        DetailRow(label: 'Button ID', value: point.buttonId.toString()),
      ],
    );
  }

  Widget _buildSensorDataSection(HelvarDevice device) {
    return ExpandableListItem(
      title: 'Sensor Data',
      subtitle: '${device.sensorInfo.length} sensor readings',
      leadingIcon: Icons.sensors,
      leadingIconColor: Colors.green,
      indentLevel: 3,
      detailRows: device.sensorInfo.entries
          .map(
            (entry) => DetailRow(
              label: entry.key,
              value: entry.value.toString(),
              showDivider: entry != device.sensorInfo.entries.last,
            ),
          )
          .toList(),
    );
  }

  Widget _buildOutputPointsSection(HelvarDriverOutputDevice device) {
    return ExpandableListItem(
      title: 'Output Points',
      subtitle: '${device.outputPoints.length} output points',
      leadingIcon: Icons.output,
      leadingIconColor: Colors.orange,
      indentLevel: 3,
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
      indentLevel: 4,
      detailRows: [
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

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'discover':
        await _discoverDevices();
        break;
      case 'import':
        await _importDevices();
        break;
      case 'export':
        await _exportDevices();
        break;
      case 'add_output':
        _addOutputDevice();
        break;
      case 'add_input':
        _addInputDevice();
        break;
      case 'add_emergency':
        _addEmergencyDevice();
        break;
      case 'delete_all':
        _deleteAllDevices();
        break;
    }
  }

  Future<void> _importDevices() async {
    try {
      final filePath = await FileDialogHelper.pickJsonFileToOpen();
      if (filePath == null) return;

      setState(() {
        _isLoading = true;
      });

      final routerStorageService = ref.read(routerStorageServiceProvider);
      final devices = await routerStorageService.importRouterDevices(filePath);
      if (!mounted) return;
      final merge = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Devices'),
          content: Text(
            'Found ${devices.length} devices. Do you want to merge with existing devices or replace them?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Replace'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Merge'),
            ),
          ],
        ),
      );

      if (merge == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      if (merge) {
        final existingAddresses = widget.router.devices
            .map((d) => d.address)
            .toSet();
        final newDevices = devices
            .where((d) => !existingAddresses.contains(d.address))
            .toList();

        for (final device in newDevices) {
          await ref
              .read(workgroupsProvider.notifier)
              .addDeviceToRouter(
                widget.workgroup.id,
                widget.router.address,
                device,
              );
        }
        showSnackBarMsg(context, 'Added ${newDevices.length} new devices');
      } else {
        widget.router.devices.clear();

        for (final device in devices) {
          await ref
              .read(workgroupsProvider.notifier)
              .addDeviceToRouter(
                widget.workgroup.id,
                widget.router.address,
                device,
              );
        }
        showSnackBarMsg(
          context,
          'Replaced with ${devices.length} imported devices',
        );
      }
      setState(() {
        _devices = widget.router.devices;
        _organizeDevicesBySubnet();
        _isLoading = false;
      });
    } catch (e) {
      showSnackBarMsg(context, 'Error importing devices: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportDevices() async {
    try {
      if (_devices.isEmpty) {
        showSnackBarMsg(context, 'No devices to export');
        return;
      }

      final filePath = await FileDialogHelper.pickJsonFileToSave(
        "helvarnet_devices.json",
      );
      if (filePath == null) return;

      setState(() {
        _isLoading = true;
      });

      final routerStorageService = ref.read(routerStorageServiceProvider);
      await routerStorageService.exportRouterDevices(_devices, filePath);

      if (!mounted) return;
      showSnackBarMsg(
        context,
        'Exported ${_devices.length} devices to $filePath',
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      showSnackBarMsg(context, 'Error exporting devices: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDeleteDevice(HelvarDevice device) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device'),
        content: Text(
          'Are you sure you want to delete the device "${device.description.isEmpty ? 'Device ${device.deviceId}' : device.description}"?',
        ),
        actions: [
          cancelAction(context),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref
          .read(workgroupsProvider.notifier)
          .removeDeviceFromRouter(
            widget.workgroup.id,
            widget.router.address,
            device,
          );

      if (!mounted) return;
      showSnackBarMsg(context, 'Device deleted');
      setState(() {
        _devices = widget.router.devices;
        _organizeDevicesBySubnet();
      });
    }
  }

  Future<void> _discoverDevices() async {
    if (widget.router.ipAddress.isEmpty) {
      showSnackBarMsg(context, 'Router IP address is not set');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      logInfo(
        'Starting device discovery for router: ${widget.router.ipAddress}',
      );

      final discoveryService = ref.watch(discoveryServiceProvider);

      await Future.delayed(const Duration(milliseconds: 100));

      logInfo('Discovery service obtained, attempting connection...');

      final discoveredRouter = await discoveryService
          .discoverRouterWithPersistentConnection(widget.router.ipAddress);

      logInfo('Discovery completed. Router found: ${discoveredRouter != null}');

      if (discoveredRouter == null || discoveredRouter.devices.isEmpty) {
        if (!mounted) return;
        final message = discoveredRouter == null
            ? 'Failed to connect to router'
            : 'No devices discovered';
        showSnackBarMsg(context, message);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final discoveredDevices = discoveredRouter.devices;
      logInfo('Found ${discoveredDevices.length} devices');

      if (!mounted) return;
      final shouldAdd =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Devices Discovered'),
              content: Text(
                'Found ${discoveredDevices.length} devices. Do you want to add them?',
              ),
              actions: [
                cancelAction(context),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Add Devices'),
                ),
              ],
            ),
          ) ??
          false;

      if (!shouldAdd || !mounted) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final existingAddresses = _devices.map((d) => d.address).toSet();
      final newDevices = discoveredDevices
          .where((d) => !existingAddresses.contains(d.address))
          .toList();

      logInfo('Adding ${newDevices.length} new devices');

      if (newDevices.isNotEmpty) {
        await ref
            .read(workgroupsProvider.notifier)
            .addMultipleDevicesToRouter(
              widget.workgroup.id,
              widget.router.address,
              newDevices,
            );
      }

      if (!mounted) return;
      showSnackBarMsg(context, 'Added ${newDevices.length} devices');
      setState(() {
        _devices = widget.router.devices;
        _organizeDevicesBySubnet();
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      logError('Error discovering devices: $e', stackTrace: stackTrace);
      if (!mounted) return;
      showSnackBarMsg(context, 'Error discovering devices: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _deleteAllDevices() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Devices'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete all devices?'),
            const SizedBox(height: 8),
            Text(
              'This will permanently remove all ${_devices.length} devices from this router.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          cancelAction(context),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        await _performDeleteAllDevices();
      }
    });
  }

  Future<void> _performDeleteAllDevices() async {
    if (_devices.isEmpty) {
      showSnackBarMsg(context, 'No devices to delete');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final devicesToDelete = List<HelvarDevice>.from(_devices);

      for (final device in devicesToDelete) {
        await ref
            .read(workgroupsProvider.notifier)
            .removeDeviceFromRouter(
              widget.workgroup.id,
              widget.router.address,
              device,
            );
      }

      if (!mounted) return;

      setState(() {
        _devices.clear();
        _devicesBySubnet.clear();
        _isLoading = false;
      });

      logInfo(
        'Deleted all ${devicesToDelete.length} devices from router ${widget.router.address}',
      );
    } catch (e) {
      logError('Error deleting all devices: $e');

      if (!mounted) return;

      showSnackBarMsg(context, 'Error deleting devices: $e');

      setState(() {
        _isLoading = false;
        _devices = widget.router.devices;
        _organizeDevicesBySubnet();
      });
    }
  }
}
