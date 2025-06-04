import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/providers/workgroups_provider.dart';
import 'package:grms_designer/utils/ui/ui_helpers.dart';
import 'package:grms_designer/widgets/common/detail_card.dart';
import 'package:grms_designer/widgets/common/expandable_list_item.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/input_device.dart';
import '../../utils/ui/treeview_utils.dart';

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
      final inputDevice = widget.device as HelvarDriverInputDevice;
      final pointIndex = inputDevice.buttonPoints.indexWhere(
        (p) =>
            p.buttonId == widget.point.buttonId && p.name == widget.point.name,
      );

      if (pointIndex != -1) {
        final updatedPoint = inputDevice.buttonPoints[pointIndex].copyWith(
          pollingRate: _selectedPollingRate,
        );

        final updatedPoints = List<ButtonPoint>.from(inputDevice.buttonPoints);
        updatedPoints[pointIndex] = updatedPoint;

        final updatedDevice = HelvarDriverInputDevice(
          deviceId: inputDevice.deviceId,
          address: inputDevice.address,
          state: inputDevice.state,
          description: inputDevice.description,
          name: inputDevice.name,
          props: inputDevice.props,
          iconPath: inputDevice.iconPath,
          hexId: inputDevice.hexId,
          addressingScheme: inputDevice.addressingScheme,
          emergency: inputDevice.emergency,
          blockId: inputDevice.blockId,
          sceneId: inputDevice.sceneId,
          out: inputDevice.out,
          helvarType: inputDevice.helvarType,
          deviceTypeCode: inputDevice.deviceTypeCode,
          deviceStateCode: inputDevice.deviceStateCode,
          isButtonDevice: inputDevice.isButtonDevice,
          isMultisensor: inputDevice.isMultisensor,
          sensorInfo: inputDevice.sensorInfo,
          additionalInfo: inputDevice.additionalInfo,
          buttonPoints: updatedPoints,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.router.description} - ${widget.point.name}'),
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
      body: ExpandableListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          ExpandableListItem(
            title: widget.point.name,
            leadingIcon: getButtonPointIcon(widget.point),
            leadingIconColor: null,
            initiallyExpanded: true,
            detailRows: [
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
                label: 'Button ID',
                value: widget.point.buttonId.toString(),
                showDivider: true,
              ),
              DetailRow(
                label: 'Polling Rate',
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
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          Text(
                            '${rate.displayName} (${_getDurationDisplay(rate)})',
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                showDivider: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
