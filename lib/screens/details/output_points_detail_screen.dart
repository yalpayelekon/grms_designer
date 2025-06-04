import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/models/helvar_models/output_point.dart';
import 'package:grms_designer/utils/ui/treeview_utils.dart';
import 'package:grms_designer/widgets/common/detail_card.dart';
import 'package:grms_designer/widgets/common/expandable_list_item.dart';
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
      body: ExpandableListView(
        padding: const EdgeInsets.all(8.0),
        children: [
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
                label: 'Current Level',
                value: '${outputDevice.level}%',
                showDivider: true,
              ),
              DetailRow(
                label: 'Power Consumption',
                value: '${outputDevice.powerConsumption.toStringAsFixed(1)}W',
              ),
            ],
          ),
          ExpandableListItem(
            title: 'Output Points',
            subtitle: '${outputDevice.outputPoints.length} configured points',
            leadingIcon: Icons.output,
            leadingIconColor: Colors.orange,
            initiallyExpanded: true,
            children: outputDevice.outputPoints
                .map((point) => _buildPointItem(point))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPointItem(OutputPoint point) {
    return ExpandableListItem(
      title: point.function,
      leadingIcon: getOutputPointIcon(point),
      leadingIconColor: getOutputPointValueColor(point),
      indentLevel: 1,
      detailRows: [
        DetailRow(label: 'Point Name', value: point.name, showDivider: true),
        DetailRow(label: 'Function', value: point.function, showDivider: true),
        DetailRow(
          label: 'Point Type',
          value: point.pointType,
          showDivider: true,
        ),
        DetailRow(
          label: 'Current Value',
          customValue: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: getOutputPointValueColor(
                point,
              ).withValues(alpha: 0.1 * 255),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: getOutputPointValueColor(
                  point,
                ).withValues(alpha: 0.3 * 255),
              ),
            ),
            child: Text(
              formatOutputPointValue(point),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: getOutputPointValueColor(point),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
