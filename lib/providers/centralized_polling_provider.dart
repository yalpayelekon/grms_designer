import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/comm/router_command_service.dart';
import 'package:grms_designer/utils/core/logger.dart';
import '../services/polling/centralized_polling_service.dart';
import '../services/polling/polling_task.dart';
import '../services/polling/device_point_polling_task.dart';
import '../models/helvar_models/workgroup.dart';
import '../models/helvar_models/helvar_device.dart';
import '../models/helvar_models/output_device.dart';
import '../models/helvar_models/input_device.dart';
import 'router_connection_provider.dart';
import 'workgroups_provider.dart';

final centralizedPollingServiceProvider = Provider<CentralizedPollingService>((
  ref,
) {
  final service = CentralizedPollingService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

final pollingTaskUpdatesProvider = StreamProvider<PollingTaskInfo>((ref) {
  final service = ref.watch(centralizedPollingServiceProvider);
  return service.taskUpdates;
});

final pollingStatisticsProvider = Provider<Map<String, dynamic>>((ref) {
  ref.watch(pollingTaskUpdatesProvider);

  final service = ref.watch(centralizedPollingServiceProvider);
  return service.getStatistics();
});

final pollingTasksProvider = Provider<Map<String, PollingTaskInfo>>((ref) {
  ref.watch(pollingTaskUpdatesProvider);

  final service = ref.watch(centralizedPollingServiceProvider);
  return service.tasks;
});

class PollingManager extends StateNotifier<Map<String, bool>> {
  final Ref _ref;
  bool _disposed = false;

  PollingManager(this._ref) : super({}) {
    _ref.listen<List<Workgroup>>(workgroupsProvider, (previous, next) {
      if (!_disposed) {
        _handleWorkgroupChanges(previous ?? [], next);
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _handleWorkgroupChanges(
    List<Workgroup> previous,
    List<Workgroup> current,
  ) {
    final pollingService = _ref.read(centralizedPollingServiceProvider);
    final commandService = _ref.read(routerCommandServiceProvider);

    for (final workgroup in current) {
      final previousWorkgroup = previous.firstWhere(
        (wg) => wg.id == workgroup.id,
        orElse: () => workgroup,
      );

      if (previousWorkgroup.pollEnabled != workgroup.pollEnabled) {
        if (workgroup.pollEnabled) {
          _startWorkgroupPolling(workgroup);
        } else {
          _stopWorkgroupPolling(workgroup);
        }
      }

      if (workgroup.pollEnabled) {
        _ensureDevicePointPollingTasks(
          workgroup,
          commandService,
          pollingService,
        );
      }
    }

    final currentIds = current.map((wg) => wg.id).toSet();
    final previousIds = previous.map((wg) => wg.id).toSet();
    final removedIds = previousIds.difference(currentIds);

    for (final removedId in removedIds) {
      _stopWorkgroupPollingById(removedId, pollingService);
    }
  }

  void _ensureDevicePointPollingTasks(
    Workgroup workgroup,
    RouterCommandService commandService,
    CentralizedPollingService pollingService,
  ) {
    for (final router in workgroup.routers) {
      for (final device in router.devices) {
        if (_hasPollingPoints(device)) {
          final taskId = 'device_points_${workgroup.id}_${device.address}';

          if (pollingService.getTaskInfo(taskId) != null) {
            continue;
          }

          final task = DevicePointPollingTask(
            commandService: commandService,
            workgroup: workgroup,
            router: router,
            device: device,
            onPointsUpdated: (updatedDevice) {
              _ref
                  .read(workgroupsProvider.notifier)
                  .updateDeviceInRouter(
                    workgroup.id,
                    router.address,
                    device,
                    updatedDevice,
                  );
            },
          );

          pollingService.registerTask(task);
        }
      }
    }
  }

  // Helper method to check if device has polling points
  bool _hasPollingPoints(HelvarDevice device) {
    if (device is HelvarDriverOutputDevice) {
      return device.outputPoints.isNotEmpty;
    } else if (device is HelvarDriverInputDevice) {
      return device.buttonPoints.isNotEmpty;
    }
    return false;
  }

  void _stopWorkgroupPolling(Workgroup workgroup) {
    _stopWorkgroupPollingById(
      workgroup.id,
      _ref.read(centralizedPollingServiceProvider),
    );
  }

  void _stopWorkgroupPollingById(
    String workgroupId,
    CentralizedPollingService pollingService,
  ) {
    logInfo('Stopping device point polling for workgroup: $workgroupId');

    final tasksToRemove = <String>[];
    for (final taskInfo in pollingService.tasks.values) {
      if (taskInfo.task.id.contains(workgroupId)) {
        tasksToRemove.add(taskInfo.task.id);
      }
    }

    for (final taskId in tasksToRemove) {
      pollingService.unregisterTask(taskId);
    }

    final newState = Map<String, bool>.from(state);
    newState[workgroupId] = false;
    state = newState;
  }

  Future<void> startWorkgroupPolling(String workgroupId) async {
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

    _startWorkgroupPolling(workgroup);
  }

  void stopWorkgroupPolling(String workgroupId) {
    _stopWorkgroupPollingById(
      workgroupId,
      _ref.read(centralizedPollingServiceProvider),
    );
  }

  void _startWorkgroupPolling(Workgroup workgroup) {
    final pollingService = _ref.read(centralizedPollingServiceProvider);
    final commandService = _ref.read(routerCommandServiceProvider);

    logInfo(
      'Starting device point polling for workgroup: ${workgroup.description}',
    );

    _ensureDevicePointPollingTasks(workgroup, commandService, pollingService);

    for (final router in workgroup.routers) {
      for (final device in router.devices) {
        if (_hasPollingPoints(device)) {
          final taskId = 'device_points_${workgroup.id}_${device.address}';
          pollingService.startTask(taskId);
        }
      }
    }

    final newState = Map<String, bool>.from(state);
    newState[workgroup.id] = true;
    state = newState;
  }

  Future<PollingResult?> executeTaskNow(String taskId) async {
    final pollingService = _ref.read(centralizedPollingServiceProvider);
    return await pollingService.executeTaskNow(taskId);
  }

  bool isWorkgroupPolling(String workgroupId) {
    return state[workgroupId] ?? false;
  }

  List<PollingTaskInfo> getActiveTasks() {
    final pollingService = _ref.read(centralizedPollingServiceProvider);
    return pollingService.getTasksByState(PollingTaskState.running);
  }

  void pauseAllPolling() {
    final pollingService = _ref.read(centralizedPollingServiceProvider);
    pollingService.pauseAllTasks();

    final newState = <String, bool>{};
    for (final key in state.keys) {
      newState[key] = false;
    }
    state = newState;

    logInfo('Paused all polling tasks');
  }

  Future<void> resumeAllPolling() async {
    final pollingService = _ref.read(centralizedPollingServiceProvider);
    await pollingService.resumeAllTasks();

    final workgroups = _ref.read(workgroupsProvider);
    final newState = <String, bool>{};

    for (final workgroup in workgroups) {
      if (workgroup.pollEnabled) {
        newState[workgroup.id] = true;
      }
    }
    state = newState;

    logInfo('Resumed all polling tasks');
  }
}

final pollingManagerProvider =
    StateNotifierProvider<PollingManager, Map<String, bool>>((ref) {
      return PollingManager(ref);
    });
