import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/group_polling_service.dart';
import '../models/helvar_models/workgroup.dart';
import '../models/helvar_models/helvar_group.dart';
import 'router_connection_provider.dart';
import 'workgroups_provider.dart';
import '../utils/logger.dart';

final groupPollingServiceProvider = Provider<GroupPollingService>((ref) {
  final commandService = ref.watch(routerCommandServiceProvider);
  final pollingService = GroupPollingService(commandService);

  pollingService.onGroupPowerUpdated = (updatedGroup) {
    ref.read(workgroupsProvider.notifier).updateGroupFromPolling(updatedGroup);
  };

  ref.onDispose(() {
    pollingService.dispose();
  });

  return pollingService;
});

final pollingStateProvider =
    StateNotifierProvider<PollingStateNotifier, Map<String, bool>>((ref) {
      return PollingStateNotifier(ref);
    });

class PollingStateNotifier extends StateNotifier<Map<String, bool>> {
  final Ref _ref;

  PollingStateNotifier(this._ref) : super({}) {
    _ref.listen<List<Workgroup>>(workgroupsProvider, (previous, next) {
      _handleWorkgroupChanges(previous ?? [], next);
    });
  }

  void _handleWorkgroupChanges(
    List<Workgroup> previous,
    List<Workgroup> current,
  ) {
    final pollingService = _ref.read(groupPollingServiceProvider);

    for (final workgroup in current) {
      final previousWorkgroup = previous.firstWhere(
        (wg) => wg.id == workgroup.id,
        orElse: () => workgroup,
      );

      if (previousWorkgroup.pollEnabled != workgroup.pollEnabled) {
        if (workgroup.pollEnabled) {
          startPolling(workgroup.id);
        } else {
          stopPolling(workgroup.id);
        }
      }

      if (workgroup.pollEnabled && !isPolling(workgroup.id)) {
        startPolling(workgroup.id);
      }
    }

    final currentIds = current.map((wg) => wg.id).toSet();
    final previousIds = previous.map((wg) => wg.id).toSet();
    final removedIds = previousIds.difference(currentIds);

    for (final removedId in removedIds) {
      stopPolling(removedId);
    }
  }

  void startPolling(String workgroupId) {
    final workgroups = _ref.read(workgroupsProvider);
    final workgroup = workgroups.firstWhere(
      (wg) => wg.id == workgroupId,
      orElse: () => throw StateError('Workgroup not found: $workgroupId'),
    );

    if (!workgroup.pollEnabled) {
      logWarning(
        'Attempted to start polling for workgroup with polling disabled: ${workgroup.description}',
      );
      return;
    }

    final pollingService = _ref.read(groupPollingServiceProvider);
    pollingService.startWorkgroupPolling(workgroup);

    state = {...state, workgroupId: true};
    logInfo('Started polling for workgroup: ${workgroup.description}');
  }

  void stopPolling(String workgroupId) {
    final pollingService = _ref.read(groupPollingServiceProvider);
    pollingService.stopWorkgroupPolling(workgroupId);

    state = {...state, workgroupId: false};
    logInfo('Stopped polling for workgroup: $workgroupId');
  }

  void togglePolling(String workgroupId) {
    if (isPolling(workgroupId)) {
      stopPolling(workgroupId);
    } else {
      startPolling(workgroupId);
    }
  }

  bool isPolling(String workgroupId) {
    return state[workgroupId] ?? false;
  }

  void updateGroupPolling(String workgroupId, HelvarGroup group) {
    if (!isPolling(workgroupId)) return;

    final workgroups = _ref.read(workgroupsProvider);
    final workgroup = workgroups.firstWhere(
      (wg) => wg.id == workgroupId,
      orElse: () => throw StateError('Workgroup not found: $workgroupId'),
    );

    final pollingService = _ref.read(groupPollingServiceProvider);
    pollingService.updateGroupPolling(workgroup, group);
  }

  void initializePolling() {
    final workgroups = _ref.read(workgroupsProvider);

    for (final workgroup in workgroups) {
      if (workgroup.pollEnabled) {
        startPolling(workgroup.id);
      }
    }
  }
}
