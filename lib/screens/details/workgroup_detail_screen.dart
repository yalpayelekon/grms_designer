import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/providers/centralized_polling_provider.dart';
import 'package:grms_designer/utils/core/date_utils.dart';
import 'package:grms_designer/utils/ui/ui_helpers.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../providers/workgroups_provider.dart';
import '../../widgets/common/detail_card.dart';
import '../../widgets/common/expandable_list_item.dart';
import '../lists/groups_list_screen.dart';
import 'router_detail_screen.dart';

class WorkgroupDetailScreen extends ConsumerStatefulWidget {
  final Workgroup workgroup;
  final bool asWidget;

  const WorkgroupDetailScreen({
    super.key,
    required this.workgroup,
    this.asWidget = false,
  });

  @override
  WorkgroupDetailScreenState createState() => WorkgroupDetailScreenState();
}

class WorkgroupDetailScreenState extends ConsumerState<WorkgroupDetailScreen> {
  bool _isLoading = false;
  bool _hasChanges = false;
  late TextEditingController _fastHoursController;
  late TextEditingController _fastMinutesController;
  late TextEditingController _fastSecondsController;
  late TextEditingController _normalHoursController;
  late TextEditingController _normalMinutesController;
  late TextEditingController _normalSecondsController;
  late TextEditingController _slowHoursController;
  late TextEditingController _slowMinutesController;
  late TextEditingController _slowSecondsController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final workgroup = widget.workgroup;

    _fastHoursController = TextEditingController(
      text: workgroup.fastRate.hours.toString(),
    );
    _fastMinutesController = TextEditingController(
      text: workgroup.fastRate.minutes.toString(),
    );
    _fastSecondsController = TextEditingController(
      text: workgroup.fastRate.seconds.toString(),
    );

    _normalHoursController = TextEditingController(
      text: workgroup.normalRate.hours.toString(),
    );
    _normalMinutesController = TextEditingController(
      text: workgroup.normalRate.minutes.toString(),
    );
    _normalSecondsController = TextEditingController(
      text: workgroup.normalRate.seconds.toString(),
    );

    _slowHoursController = TextEditingController(
      text: workgroup.slowRate.hours.toString(),
    );
    _slowMinutesController = TextEditingController(
      text: workgroup.slowRate.minutes.toString(),
    );
    _slowSecondsController = TextEditingController(
      text: workgroup.slowRate.seconds.toString(),
    );

