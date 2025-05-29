import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/input_device.dart';

class InputPointDetailScreen extends ConsumerStatefulWidget {
  final Workgroup workgroup;
  final HelvarRouter router;
  final HelvarDevice device;
  final ButtonPoint point;

  const InputPointDetailScreen({
    super.key,
    required this.workgroup,
    required this.router,
    required this.device,
    required this.point,
  });

  @override
  InputPointDetailScreenState createState() => InputPointDetailScreenState();
}

class InputPointDetailScreenState
    extends ConsumerState<InputPointDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.router.description} - ${widget.point.name}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildPointInfoCard()],
        ),
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
                        widget.point.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        widget.point.function,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Point Name', widget.point.name),
            _buildInfoRow('Function', widget.point.function),
            _buildInfoRow('Button ID', widget.point.buttonId.toString()),
            _buildInfoRow(
              'Parent Device',
              widget.device.description.isEmpty
                  ? 'Device ${widget.device.deviceId}'
                  : widget.device.description,
            ),
            _buildInfoRow('Device Address', widget.device.address),
            _buildInfoRow('Point Type', _getPointTypeDescription()),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  IconData _getPointIcon() {
    if (widget.point.function.contains('Status') ||
        widget.point.name.contains('Missing')) {
      return Icons.info_outline;
    } else if (widget.point.function.contains('IR')) {
      return Icons.settings_remote;
    } else if (widget.point.function.contains('Button')) {
      return Icons.touch_app;
    } else {
      return Icons.radio_button_unchecked;
    }
  }

  Color _getPointColor() {
    if (widget.point.function.contains('Status') ||
        widget.point.name.contains('Missing')) {
      return Colors.orange;
    } else if (widget.point.function.contains('IR')) {
      return Colors.purple;
    } else if (widget.point.function.contains('Button')) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  String _getPointTypeDescription() {
    if (widget.point.function.contains('Status') ||
        widget.point.name.contains('Missing')) {
      return 'Status Point';
    } else if (widget.point.function.contains('IR')) {
      return 'IR Receiver Point';
    } else if (widget.point.function.contains('Button')) {
      return 'Button Input Point';
    } else {
      return 'Generic Point';
    }
  }
}
