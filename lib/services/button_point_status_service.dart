// lib/services/button_point_status_service.dart
import 'dart:async';
import '../comm/models/command_models.dart';
import '../comm/router_command_service.dart';
import '../models/helvar_models/helvar_device.dart';
import '../models/helvar_models/input_device.dart';
import '../protocol/query_commands.dart';
import '../protocol/message_parser.dart';
import '../protocol/protocol_parser.dart';
import '../utils/logger.dart';

class ButtonPointStatus {
  final String deviceAddress;
  final int buttonId;
  final String function;
  final bool value;
  final DateTime lastUpdated;
  final String? rawResponse;

  ButtonPointStatus({
    required this.deviceAddress,
    required this.buttonId,
    required this.function,
    required this.value,
    required this.lastUpdated,
    this.rawResponse,
  });

  ButtonPointStatus copyWith({
    String? deviceAddress,
    int? buttonId,
    String? function,
    bool? value,
    DateTime? lastUpdated,
    String? rawResponse,
  }) {
    return ButtonPointStatus(
      deviceAddress: deviceAddress ?? this.deviceAddress,
      buttonId: buttonId ?? this.buttonId,
      function: function ?? this.function,
      value: value ?? this.value,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      rawResponse: rawResponse ?? this.rawResponse,
    );
  }
}

class ButtonPointStatusService {
  final RouterCommandService _commandService;
  final Map<String, ButtonPointStatus> _statusCache = {};
  final Map<String, Timer> _pollingTimers = {};
  final StreamController<ButtonPointStatus> _statusController =
      StreamController.broadcast();

  static const Duration _defaultPollingInterval = Duration(seconds: 5);
  static const Duration _queryTimeout = Duration(seconds: 3);

  ButtonPointStatusService(this._commandService);

  Stream<ButtonPointStatus> get statusStream => _statusController.stream;

  /// Start monitoring button point status for a device
  Future<void> startMonitoring(
    HelvarDevice device,
    String routerIpAddress, {
    Duration pollingInterval = _defaultPollingInterval,
  }) async {
    if (device is! HelvarDriverInputDevice || !device.isButtonDevice) {
      logWarning('Device ${device.address} is not a button device');
      return;
    }

    final deviceKey = '${device.address}@$routerIpAddress';

    // Stop existing monitoring if any
    stopMonitoring(device.address, routerIpAddress);

    logInfo('Starting button point monitoring for device: ${device.address}');

    // Initial status query
    await _queryDeviceStatus(device, routerIpAddress);

    // Start periodic polling
    _pollingTimers[deviceKey] = Timer.periodic(pollingInterval, (timer) {
      _queryDeviceStatus(device, routerIpAddress);
    });
  }

  /// Stop monitoring button point status for a device
  void stopMonitoring(String deviceAddress, String routerIpAddress) {
    final deviceKey = '${deviceAddress}@$routerIpAddress';
    _pollingTimers[deviceKey]?.cancel();
    _pollingTimers.remove(deviceKey);

    // Remove cached statuses for this device
    _statusCache
        .removeWhere((key, value) => key.startsWith('${deviceAddress}_'));

    logInfo('Stopped monitoring device: $deviceAddress');
  }

  /// Get current status for a button point
  ButtonPointStatus? getButtonPointStatus(String deviceAddress, int buttonId) {
    return _statusCache['${deviceAddress}_$buttonId'];
  }

  /// Query device status using multiple approaches
  Future<void> _queryDeviceStatus(
      HelvarDevice device, String routerIpAddress) async {
    try {
      // Query 1: Device State - gives overall device status
      await _queryDeviceState(device, routerIpAddress);

      // Query 2: Device Missing Status
      await _queryDeviceMissing(device, routerIpAddress);

      // Query 3: Device Faulty Status
      await _queryDeviceFaulty(device, routerIpAddress);

      // Query 4: Device Disabled Status
      await _queryDeviceDisabled(device, routerIpAddress);

      // Query 5: Try to get input status (this might be device-specific)
      await _queryInputStatus(device, routerIpAddress);
    } catch (e) {
      logError('Error querying device status for ${device.address}: $e');
    }
  }

  Future<void> _queryDeviceState(
      HelvarDevice device, String routerIpAddress) async {
    try {
      final command = HelvarNetCommands.queryDeviceState(device.address);
      logDebug('Sending device state query: $command');

      final result = await _commandService.sendCommand(
        routerIpAddress,
        command,
        timeout: _queryTimeout,
      );

      if (result.success && result.response != null) {
        logInfo(
            'Device state response for ${device.address}: ${result.response}');
        _parseDeviceStateResponse(device, result.response!);
      } else {
        logWarning(
            'Failed to get device state for ${device.address}: ${result.errorMessage}');
      }
    } catch (e) {
      logError('Error querying device state: $e');
    }
  }

  Future<void> _queryDeviceMissing(
      HelvarDevice device, String routerIpAddress) async {
    try {
      final command = HelvarNetCommands.queryDeviceIsMissing(device.address);
      logDebug('Sending device missing query: $command');

      final result = await _commandService.sendCommand(
        routerIpAddress,
        command,
        timeout: _queryTimeout,
      );

      if (result.success && result.response != null) {
        logInfo(
            'Device missing response for ${device.address}: ${result.response}');
        _parseDeviceMissingResponse(device, result.response!);
      }
    } catch (e) {
      logError('Error querying device missing status: $e');
    }
  }

