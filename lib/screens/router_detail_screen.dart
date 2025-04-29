import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/helvar_router.dart';
import '../models/helvar_device.dart';
import '../models/workgroup.dart';
import '../providers/workgroups_provider.dart';
import '../utils/file_dialog_helper.dart';

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

  @override
  void initState() {
    super.initState();
    _devices = widget.router.devices;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Router: ${widget.router.name}'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
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
    return _devices.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.device_unknown,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No devices found for this router',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add a Device'),
                  onPressed: () => _handleMenuAction('add_output'),
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: _devices.length,
            itemBuilder: (context, index) {
              final device = _devices[index];
              return _buildDeviceCard(device);
            },
          );
  }

  Widget _buildDeviceCard(HelvarDevice device) {
    IconData deviceIcon;
    switch (device.helvarType) {
      case 'input':
        deviceIcon = Icons.input;
        break;
      case 'emergency':
        deviceIcon = Icons.emergency;
        break;
      case 'output':
      default:
        deviceIcon = Icons.light;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(deviceIcon),
        ),
        title: Text(
          device.description.isEmpty
              ? 'Device ${device.deviceId}'
              : device.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Address: ${device.address}'),
            Text('Type: ${device.helvarType}'),
            if (device.helvarType == 'output')
              Text('Level: ${(device as dynamic).level}%'),
          ],
        ),
        isThreeLine: true,
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
        onTap: () => _showDeviceDetails(device),
      ),
    );
  }

  void _handleMenuAction(String action) async {
    switch (action) {
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
              'Found ${devices.length} devices. Do you want to merge with existing devices or replace them?'),
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
        final existingAddresses =
            widget.router.devices.map((d) => d.address).toSet();
        final newDevices = devices
            .where((d) => !existingAddresses.contains(d.address))
            .toList();

        for (final device in newDevices) {
          await ref.read(workgroupsProvider.notifier).addDeviceToRouter(
                widget.workgroup.id,
                widget.router.address,
                device,
              );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${newDevices.length} new devices')),
        );
      } else {
        widget.router.devices.clear();

        for (final device in devices) {
          await ref.read(workgroupsProvider.notifier).addDeviceToRouter(
                widget.workgroup.id,
                widget.router.address,
                device,
              );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Replaced with ${devices.length} imported devices')),
        );
      }
      setState(() {
        _devices = widget.router.devices;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing devices: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportDevices() async {
    try {
      if (_devices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No devices to export')),
        );
        return;
      }

      final filePath = await FileDialogHelper.pickJsonFileToSave();
      if (filePath == null) return;

      setState(() {
        _isLoading = true;
      });

      final routerStorageService = ref.read(routerStorageServiceProvider);
      await routerStorageService.exportRouterDevices(_devices, filePath);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Exported ${_devices.length} devices to $filePath')),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting devices: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addOutputDevice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Output Device feature coming soon')),
    );
  }

  void _addInputDevice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Input Device feature coming soon')),
    );
  }

  void _addEmergencyDevice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Emergency Device feature coming soon')),
    );
  }

  void _editDevice(HelvarDevice device) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit Device feature coming soon')),
    );
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref.read(workgroupsProvider.notifier).removeDeviceFromRouter(
            widget.workgroup.id,
            widget.router.address,
            device,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Device deleted'),
        ),
      );
      setState(() {
        _devices = widget.router.devices;
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
              _buildDetailRow('Type', device.helvarType),
              _buildDetailRow('Device ID', device.deviceId.toString()),
              _buildDetailRow('Emergency', device.emergency.toString()),
              _buildDetailRow('Block ID', device.blockId),
              _buildDetailRow('Scene ID', device.sceneId),
              _buildDetailRow('Fade Time', '${device.fadeTime}ms'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
