import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/widgets/common/detail_card.dart';
import 'package:grms_designer/widgets/common/expandable_list_item.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/input_device.dart';
import '../../utils/ui/treeview_utils.dart';
import 'input_point_detail_screen.dart';

class PointsDetailScreen extends ConsumerStatefulWidget {
  final Workgroup workgroup;
  final HelvarRouter router;
  final HelvarDevice device;
  final bool asWidget;
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
    this.asWidget = false,
    this.onNavigate,
  });

  @override
  PointsDetailScreenState createState() => PointsDetailScreenState();
}

class PointsDetailScreenState extends ConsumerState<PointsDetailScreen> {
  Widget _buildDeviceInfo() {
    final deviceName = widget.device.description.isEmpty
        ? 'Device ${widget.device.deviceId}'
        : widget.device.description;

    return ExpandableListItem(
      title: 'Device Information',
      subtitle: 'Basic device details and configuration',
      leadingIcon: Icons.info_outline,
      leadingIconColor: Colors.blue,
      initiallyExpanded: true,
      detailRows: [
        DetailRow(label: 'Device Name', value: deviceName, showDivider: true),
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
          statusColor: widget.device.isMultisensor ? Colors.green : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildInputPointsSection() {
    final inputDevice = widget.device as HelvarDriverInputDevice;

    return ExpandableListItem(
      title: 'Input Points',
      subtitle: '${inputDevice.buttonPoints.length} configured points',
      leadingIcon: Icons.touch_app,
      leadingIconColor: Colors.green,
      initiallyExpanded: true,
      children: inputDevice.buttonPoints
          .map((point) => _buildPointItem(point))
          .toList(),
    );
  }

  void _navigateToInputPointDetail(ButtonPoint point) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(
        'inputPointDetail',
        workgroup: widget.workgroup,
        router: widget.router,
        device: widget.device,
        point: point,
      );
    }
  }

  Widget _buildPointItem(ButtonPoint point) {
    final displayName = getButtonPointDisplayName(point);

    return ExpandableListItem(
      title: displayName,
      leadingIcon: getButtonPointIcon(point),
      leadingIconColor: null,
      indentLevel: 1,
      onSecondaryTap: widget.onNavigate != null
          ? () => _navigateToInputPointDetail(point)
          : null,
      children: [
        InputPointDetailScreen(
          workgroup: widget.workgroup,
          router: widget.router,
          device: widget.device,
          point: point,
          asWidget: true,
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (widget.asWidget) {
      final inputDevice = widget.device as HelvarDriverInputDevice;
      return Column(
        children: inputDevice.buttonPoints
            .map((point) => _buildPointItem(point))
            .toList(),
      );
    }

    return ExpandableListView(
      padding: const EdgeInsets.all(8.0),
      children: [_buildDeviceInfo(), _buildInputPointsSection()],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.asWidget) {
      return _buildContent();
    }

    final deviceName = widget.device.description.isEmpty
        ? 'Device ${widget.device.deviceId}'
        : widget.device.description;

    return Scaffold(
      appBar: AppBar(title: Text('Points - $deviceName'), centerTitle: true),
      body: _buildContent(),
    );
  }
}
