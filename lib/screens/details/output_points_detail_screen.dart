import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/models/helvar_models/output_point.dart';
import 'package:grms_designer/utils/device_utils.dart';
import 'package:grms_designer/utils/treeview_utils.dart';
import 'package:grms_designer/utils/ui_helpers.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/output_device.dart';

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
  Widget build(BuildContext context) {
    final outputDevice = widget.device as HelvarDriverOutputDevice;
    final deviceName = widget.device.description.isEmpty
        ? 'Device ${widget.device.deviceId}'
        : widget.device.description;

    return Scaffold(
      appBar: AppBar(
        title: Text('Output Points - $deviceName'),
        centerTitle: true,
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
              backgroundColor: getOutputPointColor(
                point,
              ).withValues(alpha: 0.2 * 255),
              child: Icon(
                getOutputPointIcon(point),
                color: getOutputPointColor(point),
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
                        formatOutputPointValue(point),
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
                      'Current Value',
                      formatOutputPointValue(point),
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

  void _togglePointExpansion(int pointId) {
    setState(() {
      _expandedPoints[pointId] = !(_expandedPoints[pointId] ?? false);
    });
  }
}
