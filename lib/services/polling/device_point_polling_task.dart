import 'package:grms_designer/utils/core/logger.dart';
import 'package:grms_designer/services/polling/polling_presets.dart';

import '../../comm/router_command_service.dart';
import '../../models/helvar_models/helvar_device.dart';
import '../../models/helvar_models/helvar_router.dart';
import '../../models/helvar_models/workgroup.dart';
import '../../models/helvar_models/output_device.dart';
import '../../models/helvar_models/input_device.dart';
import '../../protocol/query_commands.dart';
import '../../protocol/protocol_parser.dart';
import '../../protocol/protocol_constants.dart';
import 'polling_task.dart';

class DevicePointPollingTask extends PollingTask {
  final RouterCommandService commandService;
  final Workgroup workgroup;
  final HelvarRouter router;
  final HelvarDevice device;
  final Function(HelvarDevice updatedDevice)? onPointsUpdated;

  DevicePointPollingTask({
    required this.commandService,
    required this.workgroup,
    required this.router,
    required this.device,
    this.onPointsUpdated,
  }) : super(
         id: 'device_points_${workgroup.id}_${device.address}',
         name: 'Device Points ${device.address}',
         interval:
             PollingPresets.normal, // Default interval, will be configurable
         parameters: {
           'workgroupId': workgroup.id,
           'routerAddress': router.address,
           'deviceAddress': device.address,
           'deviceType': device.helvarType,
         },
       );

  @override
  Future<PollingResult> execute() async {
    try {
      logDebug('Polling points for device ${device.address}');

      if (device is HelvarDriverOutputDevice) {
        return await _pollOutputDevicePoints();
      } else if (device is HelvarDriverInputDevice) {
        return await _pollInputDevicePoints();
      } else {
        return PollingResult.failure(
          'Unsupported device type for point polling',
        );
      }
    } catch (e) {
      return PollingResult.failure('Error polling device points: $e');
    }
  }

  Future<PollingResult> _pollOutputDevicePoints() async {
    final outputDevice = device as HelvarDriverOutputDevice;
    final results = <String, dynamic>{};
    bool hasUpdates = false;

    // Ensure output points exist
    if (outputDevice.outputPoints.isEmpty) {
      outputDevice.generateOutputPoints();
    }

    // Poll each output point based on its configured polling rate
    for (final point in outputDevice.outputPoints) {
      try {
        final success = await _queryOutputPoint(outputDevice, point.pointId);
        if (success) {
          results['point_${point.pointId}'] = point.value;
          hasUpdates = true;
        }
      } catch (e) {
        logWarning('Error polling output point ${point.pointId}: $e');
      }
    }

    if (hasUpdates) {
      onPointsUpdated?.call(outputDevice);
    }

    return PollingResult.success(results);
  }

  Future<PollingResult> _pollInputDevicePoints() async {
    final inputDevice = device as HelvarDriverInputDevice;
    final results = <String, dynamic>{};

    // For input devices, we mainly poll device state and button status
    try {
      // Query device state
      final stateCommand = HelvarNetCommands.queryDeviceState(device.address);
      final stateResult = await commandService.sendCommand(
        router.ipAddress,
        stateCommand,
      );

      if (stateResult.success && stateResult.response != null) {
        final stateValue = ProtocolParser.extractResponseValue(
          stateResult.response!,
        );
        if (stateValue != null) {
          final stateCode = int.tryParse(stateValue) ?? 0;
          device.deviceStateCode = stateCode;
          device.state = getStateFlagsDescription(stateCode);
          results['deviceState'] = device.state;
        }
      }

      onPointsUpdated?.call(inputDevice);
      return PollingResult.success(results);
    } catch (e) {
      return PollingResult.failure('Error polling input device points: $e');
    }
  }

