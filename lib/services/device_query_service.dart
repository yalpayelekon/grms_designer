import '../comm/router_command_service.dart';
import '../models/helvar_models/output_device.dart';
import '../protocol/query_commands.dart';
import '../protocol/protocol_parser.dart';
import '../utils/core/logger.dart';

class DeviceQueryService {
  final RouterCommandService commandService;

  DeviceQueryService(this.commandService);

  Future<bool> queryOutputDevicePoints(
    String routerIpAddress,
    HelvarDriverOutputDevice device,
  ) async {
    try {
      logInfo('Querying output device points for: ${device.address}');

      await _queryDeviceState(routerIpAddress, device);

      await _queryLampFailure(routerIpAddress, device);

      await _queryMissingStatus(routerIpAddress, device);

      await _queryFaultyStatus(routerIpAddress, device);

      await _queryOutputLevel(routerIpAddress, device);

      await _queryPowerConsumption(routerIpAddress, device);

      logInfo('Successfully updated all points for device: ${device.address}');
      return true;
    } catch (e) {
      logError('Error querying output device points: $e');
      return false;
    }
  }

  Future<void> _queryDeviceState(
    String routerIpAddress,
    HelvarDriverOutputDevice device,
  ) async {
    try {
      final command = HelvarNetCommands.queryDeviceState(device.address);
      final result = await commandService.sendCommand(routerIpAddress, command);

      if (result.success && result.response != null) {
        final stateValue = ProtocolParser.extractResponseValue(
          result.response!,
        );
        if (stateValue != null) {
          final stateCode = int.tryParse(stateValue) ?? 0;
          final isNormal = stateCode == 0;
          await device.updatePointValue(1, isNormal);

          logInfo(
            'Device ${device.address} state: $stateCode (Normal: $isNormal)',
          );
        }
      }
    } catch (e) {
      logError('Error querying device state: $e');
    }
  }

  Future<void> _queryLampFailure(
    String routerIpAddress,
    HelvarDriverOutputDevice device,
  ) async {
    try {
      final command = HelvarNetCommands.queryLampFailure(device.address);
      final result = await commandService.sendCommand(routerIpAddress, command);

      if (result.success && result.response != null) {
        final failureValue = ProtocolParser.extractResponseValue(
          result.response!,
        );
        if (failureValue != null) {
          final hasFailure =
              failureValue == '1' || failureValue.toLowerCase() == 'true';
          await device.updatePointValue(2, hasFailure);

          logInfo('Device ${device.address} lamp failure: $hasFailure');
        }
      }
    } catch (e) {
      logError('Error querying lamp failure: $e');
    }
  }

  Future<void> _queryMissingStatus(
    String routerIpAddress,
    HelvarDriverOutputDevice device,
  ) async {
    try {
      final command = HelvarNetCommands.queryDeviceIsMissing(device.address);
      final result = await commandService.sendCommand(routerIpAddress, command);

      if (result.success && result.response != null) {
        final missingValue = ProtocolParser.extractResponseValue(
          result.response!,
        );
        if (missingValue != null) {
          final isMissing =
              missingValue == '1' || missingValue.toLowerCase() == 'true';
          await device.updatePointValue(3, isMissing);

          logInfo('Device ${device.address} missing: $isMissing');
        }
      }
    } catch (e) {
      logError('Error querying missing status: $e');
    }
  }

  Future<void> _queryFaultyStatus(
    String routerIpAddress,
    HelvarDriverOutputDevice device,
  ) async {
    try {
      final command = HelvarNetCommands.queryDeviceIsFaulty(device.address);
      final result = await commandService.sendCommand(routerIpAddress, command);

      if (result.success && result.response != null) {
        final faultyValue = ProtocolParser.extractResponseValue(
          result.response!,
        );
        if (faultyValue != null) {
          final isFaulty =
              faultyValue == '1' || faultyValue.toLowerCase() == 'true';
          await device.updatePointValue(4, isFaulty);

          logInfo('Device ${device.address} faulty: $isFaulty');
        }
      }
    } catch (e) {
      logError('Error querying faulty status: $e');
    }
  }

  Future<void> _queryOutputLevel(
    String routerIpAddress,
    HelvarDriverOutputDevice device,
  ) async {
    try {
      final command = HelvarNetCommands.queryLoadLevel(device.address);
      final result = await commandService.sendCommand(routerIpAddress, command);

      if (result.success && result.response != null) {
        final levelValue = ProtocolParser.extractResponseValue(
          result.response!,
        );
        if (levelValue != null) {
          final level = double.tryParse(levelValue) ?? 0.0;
          await device.updatePointValue(5, level);

          device.level = level.round();

          logInfo('Device ${device.address} output level: $level%');
        }
      }
    } catch (e) {
      logError('Error querying output level: $e');
    }
  }

  Future<void> _queryPowerConsumption(
    String routerIpAddress,
    HelvarDriverOutputDevice device,
  ) async {
    try {
      final command = HelvarNetCommands.queryPowerConsumption(device.address);
      final result = await commandService.sendCommand(routerIpAddress, command);

      if (result.success && result.response != null) {
        final powerValue = ProtocolParser.extractResponseValue(
          result.response!,
        );
        if (powerValue != null) {
          final power = double.tryParse(powerValue) ?? 0.0;
          await device.updatePointValue(6, power);
          device.powerConsumption = power;
          logInfo('Device ${device.address} power consumption: ${power}W');
        }
      }
    } catch (e) {
      logError('Error querying power consumption: $e');
    }
  }

  Future<bool> queryOutputDevicePoint(
    String routerIpAddress,
    HelvarDriverOutputDevice device,
    int pointId,
  ) async {
    try {
      switch (pointId) {
        case 1:
          await _queryDeviceState(routerIpAddress, device);
          break;
        case 2:
          await _queryLampFailure(routerIpAddress, device);
          break;
        case 3:
          await _queryMissingStatus(routerIpAddress, device);
          break;
        case 4:
          await _queryFaultyStatus(routerIpAddress, device);
          break;
        case 5:
          await _queryOutputLevel(routerIpAddress, device);
          break;
        case 6:
          await _queryPowerConsumption(routerIpAddress, device);
          break;
        default:
          logWarning('Unknown point ID: $pointId');
          return false;
      }
      return true;
    } catch (e) {
      logError('Error querying point $pointId: $e');
      return false;
    }
  }

  static String getPointDescription(int pointId) {
    switch (pointId) {
      case 1:
        return 'Device State - Indicates if device has any state issues';
      case 2:
        return 'Lamp Failure - Indicates if the lamp has failed';
      case 3:
        return 'Missing - Indicates if the device is missing/not responding';
      case 4:
        return 'Faulty - Indicates if the device is in a faulty state';
      case 5:
        return 'Output Level - Current output level percentage (0-100%)';
      case 6:
        return 'Power Consumption - Current power consumption in Watts';
      default:
        return 'Unknown point';
    }
  }
}
