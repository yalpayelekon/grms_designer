import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../providers/workgroups_provider.dart';
import '../../widgets/common/detail_card.dart';
import '../../widgets/common/expandable_list_item.dart';
import '../../utils/ui/ui_helpers.dart';

class PointPollingConfigWidget extends ConsumerStatefulWidget {
  final Workgroup workgroup;

  const PointPollingConfigWidget({super.key, required this.workgroup});

  @override
  PointPollingConfigWidgetState createState() =>
      PointPollingConfigWidgetState();
}

class PointPollingConfigWidgetState
    extends ConsumerState<PointPollingConfigWidget> {
  late PointPollingRate _config;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _config = widget.workgroup.pollingRate;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpandableListItem(
          title: 'Polling Configuration',
          initiallyExpanded: true,
          customTrailingActions: _hasChanges
              ? [
                  IconButton(
                    icon: const Icon(Icons.save, size: 16),
                    onPressed: _saveConfiguration,
                    tooltip: 'Save Changes',
                    color: Colors.green,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 16),
                    onPressed: _resetConfiguration,
                    tooltip: 'Reset Changes',
                    color: Colors.orange,
                  ),
                ]
              : null,
          children: [
            DetailRow(
              label: 'Input Point Rate',
              customValue: _buildPollingRateDropdown(
                _config,
                (rate) => _updatePollingRate(rate),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPollingRateDropdown(
    PointPollingRate currentRate,
    Function(PointPollingRate) onChanged,
  ) {
    return DropdownButton<PointPollingRate>(
      value: currentRate,
      isExpanded: true,
      items: PointPollingRate.values.map((rate) {
        return DropdownMenuItem<PointPollingRate>(
          value: rate,
          child: Row(
            children: [const SizedBox(width: 8), Text(rate.displayName)],
          ),
        );
      }).toList(),
      onChanged: (PointPollingRate? newRate) {
        if (newRate != null) {
          onChanged(newRate);
        }
      },
    );
  }

  void _updatePollingRate(PointPollingRate rate) {
    setState(() {
      _config = rate;
      _hasChanges = true;
    });
  }

  void _saveConfiguration() async {
    try {
      final updatedWorkgroup = widget.workgroup.copyWith(pollingRate: _config);

      await ref
          .read(workgroupsProvider.notifier)
          .updateWorkgroup(updatedWorkgroup);

      setState(() {
        _hasChanges = false;
      });

      if (mounted) {
        showSnackBarMsg(context, 'Point polling configuration saved');
      }
    } catch (e) {
      if (mounted) {
        showSnackBarMsg(context, 'Error saving configuration: $e');
      }
    }
  }

  void _resetConfiguration() {
    setState(() {
      _config = widget.workgroup.pollingRate;
      _hasChanges = false;
    });
  }
}
