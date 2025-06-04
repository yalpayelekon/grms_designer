import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/widgets/common/detail_card.dart';
import 'package:grms_designer/widgets/common/expandable_list_item.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../providers/router_connection_provider.dart';
import '../../providers/workgroups_provider.dart';
import 'package:grms_designer/utils/ui/ui_helpers.dart';
import '../../utils/core/logger.dart';
import '../dialogs/add_device_dialog.dart';
import 'subnet_detail_screen.dart';

class RouterDetailScreen extends ConsumerStatefulWidget {
  final Workgroup workgroup;
  final HelvarRouter router;
  final bool asWidget;

  const RouterDetailScreen({
    super.key,
    required this.workgroup,
    required this.router,
    this.asWidget = false,
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

  Widget _buildRouterInfo() {
    return ExpandableListItem(
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
        DetailRow(label: 'Workgroup', value: widget.workgroup.description),
      ],
    );
  }

  Widget _buildSubnetsSection() {
    if (_devicesBySubnet.isEmpty) {
      return const SizedBox.shrink();
    }

    return ExpandableListItem(
      title: 'Subnets and Devices',
      leadingIcon: Icons.hub,
      leadingIconColor: Colors.indigo,
      children: _devicesBySubnet.entries
          .map((entry) => _buildSubnetItem(entry.key, entry.value))
          .toList(),
    );
  }

  Widget _buildSubnetItem(String subnetId, List<HelvarDevice> devices) {
    final outputCount = devices.where((d) => d.helvarType == 'output').length;
    final inputCount = devices.where((d) => d.helvarType == 'input').length;
    final emergencyCount = devices.where((d) => d.emergency).length;

    // Extract subnet number from subnetId (e.g., "1.1.1" -> 1)
    final subnetNumber = int.tryParse(subnetId.split('.').last) ?? 0;

    return ExpandableListItem(
      title: 'Subnet $subnetId',
      subtitle:
          '${devices.length} devices • $outputCount output • $inputCount input • $emergencyCount emergency',
      leadingIcon: Icons.hub,
      leadingIconColor: Colors.orange,
      indentLevel: 1,
      children: [
        SubnetDetailScreen(
          workgroup: widget.workgroup,
          router: widget.router,
          subnetNumber: subnetNumber,
          devices: devices,
          asWidget: true,
        ),
      ],
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
    }
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'discover':
        await _discoverDevices();
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

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_devices.isEmpty) {
      return _buildEmptyState();
    }

    if (widget.asWidget) {
      return _buildSubnetsSection();
    }

    return ExpandableListView(
      padding: const EdgeInsets.all(8.0),
      children: [_buildRouterInfo(), _buildSubnetsSection()],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.asWidget) {
      return _buildContent();
    }

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
      body: _buildContent(),
    );
  }
}
