import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/utils/ui_helpers.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/output_point.dart';
import '../../services/device_query_service.dart';

class OutputPointDetailScreen extends ConsumerStatefulWidget {
  final Workgroup workgroup;
  final HelvarRouter router;
  final HelvarDevice device;
  final OutputPoint point;

  const OutputPointDetailScreen({
    super.key,
    required this.workgroup,
    required this.router,
    required this.device,
    required this.point,
  });

  @override
  OutputPointDetailScreenState createState() => OutputPointDetailScreenState();
}

class OutputPointDetailScreenState
    extends ConsumerState<OutputPointDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.router.description} - ${widget.point.function}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildPointInfoCard(),
      ),
    );
  }

  Widget _buildPointInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getPointIcon(), size: 32, color: _getPointColor()),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.point.function,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        widget.point.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            buildInfoRow('Point Name', widget.point.name),
            buildInfoRow('Function', widget.point.function),
            buildInfoRow('Point ID', widget.point.pointId.toString()),
            buildInfoRow('Point Type', widget.point.pointType),
            buildInfoRow(
              'Parent Device',
              widget.device.description.isEmpty
                  ? 'Device ${widget.device.deviceId}'
                  : widget.device.description,
            ),
            buildInfoRow('Device Address', widget.device.address),
            buildInfoRow(
              'Description',
              DeviceQueryService.getPointDescription(widget.point.pointId),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPointIcon() {
    switch (widget.point.pointId) {
      case 1:
        return Icons.device_hub;
      case 2:
        return Icons.lightbulb_outline;
      case 3:
        return Icons.help_outline;
      case 4:
        return Icons.warning;
      case 5:
        return Icons.tune;
      case 6:
        return Icons.power;
      default:
        return Icons.circle;
    }
  }

  Color _getPointColor() {
    switch (widget.point.pointId) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.red;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.green;
      case 6:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