    _addChangeListeners();
  }

  void _addChangeListeners() {
    _fastHoursController.addListener(_onDurationChanged);
    _fastMinutesController.addListener(_onDurationChanged);
    _fastSecondsController.addListener(_onDurationChanged);
    _normalHoursController.addListener(_onDurationChanged);
    _normalMinutesController.addListener(_onDurationChanged);
    _normalSecondsController.addListener(_onDurationChanged);
    _slowHoursController.addListener(_onDurationChanged);
    _slowMinutesController.addListener(_onDurationChanged);
    _slowSecondsController.addListener(_onDurationChanged);
  }

  void _onDurationChanged() {
    setState(() {
      _hasChanges = _checkForChanges();
    });
  }

  bool _checkForChanges() {
    final workgroup = currentWorkgroup;
    return _fastHoursController.text != workgroup.fastRate.hours.toString() ||
        _fastMinutesController.text != workgroup.fastRate.minutes.toString() ||
        _fastSecondsController.text != workgroup.fastRate.seconds.toString() ||
        _normalHoursController.text != workgroup.normalRate.hours.toString() ||
        _normalMinutesController.text !=
            workgroup.normalRate.minutes.toString() ||
        _normalSecondsController.text !=
            workgroup.normalRate.seconds.toString() ||
        _slowHoursController.text != workgroup.slowRate.hours.toString() ||
        _slowMinutesController.text != workgroup.slowRate.minutes.toString() ||
        _slowSecondsController.text != workgroup.slowRate.seconds.toString();
  }

  @override
  void dispose() {
    _fastHoursController.dispose();
    _fastMinutesController.dispose();
    _fastSecondsController.dispose();
    _normalHoursController.dispose();
    _normalMinutesController.dispose();
    _normalSecondsController.dispose();
    _slowHoursController.dispose();
    _slowMinutesController.dispose();
    _slowSecondsController.dispose();
    super.dispose();
  }

  Workgroup get currentWorkgroup {
    final workgroups = ref.watch(workgroupsProvider);
    return workgroups.firstWhere(
      (wg) => wg.id == widget.workgroup.id,
      orElse: () => widget.workgroup,
    );
  }

  Widget _buildWorkgroupInfo() {
    final workgroup = currentWorkgroup;

    return ExpandableListItem(
      title: 'Workgroup Details',
      subtitle: 'Basic configuration and settings',
      leadingIcon: Icons.info_outline,
      leadingIconColor: Colors.blue,
      initiallyExpanded: true,
      detailRows: [
        DetailRow(label: 'ID', value: workgroup.id, showDivider: true),
        DetailRow(
          label: 'Description',
          value: workgroup.description,
          showDivider: true,
        ),
        DetailRow(
          label: 'Refresh Props After Action',
          value: workgroup.refreshPropsAfterAction.toString(),
        ),
      ],
    );
  }

  Widget _buildPollingConfigSection() {
    final workgroup = currentWorkgroup;

    return ExpandableListItem(
      title: 'Polling Configuration',
      initiallyExpanded: true,
      detailRows: [
        DetailRow(
          label: 'Polling',
          customValue: DropdownButton<bool>(
            value: workgroup.pollEnabled,
            isExpanded: true,
            onChanged: (bool? newValue) {
              if (newValue != null) {
                _togglePolling(newValue);
              }
            },
            items: const [
              DropdownMenuItem<bool>(
                value: false,
                child: Row(children: [SizedBox(width: 8), Text('Disabled')]),
              ),
              DropdownMenuItem<bool>(
                value: true,
                child: Row(children: [SizedBox(width: 8), Text('Enabled')]),
              ),
            ],
          ),
          showDivider: true,
        ),
        if (workgroup.lastPollTime != null)
          DetailRow(
            label: 'Last Poll Started',
            value: formatDateTime(workgroup.lastPollTime!),
            showDivider: true,
          ),
      ],
      lazyChildren: () => [_buildPollingDurationSection()],
    );
  }

  Widget _buildPollingDurationSection() {
    return ExpandableListItem(
      title: 'Polling Rate Durations',
      subtitle: 'Configure duration values for each polling rate',
      leadingIcon: Icons.schedule,
      leadingIconColor: Colors.blue,
      initiallyExpanded: true,
      lazyChildren: () => [
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildDurationRow(
                'Fast Rate',
                _fastHoursController,
                _fastMinutesController,
                _fastSecondsController,
              ),
              const SizedBox(height: 12),
              _buildDurationRow(
                'Normal Rate',
                _normalHoursController,
                _normalMinutesController,
                _normalSecondsController,
              ),
              const SizedBox(height: 12),
              _buildDurationRow(
                'Slow Rate',
                _slowHoursController,
                _slowMinutesController,
                _slowSecondsController,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationRow(
    String label,
    TextEditingController hoursController,
    TextEditingController minutesController,
    TextEditingController secondsController,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        _buildTimeField(hoursController, 'h', 23),
        const Text(' : '),
        _buildTimeField(minutesController, 'm', 59),
        const Text(' : '),
        _buildTimeField(secondsController, 's', 59),
      ],
    );
  }

  Widget _buildTimeField(
    TextEditingController controller,
    String suffix,
    int maxValue,
  ) {
    return SizedBox(
      width: 50,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 8,
          ),
          border: const OutlineInputBorder(),
          suffixText: suffix,
        ),
        onChanged: (value) {
          final intValue = int.tryParse(value);
          if (intValue != null && (intValue < 0 || intValue > maxValue)) {
            controller.text = intValue.clamp(0, maxValue).toString();
            controller.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length),
            );
          }
        },
      ),
    );
  }

  Widget _buildGroupsSection() {
    final workgroup = currentWorkgroup;

    if (workgroup.groups.isEmpty) {
      return const SizedBox.shrink();
    }

    return ExpandableListItem(
      title: 'Groups',
      subtitle: '${workgroup.groups.length} groups configured',
      leadingIcon: Icons.layers,
      leadingIconColor: Colors.green,
      lazyChildren: () => [
        GroupsListScreen(workgroup: workgroup, asWidget: true),
      ],
    );
  }

  Widget _buildRoutersSection() {
    final workgroup = currentWorkgroup;

    if (workgroup.routers.isEmpty) {
      return const SizedBox.shrink();
    }

    return ExpandableListItem(
      title: 'Routers and Devices',
      leadingIcon: Icons.router,
      leadingIconColor: Colors.purple,
      lazyChildren: () =>
          workgroup.routers.map((router) => _buildRouterItem(router)).toList(),
    );
  }

  Widget _buildRouterItem(HelvarRouter router) {
    return ExpandableListItem(
      title: router.description,
      subtitle:
          'IP: ${router.ipAddress} • Address: ${router.address} • ${router.devices.length} devices',
      leadingIcon: Icons.router,
      leadingIconColor: Colors.purple,
      indentLevel: 1,
      lazyChildren: () => [
        RouterDetailScreen(
          workgroup: currentWorkgroup,
          router: router,
          asWidget: true,
        ),
      ],
    );
  }

  void _togglePolling(bool enabled) async {
    setState(() => _isLoading = true);

    try {
      await ref
          .read(workgroupsProvider.notifier)
          .toggleWorkgroupPolling(widget.workgroup.id, enabled);

      final pollingManager = ref.read(pollingManagerProvider.notifier);
      if (enabled) {
        await pollingManager.startWorkgroupPolling(widget.workgroup.id);
      } else {
        pollingManager.stopWorkgroupPolling(widget.workgroup.id);
      }
    } catch (e) {
      if (mounted) {
        showSnackBarMsg(context, 'Error toggling polling: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges) return;

    setState(() => _isLoading = true);

    try {
      final fastRate = PollingRateDuration(
        hours: int.tryParse(_fastHoursController.text) ?? 0,
        minutes: int.tryParse(_fastMinutesController.text) ?? 0,
        seconds: int.tryParse(_fastSecondsController.text) ?? 10,
      );

      final normalRate = PollingRateDuration(
        hours: int.tryParse(_normalHoursController.text) ?? 0,
        minutes: int.tryParse(_normalMinutesController.text) ?? 1,
        seconds: int.tryParse(_normalSecondsController.text) ?? 0,
      );

      final slowRate = PollingRateDuration(
        hours: int.tryParse(_slowHoursController.text) ?? 0,
        minutes: int.tryParse(_slowMinutesController.text) ?? 5,
        seconds: int.tryParse(_slowSecondsController.text) ?? 0,
      );

      final updatedWorkgroup = currentWorkgroup.copyWith(
        fastRate: fastRate,
        normalRate: normalRate,
        slowRate: slowRate,
      );

      await ref
          .read(workgroupsProvider.notifier)
          .updateWorkgroup(updatedWorkgroup);

      setState(() {
        _hasChanges = false;
      });

      if (mounted) {
        showSnackBarMsg(context, 'Polling duration configuration saved');
      }
    } catch (e) {
      if (mounted) {
        showSnackBarMsg(context, 'Error saving configuration: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetChanges() {
    final workgroup = currentWorkgroup;

    _fastHoursController.text = workgroup.fastRate.hours.toString();
    _fastMinutesController.text = workgroup.fastRate.minutes.toString();
    _fastSecondsController.text = workgroup.fastRate.seconds.toString();

    _normalHoursController.text = workgroup.normalRate.hours.toString();
    _normalMinutesController.text = workgroup.normalRate.minutes.toString();
    _normalSecondsController.text = workgroup.normalRate.seconds.toString();

    _slowHoursController.text = workgroup.slowRate.hours.toString();
    _slowMinutesController.text = workgroup.slowRate.minutes.toString();
    _slowSecondsController.text = workgroup.slowRate.seconds.toString();

    setState(() {
      _hasChanges = false;
    });
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ExpandableListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        if (!widget.asWidget) _buildWorkgroupInfo(),
        if (!widget.asWidget) _buildPollingConfigSection(),
        _buildGroupsSection(),
        _buildRoutersSection(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.asWidget) {
      return _buildContent();
    }

    final workgroup = currentWorkgroup;

    return Scaffold(
      appBar: AppBar(
        title: Text(workgroup.description),
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
      body: _buildContent(),
    );
  }
}