  Future<bool> _queryOutputPoint(
    HelvarDriverOutputDevice device,
    int pointId,
  ) async {
    try {
      switch (pointId) {
        case 1: // Device State
          return await _queryDeviceState(device);
        case 2: // Lamp Failure
          return await _queryLampFailure(device);
        case 3: // Missing Status
          return await _queryMissingStatus(device);
        case 4: // Faulty Status
          return await _queryFaultyStatus(device);
        case 5: // Output Level
          return await _queryOutputLevel(device);
        case 6: // Power Consumption
          return await _queryPowerConsumption(device);
        default:
          logWarning('Unknown point ID: $pointId');
          return false;
      }
    } catch (e) {
      logError('Error querying point $pointId: $e');
      return false;
    }
  }

  Future<bool> _queryDeviceState(HelvarDriverOutputDevice device) async {
    final command = HelvarNetCommands.queryDeviceState(device.address);
    final result = await commandService.sendCommand(router.ipAddress, command);

    if (result.success && result.response != null) {
      final stateValue = ProtocolParser.extractResponseValue(result.response!);
      if (stateValue != null) {
        final stateCode = int.tryParse(stateValue) ?? 0;
        final isNormal = stateCode == 0;
        await device.updatePointValue(1, isNormal);
        return true;
      }
    }
    return false;
  }

  Future<bool> _queryLampFailure(HelvarDriverOutputDevice device) async {
    final command = HelvarNetCommands.queryLampFailure(device.address);
    final result = await commandService.sendCommand(router.ipAddress, command);

    if (result.success && result.response != null) {
      final failureValue = ProtocolParser.extractResponseValue(
        result.response!,
      );
      if (failureValue != null) {
        final hasFailure =
            failureValue == '1' || failureValue.toLowerCase() == 'true';
        await device.updatePointValue(2, hasFailure);
        return true;
      }
    }
    return false;
  }

  Future<bool> _queryMissingStatus(HelvarDriverOutputDevice device) async {
    final command = HelvarNetCommands.queryDeviceIsMissing(device.address);
    final result = await commandService.sendCommand(router.ipAddress, command);

    if (result.success && result.response != null) {
      final missingValue = ProtocolParser.extractResponseValue(
        result.response!,
      );
      if (missingValue != null) {
        final isMissing =
            missingValue == '1' || missingValue.toLowerCase() == 'true';
        await device.updatePointValue(3, isMissing);
        return true;
      }
    }
    return false;
  }

  Future<bool> _queryFaultyStatus(HelvarDriverOutputDevice device) async {
    final command = HelvarNetCommands.queryDeviceIsFaulty(device.address);
    final result = await commandService.sendCommand(router.ipAddress, command);

    if (result.success && result.response != null) {
      final faultyValue = ProtocolParser.extractResponseValue(result.response!);
      if (faultyValue != null) {
        final isFaulty =
            faultyValue == '1' || faultyValue.toLowerCase() == 'true';
        await device.updatePointValue(4, isFaulty);
        return true;
      }
    }
    return false;
  }

  Future<bool> _queryOutputLevel(HelvarDriverOutputDevice device) async {
    final command = HelvarNetCommands.queryLoadLevel(device.address);
    final result = await commandService.sendCommand(router.ipAddress, command);

    if (result.success && result.response != null) {
      final levelValue = ProtocolParser.extractResponseValue(result.response!);
      if (levelValue != null) {
        final level = double.tryParse(levelValue) ?? 0.0;
        await device.updatePointValue(5, level);
        device.level = level.round();
        return true;
      }
    }
    return false;
  }

  Future<bool> _queryPowerConsumption(HelvarDriverOutputDevice device) async {
    final command = HelvarNetCommands.queryPowerConsumption(device.address);
    final result = await commandService.sendCommand(router.ipAddress, command);

    if (result.success && result.response != null) {
      final powerValue = ProtocolParser.extractResponseValue(result.response!);
      if (powerValue != null) {
        final power = double.tryParse(powerValue) ?? 0.0;
        await device.updatePointValue(6, power);
        device.powerConsumption = power;
        return true;
      }
    }
    return false;
  }

  @override
  void onStart() {
    logInfo('Started device point polling for ${device.address}');
  }

  @override
  void onStop() {
    logInfo('Stopped device point polling for ${device.address}');
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    logError(
      'Device point polling error for ${device.address}: $error',
      stackTrace: stackTrace,
    );
  }
}
