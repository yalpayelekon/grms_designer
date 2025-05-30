import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/utils/dialog_utils.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/input_device.dart';
import '../../models/helvar_models/output_device.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../providers/router_connection_provider.dart';
import '../../providers/workgroups_provider.dart';
import '../../utils/device_icons.dart';
import '../../utils/file_dialog_helper.dart';
import '../../utils/general_ui.dart';
import '../../utils/logger.dart';
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
          : _buildDevicesList(),
    );
  }

  Widget _buildDevicesList() {
    return widget.router.devices.isEmpty
        ? Center(
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
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Manually'),
                      onPressed: () => _handleMenuAction('add_output'),
                    ),
                  ],
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: widget.router.devicesBySubnet.length,
            itemBuilder: (context, index) {
              final subnet = widget.router.devicesBySubnet.keys.elementAt(
                index,
              );
              final subnetDevices = widget.router.devicesBySubnet[subnet] ?? [];

              return ExpansionTile(
                title: Text('Subnet $subnet (${subnetDevices.length} devices)'),
                initiallyExpanded: index == 0,
                children: subnetDevices
                    .map((device) => _buildDeviceExpansionTile(device))
                    .toList(),
              );
            },
          );
  }

  Widget _buildDeviceExpansionTile(HelvarDevice device) {
    final deviceName = device.description.isEmpty
        ? 'Device ${device.deviceId}'
        : device.description;

    final List<Widget> subItems = [];

    subItems.add(
      ListTile(
        leading: const Icon(Icons.warning_amber, size: 20),
        title: const Text('Alarm Source Info'),
        contentPadding: const EdgeInsets.only(left: 56),
        dense: true,
        onTap: () => _showDeviceAlarmInfo(device),
      ),
    );

    if (device is HelvarDriverInputDevice &&
        device.isButtonDevice &&
        device.buttonPoints.isNotEmpty) {
      subItems.add(
        ExpansionTile(
          title: const Text('Points'),
          leading: const Icon(Icons.add_circle_outline),
          childrenPadding: const EdgeInsets.only(left: 20),
          tilePadding: const EdgeInsets.only(left: 40),
          children: device.buttonPoints
              .map(
                (point) => ListTile(
                  leading: Icon(
                    point.function.contains('Status') ||
                            point.name.contains('Missing')
                        ? Icons.info_outline
                        : point.function.contains('IR')
                        ? Icons.settings_remote
                        : Icons.touch_app,
                    size: 20,
                    color: Colors.green,
                  ),
                  title: Text(point.name),
                  subtitle: Text(point.function),
                  contentPadding: const EdgeInsets.only(left: 16),
                  dense: true,
                ),
              )
              .toList(),
        ),
      );
    }

    // Add sensor info for multisensors
    if (device.isMultisensor) {
      subItems.add(
        ExpansionTile(
          title: const Text('Sensor Data'),
          leading: const Icon(Icons.sensors),
          childrenPadding: const EdgeInsets.only(left: 20),
          tilePadding: const EdgeInsets.only(left: 40),
          children: device.sensorInfo.entries
              .map(
                (entry) => ListTile(
                  title: Text('${entry.key}: ${entry.value}'),
                  dense: true,
                ),
              )
              .toList(),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
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
            Text('Type: ${device.props}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editDevice(device),
              tooltip: 'Edit device',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDeleteDevice(device),
              tooltip: 'Remove device',
            ),
          ],
        ),
        onExpansionChanged: (expanded) {
          if (expanded) {
            _showDeviceDetails(device);
          }
        },
        children: subItems,
      ),
    );
  }

  void _showDeviceAlarmInfo(HelvarDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Alarm Info: ${device.description}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('State: ${device.state}'),
            if (device.deviceStateCode != null)
              Text(
                'State Code: 0x${device.deviceStateCode!.toRadixString(16)}',
              ),
            const SizedBox(height: 8),
            const Text('No active alarms'),
          ],
        ),
        actions: [closeAction(context)],
      ),
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

  void _editDevice(HelvarDevice device) {
    showSnackBarMsg(context, 'Edit Device feature coming soon');
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

  void _showDeviceDetails(HelvarDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          device.description.isEmpty
              ? 'Device ${device.deviceId}'
              : device.description,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Address', device.address),
              _buildDetailRow('Type', device.props),
              _buildDetailRow('ID', device.deviceId.toString()),
              if (device.deviceTypeCode != null)
                _buildDetailRow(
                  'Type Code',
                  '0x${device.deviceTypeCode!.toRadixString(16)}',
                ),
              _buildDetailRow('Device Type', device.helvarType),
              _buildDetailRow('Emergency', device.emergency.toString()),
              _buildDetailRow('Block ID', device.blockId),
              _buildDetailRow('Scene ID', device.sceneId),
              if (device.state.isNotEmpty)
                _buildDetailRow('State', device.state),
              if (device.hexId.isNotEmpty)
                _buildDetailRow('Hex ID', device.hexId),
              if (device.helvarType == 'output' &&
                  device is HelvarDriverOutputDevice)
                _buildDetailRow('Level', '${device.level}%'),
              if (device is HelvarDriverInputDevice &&
                  device.isButtonDevice &&
                  device.buttonPoints.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'Button Points:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...device.buttonPoints.map(
                  (point) => Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                    child: Text('${point.name} (${point.function})'),
                  ),
                ),
              ],
              if (device.isMultisensor) ...[
                const Divider(),
                const Text(
                  'Sensor Capabilities:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...device.sensorInfo.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                    child: Text('${entry.key}: ${entry.value}'),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          closeAction(context),
          if (device.helvarType == 'output')
            ElevatedButton(
              onPressed: () => _controlOutputDevice(device),
              child: const Text('Control'),
            )
          else if (device.helvarType == 'emergency')
            ElevatedButton(
              onPressed: () => _testEmergencyDevice(device),
              child: const Text('Test'),
            ),
        ],
      ),
    );
  }

  void _controlOutputDevice(HelvarDevice device) {
    showSnackBarMsg(context, 'Device control feature coming soon');
  }

  void _testEmergencyDevice(HelvarDevice device) {
    showSnackBarMsg(context, 'Emergency device test feature coming soon');
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
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

      showSnackBarMsg(
        context,
        'Successfully deleted ${devicesToDelete.length} devices',
      );

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
