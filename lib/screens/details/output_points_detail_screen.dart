import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/models/helvar_models/output_point.dart';
import 'package:grms_designer/utils/ui_helpers.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/output_device.dart';
import '../../services/device_query_service.dart';

class OutputPointsDetailScreen extends ConsumerStatefulWidget {
  final Workgroup workgroup;
  final HelvarRouter router;
  final HelvarDevice device;
  final Function(
    String, {
    Workgroup? workgroup,
    HelvarRouter? router,
    HelvarDevice? device,
    OutputPoint? outputPoint,
  })?
  onNavigate;

  const OutputPointsDetailScreen({
    super.key,
    required this.workgroup,
    required this.router,
    required this.device,
    this.onNavigate,
  });

  @override
  OutputPointsDetailScreenState createState() =>
      OutputPointsDetailScreenState();
}

class OutputPointsDetailScreenState
    extends ConsumerState<OutputPointsDetailScreen> {
  final Map<int, bool> _expandedPoints = {};
  bool _autoRefresh = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    if (widget.device is HelvarDriverOutputDevice) {
      final outputDevice = widget.device as HelvarDriverOutputDevice;
      if (outputDevice.outputPoints.isEmpty) {
        outputDevice.generateOutputPoints();
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outputDevice = widget.device as HelvarDriverOutputDevice;
    final deviceName = widget.device.description.isEmpty
        ? 'Device ${widget.device.deviceId}'
        : widget.device.description;

    return Scaffold(
      appBar: AppBar(
        title: Text('Output Points - $deviceName'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_autoRefresh ? Icons.pause : Icons.refresh),
            tooltip: _autoRefresh ? 'Stop Auto Refresh' : 'Start Auto Refresh',
            onPressed: _toggleAutoRefresh,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'query_all',
                child: Text('Query All Points'),
              ),
              const PopupMenuItem(
                value: 'export_config',
                child: Text('Export Point Configuration'),
              ),
              const PopupMenuItem(
                value: 'reset_values',
                child: Text('Reset All Values'),
              ),
            ],
          ),
        ],
      ),
      body: outputDevice.outputPoints.isEmpty
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
                    'No output points available for this device',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            )
          : _buildPointsList(outputDevice),
    );
  }

  Widget _buildPointsList(HelvarDriverOutputDevice outputDevice) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: outputDevice.outputPoints.length,
      itemBuilder: (context, index) {
        final point = outputDevice.outputPoints[index];
        return _buildPointCard(point, index);
      },
    );
  }

  Widget _buildPointCard(OutputPoint point, int index) {
    final isExpanded = _expandedPoints[point.pointId] ?? false;

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
              point.function,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: ${point.pointType}'),
                Text('ID: ${point.pointId}'),
                Row(
                  children: [
                    const Text('Value: '),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getValueColor(
                          point,
                        ).withValues(alpha: 0.2 * 255),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatValue(point),
                        style: TextStyle(
                          color: _getValueColor(point),
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
                  onPressed: () => _togglePointExpansion(point.pointId),
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

  Widget _buildExpandedPointContent(OutputPoint point) {
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
                    buildInfoRow('Point Name', point.name),
                    buildInfoRow('Function', point.function),
                    buildInfoRow('Point ID', point.pointId.toString()),
                    buildInfoRow('Point Type', point.pointType),
                    buildInfoRow(
                      'Description',
                      DeviceQueryService.getPointDescription(point.pointId),
                    ),
                    buildInfoRow('Current Value', _formatValue(point)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getPointIcon(OutputPoint point) {
    switch (point.pointId) {
      case 1: // Device State
        return Icons.device_hub;
      case 2: // Lamp Failure
        return Icons.lightbulb_outline;
      case 3: // Missing
        return Icons.help_outline;
      case 4: // Faulty
        return Icons.warning;
      case 5: // Output Level
        return Icons.tune;
      case 6: // Power Consumption
        return Icons.power;
      default:
        return Icons.circle;
    }
  }

  Color _getPointColor(OutputPoint point) {
    switch (point.pointId) {
      case 1: // Device State
        return Colors.blue;
      case 2: // Lamp Failure
        return Colors.red;
      case 3: // Missing
        return Colors.orange;
      case 4: // Faulty
        return Colors.red;
      case 5: // Output Level
        return Colors.green;
      case 6: // Power Consumption
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getValueColor(OutputPoint point) {
    if (point.pointType == 'boolean') {
      final value = point.value as bool? ?? false;
      if ([1, 2, 3, 4].contains(point.pointId)) {
        return value ? Colors.red : Colors.green;
      }
      return value ? Colors.green : Colors.grey;
    } else {
      final value = (point.value as num?)?.toDouble() ?? 0.0;
      if (value == 0) return Colors.grey;
      if (value < 50) return Colors.blue;
      return Colors.green;
    }
  }

  String _formatValue(OutputPoint point) {
    if (point.pointType == 'boolean') {
      final value = point.value as bool? ?? false;
      return value ? 'TRUE' : 'FALSE';
    } else {
      final value = (point.value as num?)?.toDouble() ?? 0.0;
      if (point.pointId == 5) {
        // Output Level
        return '${value.toStringAsFixed(0)}%';
      } else if (point.pointId == 6) {
        // Power Consumption
        return '${value.toStringAsFixed(1)}W';
      }
      return value.toStringAsFixed(1);
    }
  }

  void _togglePointExpansion(int pointId) {
    setState(() {
      _expandedPoints[pointId] = !(_expandedPoints[pointId] ?? false);
    });
  }

  void _toggleAutoRefresh() {
    setState(() {
      _autoRefresh = !_autoRefresh;
    });

    if (_autoRefresh) {
      _startAutoRefresh();
      showSnackBarMsg(context, 'Auto refresh started (30s interval)');
    } else {
      _stopAutoRefresh();
      showSnackBarMsg(context, 'Auto refresh stopped');
    }
  }

  void _startAutoRefresh() {}

  void _stopAutoRefresh() {}

  void _handleMenuAction(String action) {
    switch (action) {
      case 'query_all':
        break;
      case 'export_config':
        break;
      case 'reset_values':
        break;
    }
  }
}
