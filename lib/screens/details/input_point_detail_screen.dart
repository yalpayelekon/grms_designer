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
      body: ExpandableListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          ExpandableListItem(
            title: widget.point.name,
            subtitle:
                'Function: ${widget.point.function} • ID: ${widget.point.buttonId}',
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
                label: 'Point Type',
                value: getPointTypeDescription(widget.point),
                showDivider: true,
              ),
            ],
          ),

          ExpandableListItem(
            title: 'Parent Device',
            subtitle: widget.device.description.isEmpty
                ? 'Device ${widget.device.deviceId}'
                : widget.device.description,
            leadingIcon: Icons.device_hub,
            leadingIconColor: Colors.blue,
            detailRows: [
              DetailRow(
                label: 'Device Name',
                value: widget.device.description.isEmpty
                    ? 'Device ${widget.device.deviceId}'
                    : widget.device.description,
                showDivider: true,
              ),
              DetailRow(
                label: 'Device Address',
                value: widget.device.address,
                showDivider: true,
              ),
              DetailRow(
                label: 'Device ID',
                value: widget.device.deviceId.toString(),
                showDivider: true,
              ),
              DetailRow(
                label: 'Device Type',
                value: widget.device.helvarType,
                showDivider: true,
              ),
            ],
          ),
          ExpandableListItem(
            title: 'Router Information',
            subtitle: 'Network and connection details',
            leadingIcon: Icons.router,
            leadingIconColor: Colors.purple,
            detailRows: [
              DetailRow(
                label: 'Router Description',
                value: widget.router.description,
                showDivider: true,
              ),
              DetailRow(
                label: 'Router IP',
                value: widget.router.ipAddress,
                showDivider: true,
              ),
              DetailRow(
                label: 'Router Address',
                value: widget.router.address,
                showDivider: true,
              ),
              DetailRow(
                label: 'Workgroup',
                value: widget.workgroup.description,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
