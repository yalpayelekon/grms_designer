import 'dart:async';
import '../comm/router_command_service.dart';
import '../models/helvar_models/helvar_group.dart';
import '../models/helvar_models/workgroup.dart';
import '../protocol/query_commands.dart';
import '../protocol/protocol_parser.dart';
import '../utils/core/logger.dart';

class GroupPollingService {
  final RouterCommandService _commandService;
  final Map<String, Timer> _workgroupTimers = {};
  final Map<String, Timer> _groupTimers = {};
  bool _isDisposed = false;

  GroupPollingService(this._commandService);

  Function(HelvarGroup updatedGroup)? onGroupPowerUpdated;

  void startWorkgroupPolling(Workgroup workgroup) {
    if (_isDisposed || !workgroup.pollEnabled) return;

    stopWorkgroupPolling(workgroup.id);

    logInfo('Starting polling for workgroup: ${workgroup.description}');

    for (final group in workgroup.groups) {
      _startGroupPolling(workgroup, group);
    }

    logInfo(
      'Started polling for ${workgroup.groups.length} groups in workgroup ${workgroup.description}',
    );
  }

  void _startGroupPolling(Workgroup workgroup, HelvarGroup group) {
    if (_isDisposed) return;

    final groupKey = '${workgroup.id}_${group.id}';

    _groupTimers[groupKey]?.cancel();

    final intervalDuration = Duration(minutes: group.powerPollingMinutes);

    logInfo(
      'Starting polling for group ${group.groupId} with ${group.powerPollingMinutes} minute interval',
    );

    _pollGroupPowerConsumption(workgroup, group);

    _groupTimers[groupKey] = Timer.periodic(intervalDuration, (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      _pollGroupPowerConsumption(workgroup, group);
    });
  }

  void stopWorkgroupPolling(String workgroupId) {
    logInfo('Stopping polling for workgroup: $workgroupId');

    final keysToRemove = <String>[];
    for (final entry in _groupTimers.entries) {
      if (entry.key.startsWith('${workgroupId}_')) {
        entry.value.cancel();
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _groupTimers.remove(key);
    }

    _workgroupTimers[workgroupId]?.cancel();
    _workgroupTimers.remove(workgroupId);
  }

  void updateWorkgroupPolling(Workgroup workgroup) {
    if (_isDisposed) return;

    if (workgroup.pollEnabled) {
      startWorkgroupPolling(workgroup);
    } else {
      stopWorkgroupPolling(workgroup.id);
    }
  }

  void updateGroupPolling(Workgroup workgroup, HelvarGroup group) {
    if (_isDisposed || !workgroup.pollEnabled) return;

    logInfo(
      'Updating polling interval for group ${group.groupId} to ${group.powerPollingMinutes} minutes',
    );
    _startGroupPolling(workgroup, group);
  }

  Future<void> _pollGroupPowerConsumption(
    Workgroup workgroup,
    HelvarGroup group,
  ) async {
    try {
      if (_isDisposed) return;

      if (workgroup.routers.isEmpty) {
        logWarning(
          'No routers available for workgroup ${workgroup.description}',
        );
        return;
      }

      final router = workgroup.routers.first;
      final groupIdInt = int.tryParse(group.groupId);

      if (groupIdInt == null) {
        logError('Invalid group ID: ${group.groupId}');
        return;
      }

      logDebug('Polling power consumption for group ${group.groupId}');

      final powerCommand = HelvarNetCommands.queryGroupPowerConsumption(
        groupIdInt,
      );
      final powerResult = await _commandService.sendCommand(
        router.ipAddress,
        powerCommand,
      );

      if (powerResult.success && powerResult.response != null) {
        final powerValue = ProtocolParser.extractResponseValue(
          powerResult.response!,
        );

        if (powerValue != null) {
          final powerConsumption = double.tryParse(powerValue) ?? 0.0;
          final now = DateTime.now();

          final updatedGroup = group.copyWith(
            powerConsumption: powerConsumption,
            lastPowerUpdateTime: now,
          );

          logInfo(
            'Polled power consumption for group ${group.groupId}: ${powerConsumption}W',
          );

          onGroupPowerUpdated?.call(updatedGroup);
        } else {
          logWarning(
            'Empty power consumption value received for group ${group.groupId}',
          );
        }
      } else {
        logWarning(
          'Failed to poll power consumption for group ${group.groupId}: ${powerResult.response}',
        );
      }
    } catch (e) {
      logError(
        'Error polling power consumption for group ${group.groupId}: $e',
      );
    }
  }

  bool isWorkgroupPollingActive(String workgroupId) {
    return _groupTimers.keys.any((key) => key.startsWith('${workgroupId}_'));
  }

  Map<String, int> getActivePollingIntervals(String workgroupId) {
    final intervals = <String, int>{};

    for (final entry in _groupTimers.entries) {
      if (entry.key.startsWith('${workgroupId}_')) {
        final groupId = entry.key.split('_').last;
        // This would need the actual group object to get the interval
        // For now, we'll return empty map - could be enhanced
      }
    }

    return intervals;
  }

  void dispose() {
    _isDisposed = true;

    for (final timer in _workgroupTimers.values) {
      timer.cancel();
    }
    _workgroupTimers.clear();

    for (final timer in _groupTimers.values) {
      timer.cancel();
    }
    _groupTimers.clear();

    logInfo('Group polling service disposed');
  }
}
