import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/models/helvar_models/output_device.dart';
import 'package:grms_designer/providers/workgroups_provider.dart';
import 'package:grms_designer/utils/device/device_utils.dart';
import 'package:grms_designer/utils/ui/treeview_utils.dart';
import 'package:grms_designer/utils/ui/ui_helpers.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/output_point.dart';

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
  late PointPollingRate _selectedPollingRate;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _selectedPollingRate = widget.point.pollingRate;
  }

  void _updatePollingRate(PointPollingRate newRate) {
    setState(() {
      _selectedPollingRate = newRate;
      _hasChanges = _selectedPollingRate != widget.point.pollingRate;
    });
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges) return;

    try {
      final outputDevice = widget.device as HelvarDriverOutputDevice;
      final pointIndex = outputDevice.outputPoints.indexWhere(
        (p) => p.pointId == widget.point.pointId,
      );

      if (pointIndex != -1) {
        final updatedPoint = outputDevice.outputPoints[pointIndex].copyWith(
          pollingRate: _selectedPollingRate,
        );

        final updatedPoints = List<OutputPoint>.from(outputDevice.outputPoints);
        updatedPoints[pointIndex] = updatedPoint;

        final updatedDevice = HelvarDriverOutputDevice(
          deviceId: outputDevice.deviceId,
          address: outputDevice.address,
          state: outputDevice.state,
          description: outputDevice.description,
          name: outputDevice.name,
          props: outputDevice.props,
          iconPath: outputDevice.iconPath,
          hexId: outputDevice.hexId,
          addressingScheme: outputDevice.addressingScheme,
          emergency: outputDevice.emergency,
          blockId: outputDevice.blockId,
          sceneId: outputDevice.sceneId,
          out: outputDevice.out,
          helvarType: outputDevice.helvarType,
          deviceTypeCode: outputDevice.deviceTypeCode,
          deviceStateCode: outputDevice.deviceStateCode,
          isButtonDevice: outputDevice.isButtonDevice,
          isMultisensor: outputDevice.isMultisensor,
          sensorInfo: outputDevice.sensorInfo,
          additionalInfo: outputDevice.additionalInfo,
          missing: outputDevice.missing,
          faulty: outputDevice.faulty,
          level: outputDevice.level,
          proportion: outputDevice.proportion,
          powerConsumption: outputDevice.powerConsumption,
          outputPoints: updatedPoints,
        );

        await ref
            .read(workgroupsProvider.notifier)
            .updateDeviceInRouter(
              widget.workgroup.id,
              widget.router.address,
              widget.device,
              updatedDevice,
            );

        setState(() {
          _hasChanges = false;
        });

        if (mounted) {
          showSnackBarMsg(context, 'Polling rate updated successfully');
        }
      }
    } catch (e) {
      if (mounted) {
        showSnackBarMsg(context, 'Error updating polling rate: $e');
      }
    }
  }

  void _resetChanges() {
    setState(() {
      _selectedPollingRate = widget.point.pollingRate;
      _hasChanges = false;
    });
  }

  String _getDurationDisplay(PointPollingRate rate) {
    final duration = widget.workgroup.getDurationForRate(rate);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.router.description} - ${widget.point.function}'),
        centerTitle: true,
        actions: _hasChanges
            ? [
                IconButton(
                  onPressed: _resetChanges,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reset Changes',
                ),
                IconButton(
                  onPressed: _saveChanges,
                  icon: const Icon(Icons.save),
                  tooltip: 'Save Changes',
                ),
              ]
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPointInfoCard(),
            const SizedBox(height: 16),
            _buildPollingConfigCard(),
          ],
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
                Icon(
                  getOutputPointIcon(widget.point),
                  size: 32,
                  color: getOutputPointColor(widget.point),
                ),
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
            buildInfoRow(
              'Parent Device',
              widget.device.description.isEmpty
                  ? 'Device ${widget.device.deviceId}'
                  : widget.device.description,
            ),
            buildInfoRow('Device Address', widget.device.address),
          ],
        ),
      ),
    );
  }

  Widget _buildPollingConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Polling Configuration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            buildInfoRow('Current Rate', _selectedPollingRate.displayName),
            buildInfoRow('Duration', _getDurationDisplay(_selectedPollingRate)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Polling Rate:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<PointPollingRate>(
                    value: _selectedPollingRate,
                    isExpanded: true,
                    onChanged: (PointPollingRate? newRate) {
                      if (newRate != null) {
                        _updatePollingRate(newRate);
                      }
                    },
                    items: PointPollingRate.values.map((rate) {
                      return DropdownMenuItem<PointPollingRate>(
                        value: rate,
                        child: Text(
                          '${rate.displayName} (${_getDurationDisplay(rate)})',
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
