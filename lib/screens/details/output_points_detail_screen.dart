import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/output_device.dart';
import '../../providers/router_connection_provider.dart';
import '../../services/device_query_service.dart';
import '../../utils/general_ui.dart';
import '../../utils/logger.dart';

class OutputPointsDetailScreen extends ConsumerStatefulWidget {
  final Workgroup workgroup;
  final HelvarRouter router;
  final HelvarDevice device;
  final Function(String,
      {Workgroup? workgroup,
      HelvarRouter? router,
      HelvarDevice? device,
      OutputPoint? outputPoint})? onNavigate;

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
  bool _isQueryingAll = false;
  bool _autoRefresh = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Generate points if they don't exist
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
      floatingActionButton: _isQueryingAll
          ? const FloatingActionButton(
              onPressed: null,
              child: CircularProgressIndicator(color: Colors.white),
            )
          : FloatingActionButton(
              onPressed: _queryAllPoints,
              tooltip: 'Query All Points',
              child: const Icon(Icons.cloud_download),
            ),
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
              backgroundColor:
                  _getPointColor(point).withValues(alpha: 0.2 * 255),
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
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            _getValueColor(point).withValues(alpha: 0.2 * 255),
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
                  icon: const Icon(Icons.launch, size: 20),
                  tooltip: 'Open Point Detail',
                  onPressed: () => _navigateToPointDetail(point),
                ),
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () => _togglePointExpansion(point.pointId),
                ),
              ],
            ),
            isThreeLine: true,
            onTap: () => _navigateToPointDetail(point),
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
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
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
                    _buildInfoRow('Function', point.function),
                    _buildInfoRow('Point ID', point.pointId.toString()),
                    _buildInfoRow('Point Type', point.pointType),
                    _buildInfoRow('Description',
                        DeviceQueryService.getPointDescription(point.pointId)),
                    _buildInfoRow('Current Value', _formatValue(point)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.launch, size: 16),
                label: const Text('Open Detail'),
                onPressed: () => _navigateToPointDetail(point),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Query Value'),
                onPressed: () => _queryPoint(point),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.info, size: 16),
                label: const Text('Point Info'),
                onPressed: () => _showPointInfo(point),
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
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12)),
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
      // For error states (Device State, Lamp Failure, Missing, Faulty)
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

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_isQueryingAll) {
        _queryAllPoints();
      }
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'query_all':
        _queryAllPoints();
        break;
      case 'export_config':
        _exportPointConfiguration();
        break;
      case 'reset_values':
        _resetAllValues();
        break;
    }
  }

  Future<void> _queryAllPoints() async {
    if (_isQueryingAll) return;

    setState(() {
      _isQueryingAll = true;
    });

    showSnackBarMsg(context, 'Querying all output points...');

    try {
      final deviceQueryService = ref.read(deviceQueryServiceProvider);
      final outputDevice = widget.device as HelvarDriverOutputDevice;

      final success = await deviceQueryService.queryOutputDevicePoints(
        widget.router.ipAddress,
        outputDevice,
      );

      if (success && mounted) {
        setState(() {}); // Refresh UI with new values
        showSnackBarMsg(context, 'Successfully updated all points');
      } else if (mounted) {
        showSnackBarMsg(context, 'Failed to query some points');
      }
    } catch (e) {
      logError('Error querying all points: $e');
      if (mounted) {
        showSnackBarMsg(context, 'Error querying points: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isQueryingAll = false;
        });
      }
    }
  }

  Future<void> _queryPoint(OutputPoint point) async {
    showSnackBarMsg(context, 'Querying ${point.function}...');

    try {
      final deviceQueryService = ref.read(deviceQueryServiceProvider);
      final outputDevice = widget.device as HelvarDriverOutputDevice;

      final success = await deviceQueryService.queryOutputDevicePoint(
        widget.router.ipAddress,
        outputDevice,
        point.pointId,
      );

      if (success && mounted) {
        setState(() {}); // Refresh UI
        showSnackBarMsg(context, 'Updated ${point.function}');
      } else if (mounted) {
        showSnackBarMsg(context, 'Failed to query ${point.function}');
      }
    } catch (e) {
      logError('Error querying point: $e');
      if (mounted) {
        showSnackBarMsg(context, 'Error querying point: $e');
      }
    }
  }

  void _exportPointConfiguration() {
    showSnackBarMsg(context, 'Export configuration feature coming soon');
  }

  void _resetAllValues() {
    final outputDevice = widget.device as HelvarDriverOutputDevice;
    setState(() {
      for (final point in outputDevice.outputPoints) {
        if (point.pointType == 'boolean') {
          point.value = false;
        } else {
          point.value = 0.0;
        }
      }
    });
    showSnackBarMsg(context, 'Reset all point values');
  }

  void _navigateToPointDetail(OutputPoint point) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(
        'outputPointDetail',
        workgroup: widget.workgroup,
        router: widget.router,
        device: widget.device,
        outputPoint: point,
      );
    } else {
      showSnackBarMsg(context, 'Point Detail navigation not available');
    }
  }

  void _showPointInfo(OutputPoint point) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(point.function),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Description: ${DeviceQueryService.getPointDescription(point.pointId)}'),
            const SizedBox(height: 8),
            Text('Point Type: ${point.pointType}'),
            Text('Current Value: ${_formatValue(point)}'),
            const SizedBox(height: 8),
            if (point.pointType == 'boolean')
              const Text(
                  'Boolean points represent on/off or true/false states.')
            else
              const Text('Numeric points represent measurable values.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
