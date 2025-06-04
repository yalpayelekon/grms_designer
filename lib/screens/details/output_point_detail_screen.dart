import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/models/helvar_models/output_device.dart';
import 'package:grms_designer/providers/workgroups_provider.dart';
import 'package:grms_designer/utils/ui/treeview_utils.dart';
import 'package:grms_designer/utils/ui/ui_helpers.dart';
import 'package:grms_designer/widgets/common/detail_card.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/output_point.dart';

class OutputPointDetailScreen extends ConsumerStatefulWidget {
  final Workgroup workgroup;
  final HelvarRouter router;
  final HelvarDevice device;
  final OutputPoint point;
  final bool asWidget;

  const OutputPointDetailScreen({
    super.key,
    required this.workgroup,
    required this.router,
    required this.device,
    required this.point,
    this.asWidget = false,
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

  Widget _buildContent() {
    return DetailRowsList(
      children: [
        DetailRow(
          label: 'Point Name',
          value: widget.point.name,
          showDivider: true,
        ),
        DetailRow(
          label: 'Function',
          value: widget.point.function,
          showDivider: true,
        ),
        DetailRow(
          label: 'Current Value',
          value: formatOutputPointValue(widget.point),
          showDivider: true,
        ),
        DetailRow(
          label: 'Device Address',
          value: widget.device.address,
          showDivider: true,
        ),
        DetailRow(
          label: 'Current Polling Rate',
          value: _getDurationDisplay(_selectedPollingRate),
          showDivider: true,
        ),
        DetailRow(
          label: 'Polling Frequency',
          customValue: DropdownButton<PointPollingRate>(
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
                  style: const TextStyle(fontSize: 11),
                  '${rate.displayName} (${_getDurationDisplay(rate)})',
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.asWidget) {
      return _buildContent();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.device.name} - ${widget.point.function}'),
        centerTitle: true,
        actions: _hasChanges
            ? [
                TextButton(
                  onPressed: _resetChanges,
                  child: const Text('Reset'),
                ),
                TextButton(onPressed: _saveChanges, child: const Text('Save')),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: _buildContent(),
      ),
    );
  }
}
