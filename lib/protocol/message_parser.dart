import 'protocol_constants.dart';

Map<String, dynamic> parseResponse(String response) {
  final result = <String, dynamic>{};
  if (!response.startsWith(MessageType.reply) &&
      !response.startsWith(MessageType.error)) {
    throw FormatException('Invalid response format: $response');
  }
  final parts = response.split(MessageType.answer);
  if (parts.length != 2) {
    throw FormatException('Invalid response format: $response');
  }
  final commandPart = parts[0].substring(1);
  final commandParams = commandPart.split(MessageType.delimiter);
  var dataPart = parts[1];
  if (dataPart.endsWith(MessageType.terminator)) {
    dataPart = dataPart.substring(0, dataPart.length - 1);
  } else if (dataPart.endsWith(MessageType.partialTerminator)) {
    dataPart = dataPart.substring(0, dataPart.length - 1);
    result['partial'] = true;
  }
  for (final param in commandParams) {
    if (param.contains(MessageType.paramDelimiter)) {
      final keyValue = param.split(MessageType.paramDelimiter);
      if (keyValue.length == 2) {
        result[keyValue[0]] = keyValue[1];
      }
    } else if (param.startsWith(ParameterId.address)) {
      result[ParameterId.address] = param.substring(1);
    }
  }
  if (response.startsWith(MessageType.error)) {
    final errorCode = int.tryParse(dataPart);
    result['error'] = errorCode;
    result['errorMessage'] = ErrorCode.getMessage(errorCode ?? -1);
  } else {
    if (dataPart.contains(MessageType.delimiter)) {
      final values = dataPart.split(MessageType.delimiter);
      result['data'] = values;
    } else {
      result['data'] = dataPart;
    }
  }

  return result;
}

Map<String, int> parseDeviceAddress(String address) {
  final parts = address.split(MessageType.addressDelimiter);

  if (parts.length != 4) {
    throw FormatException('Invalid device address format: $address');
  }

  return {
    'cluster': int.parse(parts[0]),
    'router': int.parse(parts[1]),
    'subnet': int.parse(parts[2]),
    'device': int.parse(parts[3]),
  };
}

Map<String, bool> decodeDeviceState(int stateValue) {
  return {
    'disabled': (stateValue & DeviceStateFlag.disabled) != 0,
    'lampFailure': (stateValue & DeviceStateFlag.lampFailure) != 0,
    'missing': (stateValue & DeviceStateFlag.missing) != 0,
    'faulty': (stateValue & DeviceStateFlag.faulty) != 0,
    'refreshing': (stateValue & DeviceStateFlag.refreshing) != 0,
    'emergencyResting': (stateValue & DeviceStateFlag.emergencyResting) != 0,
    'emergencyMode': (stateValue & DeviceStateFlag.emergencyMode) != 0,
    'emergencyProlong': (stateValue & DeviceStateFlag.emergencyProlong) != 0,
    'functionalTestInProgress':
        (stateValue & DeviceStateFlag.functionalTestInProgress) != 0,
    'durationTestInProgress':
        (stateValue & DeviceStateFlag.durationTestInProgress) != 0,
    'durationTestPending':
        (stateValue & DeviceStateFlag.durationTestPending) != 0,
    'functionalTestPending':
        (stateValue & DeviceStateFlag.functionalTestPending) != 0,
    'batteryFail': (stateValue & DeviceStateFlag.batteryFail) != 0,
    'emergencyInhibit': (stateValue & DeviceStateFlag.emergencyInhibit) != 0,
    'functionalTestRequested':
        (stateValue & DeviceStateFlag.functionalTestRequested) != 0,
    'durationTestRequested':
        (stateValue & DeviceStateFlag.durationTestRequested) != 0,
    'unknown': (stateValue & DeviceStateFlag.unknown) != 0,
    'overTemperature': (stateValue & DeviceStateFlag.overTemperature) != 0,
    'overCurrent': (stateValue & DeviceStateFlag.overCurrent) != 0,
    'commsError': (stateValue & DeviceStateFlag.commsError) != 0,
    'severeError': (stateValue & DeviceStateFlag.severeError) != 0,
    'badReply': (stateValue & DeviceStateFlag.badReply) != 0,
    'deviceMismatch': (stateValue & DeviceStateFlag.deviceMismatch) != 0,
  };
}

Map<String, bool> decodeEmergencyTestState(int stateValue) {
  return {
    'pass': (stateValue & EmergencyTestState.pass) == EmergencyTestState.pass,
    'lampFailure': (stateValue & EmergencyTestState.lampFailure) != 0,
    'batteryFailure': (stateValue & EmergencyTestState.batteryFailure) != 0,
    'faulty': (stateValue & EmergencyTestState.faulty) != 0,
    'failure': (stateValue & EmergencyTestState.failure) != 0,
    'testPending': (stateValue & EmergencyTestState.testPending) != 0,
    'unknown': (stateValue & EmergencyTestState.unknown) != 0,
  };
}
