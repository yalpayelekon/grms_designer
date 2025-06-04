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
  late DevicePointPollingConfig _config;
  bool _hasChanges = false;

  // Output point descriptions
  static const Map<int, String> _outputPointDescriptions = {
    1: 'Device State',
    2: 'Lamp Failure',
    3: 'Missing Status',
    4: 'Faulty Status',
    5: 'Output Level',
    6: 'Power Consumption',
  };

  @override
  void initState() {
    super.initState();
    _config = widget.workgroup.pointPollingConfig;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpandableListItem(
          title: 'Device Point Polling Configuration',
          leadingIcon: Icons.settings,
          leadingIconColor: Colors.blue,
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
            ExpandableListItem(
              title: 'Output Device Points',
              leadingIcon: Icons.output,
              leadingIconColor: Colors.orange,
              indentLevel: 1,
              initiallyExpanded: true,
              children: _outputPointDescriptions.entries
                  .map(
                    (entry) => _buildOutputPointConfig(entry.key, entry.value),
                  )
                  .toList(),
            ),
            ExpandableListItem(
              title: 'Input Device Points',
              leadingIcon: Icons.input,
              leadingIconColor: Colors.green,
              indentLevel: 1,
              detailRows: [
                DetailRow(
                  label: 'Input Point Rate',
                  customValue: _buildPollingRateDropdown(
                    _config.inputPointRate,
                    (rate) => _updateInputPointRate(rate),
                  ),
                ),
              ],
            ),

            // Configuration Summary
            if (widget.workgroup.pollEnabled)
              ExpandableListItem(
                title: 'Polling Summary',
                subtitle: 'Current polling configuration overview',
                leadingIcon: Icons.info_outline,
                leadingIconColor: Colors.blue,
                indentLevel: 1,
                detailRows: [
                  DetailRow(
                    label: 'Fast Points',
                    value: _getPointCountByRate(
                      PointPollingRate.fast,
                    ).toString(),
                    showDivider: true,
                  ),
                  DetailRow(
                    label: 'Normal Points',
                    value: _getPointCountByRate(
                      PointPollingRate.normal,
                    ).toString(),
                    showDivider: true,
                  ),
                  DetailRow(
                    label: 'Slow Points',
                    value: _getPointCountByRate(
                      PointPollingRate.slow,
                    ).toString(),
                    showDivider: true,
                  ),
                  DetailRow(
                    label: 'Disabled Points',
                    value: _getPointCountByRate(
                      PointPollingRate.disabled,
                    ).toString(),
                    showDivider: true,
                  ),
                  StatusDetailRow(
                    label: 'Input Points',
                    statusText: _config.inputPointRate.displayName,
                    statusColor: _getRateColor(_config.inputPointRate),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildOutputPointConfig(int pointId, String description) {
    final currentRate =
        _config.outputPointRates[pointId] ?? PointPollingRate.normal;

    return ExpandableListItem(
      title: description,
      subtitle: 'Point ID: $pointId • Rate: ${currentRate.displayName}',
      leadingIcon: _getPointIcon(pointId),
      leadingIconColor: _getRateColor(currentRate),
      indentLevel: 2,
      detailRows: [
        DetailRow(
          label: 'Polling Rate',
          customValue: _buildPollingRateDropdown(
            currentRate,
            (rate) => _updateOutputPointRate(pointId, rate),
          ),
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
            children: [
              Icon(_getRateIcon(rate), size: 16, color: _getRateColor(rate)),
              const SizedBox(width: 8),
              Text(
                rate.displayName,
                style: TextStyle(fontSize: 12, color: _getRateColor(rate)),
              ),
            ],
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

  void _updateOutputPointRate(int pointId, PointPollingRate rate) {
    setState(() {
      final newRates = Map<int, PointPollingRate>.from(
        _config.outputPointRates,
      );
      newRates[pointId] = rate;
      _config = _config.copyWith(outputPointRates: newRates);
      _hasChanges = true;
    });
  }

  void _updateInputPointRate(PointPollingRate rate) {
    setState(() {
      _config = _config.copyWith(inputPointRate: rate);
      _hasChanges = true;
    });
  }

  void _saveConfiguration() async {
    try {
      final updatedWorkgroup = widget.workgroup.copyWith(
        pointPollingConfig: _config,
      );

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
      _config = widget.workgroup.pointPollingConfig;
      _hasChanges = false;
    });
  }

  int _getPointCountByRate(PointPollingRate rate) {
    int count = _config.outputPointRates.values.where((r) => r == rate).length;
    if (_config.inputPointRate == rate) {
      count++; // Add input points
    }
    return count;
  }

  IconData _getPointIcon(int pointId) {
    switch (pointId) {
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

  IconData _getRateIcon(PointPollingRate rate) {
    switch (rate) {
      case PointPollingRate.disabled:
        return Icons.pause_circle_outline;
      case PointPollingRate.fast:
        return Icons.flash_on;
      case PointPollingRate.normal:
        return Icons.play_circle_outline;
      case PointPollingRate.slow:
        return Icons.schedule;
    }
  }

  Color _getRateColor(PointPollingRate rate) {
    switch (rate) {
      case PointPollingRate.disabled:
        return Colors.grey;
      case PointPollingRate.fast:
        return Colors.red;
      case PointPollingRate.normal:
        return Colors.green;
      case PointPollingRate.slow:
        return Colors.blue;
    }
  }
}
