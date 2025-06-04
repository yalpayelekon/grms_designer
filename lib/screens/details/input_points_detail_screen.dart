import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/utils/device/device_utils.dart';
import 'package:grms_designer/widgets/common/detail_card.dart';
import 'package:grms_designer/widgets/common/expandable_list_item.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/input_device.dart';
import '../../utils/ui/treeview_utils.dart';

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
  @override
  Widget build(BuildContext context) {
    final inputDevice = widget.device as HelvarDriverInputDevice;
    final deviceName = widget.device.description.isEmpty
        ? 'Device ${widget.device.deviceId}'
        : widget.device.description;

    return Scaffold(
      appBar: AppBar(title: Text('Points - $deviceName'), centerTitle: true),
      body: inputDevice.buttonPoints.isEmpty
          ? _buildEmptyState()
          : ExpandableListView(
              padding: const EdgeInsets.all(8.0),
              children: [
                // Device Information
                ExpandableListItem(
                  title: 'Device Information',
                  subtitle: 'Basic device details and configuration',
                  leadingIcon: Icons.info_outline,
                  leadingIconColor: Colors.blue,
                  initiallyExpanded: true,
                  detailRows: [
                    DetailRow(
                      label: 'Device Name',
                      value: deviceName,
                      showDivider: true,
                    ),
                    DetailRow(
                      label: 'Device Address',
                      value: widget.device.address,
                      showDivider: true,
                    ),
                    DetailRow(
                      label: 'Device Type',
                      value: widget.device.helvarType,
                      showDivider: true,
                    ),
                    DetailRow(
                      label: 'Total Points',
                      value: '${inputDevice.buttonPoints.length} points',
                      showDivider: true,
                    ),
                    StatusDetailRow(
                      label: 'Button Device',
                      statusText: widget.device.isButtonDevice ? 'Yes' : 'No',
                      statusColor: widget.device.isButtonDevice
                          ? Colors.green
                          : Colors.grey,
                      showDivider: true,
                    ),
                    StatusDetailRow(
                      label: 'Multisensor',
                      statusText: widget.device.isMultisensor ? 'Yes' : 'No',
                      statusColor: widget.device.isMultisensor
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ],
                ),

                // Input Points
                ExpandableListItem(
                  title: 'Input Points',
                  subtitle:
                      '${inputDevice.buttonPoints.length} configured points',
                  leadingIcon: Icons.touch_app,
                  leadingIconColor: Colors.green,
                  initiallyExpanded: true,
                  children: inputDevice.buttonPoints
                      .map((point) => _buildPointItem(point))
                      .toList(),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.radio_button_unchecked, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No points available for this device',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildPointItem(ButtonPoint point) {
    final pointIcon = getButtonPointIcon(point);
    final pointColor = _getPointColor(point);
    final displayName = getButtonPointDisplayName(point);

    return ExpandableListItem(
      title: displayName,
      leadingIcon: pointIcon,
      leadingIconColor: pointColor,
      indentLevel: 1,
      detailRows: [
        DetailRow(label: 'Point Name', value: point.name, showDivider: true),
        DetailRow(
          label: 'Function Type',
          value: point.function,
          showDivider: true,
        ),
        DetailRow(
          label: 'Button ID',
          value: point.buttonId.toString(),
          showDivider: true,
        ),
        DetailRow(
          label: 'Point Type',
          value: getPointTypeDescription(point),
          showDivider: true,
        ),
        StatusDetailRow(
          label: 'Status',
          statusText: _getPointStatus(point),
          statusColor: _getPointStatusColor(point),
        ),
      ],
    );
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

  String _getPointStatus(ButtonPoint point) {
    if (point.function.contains('Status') || point.name.contains('Missing')) {
      return 'Monitoring';
    } else if (point.function.contains('IR')) {
      return 'Listening';
    } else {
      return 'Ready';
    }
  }

  Color _getPointStatusColor(ButtonPoint point) {
    if (point.function.contains('Status') || point.name.contains('Missing')) {
      return Colors.orange;
    } else if (point.function.contains('IR')) {
      return Colors.purple;
    } else {
      return Colors.green;
    }
  }
}
