import 'package:grms_designer/utils/core/logger.dart';

import '../../comm/router_command_service.dart';
import '../../models/helvar_models/helvar_group.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../protocol/query_commands.dart';
import '../../protocol/protocol_parser.dart';
import 'polling_task.dart';

class GroupPowerPollingTask extends PollingTask {
  final RouterCommandService commandService;
  final Workgroup workgroup;
  final HelvarGroup group;
  final Function(HelvarGroup updatedGroup)? onPowerUpdated;

  GroupPowerPollingTask({
    required this.commandService,
    required this.workgroup,
    required this.group,
    this.onPowerUpdated,
    Duration? customInterval,
  }) : super(
         id: 'group_power_${workgroup.id}_${group.id}',
         name: 'Group ${group.groupId} Power Consumption',
         interval:
             customInterval ?? Duration(minutes: group.powerPollingMinutes),
         parameters: {
           'workgroupId': workgroup.id,
           'groupId': group.id,
           'groupIdInt': int.tryParse(group.groupId),
         },
       );

  @override
  Future<PollingResult> execute() async {
    try {
      if (workgroup.routers.isEmpty) {
        return PollingResult.failure(
          'No routers available for workgroup ${workgroup.description}',
        );
      }

      final router = workgroup.routers.first;
      final groupIdInt = parameters['groupIdInt'] as int?;

      if (groupIdInt == null) {
        return PollingResult.failure('Invalid group ID: ${group.groupId}');
      }

      logDebug('Polling power consumption for group ${group.groupId}');

      final powerCommand = HelvarNetCommands.queryGroupPowerConsumption(
        groupIdInt,
      );
      final powerResult = await commandService.sendCommand(
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

          onPowerUpdated?.call(updatedGroup);

          return PollingResult.success({
            'powerConsumption': powerConsumption,
            'timestamp': now,
            'updatedGroup': updatedGroup,
          });
        } else {
          return PollingResult.failure(
            'Empty power consumption value received',
          );
        }
      } else {
        return PollingResult.failure(
          'Failed to query power consumption: ${powerResult.response}',
        );
      }
    } catch (e) {
      return PollingResult.failure('Error polling power consumption: $e');
    }
  }

  @override
  void onStart() {
    logInfo('Started power consumption polling for group ${group.groupId}');
  }

  @override
  void onStop() {
    logInfo('Stopped power consumption polling for group ${group.groupId}');
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    logError(
      'Power consumption polling error for group ${group.groupId}: $error',
      stackTrace: stackTrace,
    );
  }
}