  Future<void> _queryDeviceFaulty(
      HelvarDevice device, String routerIpAddress) async {
    try {
      final command = HelvarNetCommands.queryDeviceIsFaulty(device.address);
      logDebug('Sending device faulty query: $command');

      final result = await _commandService.sendCommand(
        routerIpAddress,
        command,
        timeout: _queryTimeout,
      );

      if (result.success && result.response != null) {
        logInfo(
            'Device faulty response for ${device.address}: ${result.response}');
        _parseDeviceFaultyResponse(device, result.response!);
      }
    } catch (e) {
      logError('Error querying device faulty status: $e');
    }
  }

  Future<void> _queryDeviceDisabled(
      HelvarDevice device, String routerIpAddress) async {
    try {
      final command = HelvarNetCommands.queryDeviceIsDisabled(device.address);
      logDebug('Sending device disabled query: $command');

      final result = await _commandService.sendCommand(
        routerIpAddress,
        command,
        timeout: _queryTimeout,
      );

      if (result.success && result.response != null) {
        logInfo(
            'Device disabled response for ${device.address}: ${result.response}');
        _parseDeviceDisabledResponse(device, result.response!);
      }
    } catch (e) {
      logError('Error querying device disabled status: $e');
    }
  }

  Future<void> _queryInputStatus(
      HelvarDevice device, String routerIpAddress) async {
    try {
      final command = HelvarNetCommands.queryInputs();
      logDebug('Sending input query: $command');

      final result = await _commandService.sendCommand(
        routerIpAddress,
        command,
        timeout: _queryTimeout,
      );

      if (result.success && result.response != null) {
        logInfo('Input status response: ${result.response}');
        _parseInputStatusResponse(device, result.response!);
      }
    } catch (e) {
      logError('Error querying input status: $e');
    }
  }

  void _parseDeviceStateResponse(HelvarDevice device, String response) {
    try {
      final parsed = parseResponse(response);
      if (parsed.containsKey('data')) {
        final stateValue = parsed['data'];
        logInfo('Device ${device.address} state value: $stateValue');

        // Parse device state flags to determine button statuses
        if (stateValue is String) {
          final stateCode = int.tryParse(stateValue);
          if (stateCode != null) {
            _updateButtonStatusesFromDeviceState(device, stateCode, response);
          }
        }
      }
    } catch (e) {
      logError('Error parsing device state response: $e');
    }
  }

  void _parseDeviceMissingResponse(HelvarDevice device, String response) {
    try {
      final value = ProtocolParser.extractResponseValue(response);
      if (value != null) {
        final isMissing = value == '1' || value.toLowerCase() == 'true';
        logInfo('Device ${device.address} is missing: $isMissing');

        // Update Missing button point status
        _updateButtonPointStatus(
            device.address,
            0, // Missing is typically buttonId 0
            'Status',
            isMissing,
            response);
      }
    } catch (e) {
      logError('Error parsing device missing response: $e');
    }
  }

  void _parseDeviceFaultyResponse(HelvarDevice device, String response) {
    try {
      final value = ProtocolParser.extractResponseValue(response);
      if (value != null) {
        final isFaulty = value == '1' || value.toLowerCase() == 'true';
        logInfo('Device ${device.address} is faulty: $isFaulty');

        // This could affect multiple button points - device malfunction
        // We might want to set all buttons to a default state when faulty
      }
    } catch (e) {
      logError('Error parsing device faulty response: $e');
    }
  }

  void _parseDeviceDisabledResponse(HelvarDevice device, String response) {
    try {
      final value = ProtocolParser.extractResponseValue(response);
      if (value != null) {
        final isDisabled = value == '1' || value.toLowerCase() == 'true';
        logInfo('Device ${device.address} is disabled: $isDisabled');
      }
    } catch (e) {
      logError('Error parsing device disabled response: $e');
    }
  }

  void _parseInputStatusResponse(HelvarDevice device, String response) {
    try {
      // This is where we might get actual button press states
      // The format is likely device-specific, so we'll log and analyze
      logInfo('Input status for ${device.address}: $response');

      final parsed = parseResponse(response);
      logInfo('Parsed input response: $parsed');

      // TODO: Based on actual response format, parse button states
      // This might contain individual button press information
    } catch (e) {
      logError('Error parsing input status response: $e');
    }
  }

  void _updateButtonStatusesFromDeviceState(
      HelvarDevice device, int stateCode, String rawResponse) {
    if (device is! HelvarDriverInputDevice) return;

    // Use the device state flags to determine button statuses
    final stateFlags = decodeDeviceState(stateCode);

    // Update button point statuses based on device state
    for (final buttonPoint in device.buttonPoints) {
      bool value = false;

      if (buttonPoint.function.contains('Status') ||
          buttonPoint.name.toLowerCase().contains('missing')) {
        // Missing status: true if device has issues
        value = stateFlags['missing'] == true ||
            stateFlags['faulty'] == true ||
            stateFlags['disabled'] == true;
      } else {
        // For actual buttons, we might need different logic
        // This is where we'd need to understand the actual protocol
        value = false; // Default to not pressed
      }

      _updateButtonPointStatus(device.address, buttonPoint.buttonId,
          buttonPoint.function, value, rawResponse);
    }
  }

  void _updateButtonPointStatus(String deviceAddress, int buttonId,
      String function, bool value, String rawResponse) {
    final key = '${deviceAddress}_$buttonId';
    final status = ButtonPointStatus(
      deviceAddress: deviceAddress,
      buttonId: buttonId,
      function: function,
      value: value,
      lastUpdated: DateTime.now(),
      rawResponse: rawResponse,
    );

    _statusCache[key] = status;
    _statusController.add(status);

    logDebug(
        'Updated button point status: $deviceAddress button $buttonId ($function) = $value');
  }

  void dispose() {
    for (final timer in _pollingTimers.values) {
      timer.cancel();
    }
    _pollingTimers.clear();
    _statusCache.clear();
    _statusController.close();
  }
}
