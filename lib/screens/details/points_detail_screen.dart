import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/input_device.dart';

class PointsDetailScreen extends ConsumerStatefulWidget {
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

  const PointsDetailScreen({
    super.key,
    required this.workgroup,
    required this.router,
    required this.device,
    this.onNavigate,
  });

  @override
  PointsDetailScreenState createState() => PointsDetailScreenState();
}

class PointsDetailScreenState extends ConsumerState<PointsDetailScreen> {
  final Map<int, bool> _expandedPoints = {};
  final Map<int, String> _pointStates = {};

  @override
  void initState() {
    super.initState();
    _initializePointStates();
  }

  void _initializePointStates() {
    final inputDevice = widget.device as HelvarDriverInputDevice;
    for (final point in inputDevice.buttonPoints) {
      _pointStates[point.buttonId] = 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputDevice = widget.device as HelvarDriverInputDevice;
    final deviceName = widget.device.description.isEmpty
        ? 'Device ${widget.device.deviceId}'
        : widget.device.description;

    return Scaffold(
      appBar: AppBar(
        title: Text('Points - $deviceName'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh_all',
                child: Text('Refresh All States'),
              ),
              const PopupMenuItem(
                value: 'export_config',
                child: Text('Export Point Configuration'),
              ),
              const PopupMenuItem(
                value: 'clear_all_history',
                child: Text('Clear All Event History'),
              ),
            ],
          ),
        ],
      ),
      body: inputDevice.buttonPoints.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.radio_button_unchecked,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No points available for this device',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            )
          : _buildPointsList(inputDevice),
    );
  }

  Widget _buildPointsList(HelvarDriverInputDevice inputDevice) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: inputDevice.buttonPoints.length,
      itemBuilder: (context, index) {
        final point = inputDevice.buttonPoints[index];
        return _buildPointCard(point, index);
      },
    );
  }

  Widget _buildPointCard(ButtonPoint point, int index) {
    final isExpanded = _expandedPoints[point.buttonId] ?? false;
    final currentState = _pointStates[point.buttonId] ?? 'Unknown';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _getPointColor(
                point,
              ).withValues(alpha: 0.2 * 255),
              child: Icon(
                _getPointIcon(point),
                color: _getPointColor(point),
                size: 20,
              ),
            ),
            title: Text(
              point.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Function: ${point.function}'),
                Text('ID: ${point.buttonId}'),
                Row(
                  children: [
                    const Text('State: '),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStateColor(
                          currentState,
                        ).withValues(alpha: 0.2 * 255),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        currentState,
                        style: TextStyle(
                          color: _getStateColor(currentState),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () => _togglePointExpansion(point.buttonId),
                ),
              ],
            ),
            isThreeLine: true,
          ),
          if (isExpanded) _buildExpandedPointContent(point),
        ],
      ),
    );
  }

  Widget _buildExpandedPointContent(ButtonPoint point) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Point Name', point.name),
                    _buildInfoRow('Function Type', point.function),
                    _buildInfoRow('Button ID', point.buttonId.toString()),
                    _buildInfoRow(
                      'Point Type',
                      _getPointTypeDescription(point),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  IconData _getPointIcon(ButtonPoint point) {
    if (point.function.contains('Status') || point.name.contains('Missing')) {
      return Icons.info_outline;
    } else if (point.function.contains('IR')) {
      return Icons.settings_remote;
    } else if (point.function.contains('Button')) {
      return Icons.touch_app;
    } else {
      return Icons.radio_button_unchecked;
    }
  }

  Color _getPointColor(ButtonPoint point) {
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

  Color _getStateColor(String state) {
    switch (state.toLowerCase()) {
      case 'active':
      case 'on':
      case 'pressed':
        return Colors.green;
      case 'inactive':
      case 'off':
      case 'released':
        return Colors.grey;
      case 'fault':
      case 'error':
        return Colors.red;
      case 'unknown':
      default:
        return Colors.orange;
    }
  }

  String _getPointTypeDescription(ButtonPoint point) {
    if (point.function.contains('Status') || point.name.contains('Missing')) {
      return 'Status Point';
    } else if (point.function.contains('IR')) {
      return 'IR Receiver';
    } else if (point.function.contains('Button')) {
      return 'Button Input';
    } else {
      return 'Generic Point';
    }
  }

  void _togglePointExpansion(int buttonId) {
    setState(() {
      _expandedPoints[buttonId] = !(_expandedPoints[buttonId] ?? false);
    });
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh_all':
        break;
      case 'export_config':
        break;
      case 'clear_all_history':
        break;
    }
  }
}
