import 'package:grms_designer/models/helvar_models/output_point.dart';

import '../../comm/router_command_service.dart';
import '../../comm/router_connection_manager.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/helvar_group.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/output_device.dart';
import 'polling_task.dart';
import 'group_power_polling_task.dart';
import 'device_status_polling_task.dart';
import 'router_connection_polling_task.dart';
import 'system_health_polling_task.dart';
import 'output_point_polling_task.dart';

class PollingTaskFactory {
  static GroupPowerPollingTask createGroupPowerTask({
    required RouterCommandService commandService,
    required Workgroup workgroup,
    required HelvarGroup group,
    Function(HelvarGroup)? onPowerUpdated,
    Duration? customInterval,
  }) {
    return GroupPowerPollingTask(
      commandService: commandService,
      workgroup: workgroup,
      group: group,
      onPowerUpdated: onPowerUpdated,
      customInterval: customInterval,
    );
  }

  /// Create a device status polling task
  static DeviceStatusPollingTask createDeviceStatusTask({
    required RouterCommandService commandService,
    required HelvarRouter router,
    required HelvarDevice device,
    Function(HelvarDevice)? onDeviceUpdated,
    Duration interval = const Duration(minutes: 5),
  }) {
    return DeviceStatusPollingTask(
      commandService: commandService,
      router: router,
      device: device,
      onDeviceUpdated: onDeviceUpdated,
      interval: interval,
    );
  }

  /// Create a router connection monitoring task
  static RouterConnectionPollingTask createRouterConnectionTask({
    required RouterConnectionManager connectionManager,
    required HelvarRouter router,
    Function(HelvarRouter, bool)? onConnectionChanged,
    Duration interval = const Duration(seconds: 30),
  }) {
    return RouterConnectionPollingTask(
      connectionManager: connectionManager,
      router: router,
      onConnectionChanged: onConnectionChanged,
      interval: interval,
    );
  }

  /// Create a system health monitoring task
  static SystemHealthPollingTask createSystemHealthTask({
    Function(Map<String, dynamic>)? onHealthUpdated,
    Duration interval = const Duration(minutes: 1),
  }) {
    return SystemHealthPollingTask(
      onHealthUpdated: onHealthUpdated,
      interval: interval,
    );
  }

  /// Create an output point polling task
  static OutputPointPollingTask createOutputPointTask({
    required RouterCommandService commandService,
    required HelvarRouter router,
    required HelvarDriverOutputDevice device,
    required List<int> pointIds,
    Function(HelvarDriverOutputDevice, List<OutputPoint>)? onPointsUpdated,
    Duration interval = const Duration(seconds: 30),
  }) {
    return OutputPointPollingTask(
      commandService: commandService,
      router: router,
      device: device,
      pointIds: pointIds,
      onPointsUpdated: onPointsUpdated,
      interval: interval,
    );
  }

  /// Create multiple tasks for all devices in a router
  static List<PollingTask> createAllDeviceTasksForRouter({
    required RouterCommandService commandService,
    required HelvarRouter router,
    Function(HelvarDevice)? onDeviceUpdated,
    Duration deviceInterval = const Duration(minutes: 5),
    Duration connectionInterval = const Duration(seconds: 30),
    required RouterConnectionManager connectionManager,
  }) {
    final tasks = <PollingTask>[];

    // Add router connection monitoring
    tasks.add(
      createRouterConnectionTask(
        connectionManager: connectionManager,
        router: router,
        interval: connectionInterval,
      ),
    );

    // Add device status tasks
    for (final device in router.devices) {
      tasks.add(
        createDeviceStatusTask(
          commandService: commandService,
          router: router,
          device: device,
          onDeviceUpdated: onDeviceUpdated,
          interval: deviceInterval,
        ),
      );
    }

    return tasks;
  }

  /// Create tasks for all groups in a workgroup
  static List<PollingTask> createAllGroupTasksForWorkgroup({
    required RouterCommandService commandService,
    required Workgroup workgroup,
    Function(HelvarGroup)? onPowerUpdated,
  }) {
    final tasks = <PollingTask>[];

    for (final group in workgroup.groups) {
      tasks.add(
        createGroupPowerTask(
          commandService: commandService,
          workgroup: workgroup,
          group: group,
          onPowerUpdated: onPowerUpdated,
        ),
      );
    }

    return tasks;
  }
}

// lib/services/polling/polling_presets.dart
/// Predefined polling configurations for common scenarios
class PollingPresets {
  /// Fast polling preset (for critical monitoring)
  static const Duration fast = Duration(seconds: 10);

  /// Normal polling preset (for regular monitoring)
  static const Duration normal = Duration(minutes: 1);

  /// Slow polling preset (for background monitoring)
  static const Duration slow = Duration(minutes: 5);

  /// Very slow polling preset (for historical data)
  static const Duration verySlow = Duration(minutes: 15);

  /// Power consumption specific preset
  static const Duration powerConsumption = Duration(minutes: 15);

  /// Device status preset
  static const Duration deviceStatus = Duration(minutes: 5);

  /// Connection monitoring preset
  static const Duration connectionMonitoring = Duration(seconds: 30);

  /// System health preset
  static const Duration systemHealth = Duration(minutes: 1);

  /// Get preset by name
  static Duration? getPreset(String name) {
    switch (name.toLowerCase()) {
      case 'fast':
        return fast;
      case 'normal':
        return normal;
      case 'slow':
        return slow;
      case 'very_slow':
      case 'veryslow':
        return verySlow;
      case 'power_consumption':
      case 'powerconsumption':
        return powerConsumption;
      case 'device_status':
      case 'devicestatus':
        return deviceStatus;
      case 'connection_monitoring':
      case 'connectionmonitoring':
        return connectionMonitoring;
      case 'system_health':
      case 'systemhealth':
        return systemHealth;
      default:
        return null;
    }
  }

  /// Get all available presets
  static Map<String, Duration> getAllPresets() {
    return {
      'fast': fast,
      'normal': normal,
      'slow': slow,
      'very_slow': verySlow,
      'power_consumption': powerConsumption,
      'device_status': deviceStatus,
      'connection_monitoring': connectionMonitoring,
      'system_health': systemHealth,
    };
  }
}
