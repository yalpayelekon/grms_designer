import '../models/helvar_models/helvar_device.dart';
import '../models/helvar_models/input_device.dart';
import '../models/helvar_models/output_device.dart';
import '../models/helvar_models/emergency_device.dart';

class HelvarDeviceFactory {
  static HelvarDevice createDevice({
    required int deviceId,
    required String deviceAddress,
    required String deviceState,
    required String description,
    required String deviceTypeString,
    required int typeCode,
    required int? deviceStateCode,
    required int? loadLevel,
    required bool isButton,
    required bool isMultisensor,
  }) {
    if (isButton) {
      return HelvarDriverInputDevice(
        deviceId: deviceId,
        address: deviceAddress,
        state: deviceState,
        description: description,
        props: deviceTypeString,
        hexId: '0x${typeCode.toRadixString(16)}',
        helvarType: 'input',
        deviceTypeCode: typeCode,
        deviceStateCode: deviceStateCode,
        isButtonDevice: true,
        buttonPoints: generateButtonPoints(description),
      );
    } else if (isMultisensor) {
      return HelvarDriverInputDevice(
        deviceId: deviceId,
        address: deviceAddress,
        state: deviceState,
        description: description,
        props: deviceTypeString,
        hexId: '0x${typeCode.toRadixString(16)}',
        helvarType: 'input',
        deviceTypeCode: typeCode,
        deviceStateCode: deviceStateCode,
        isMultisensor: true,
        sensorInfo: {
          'hasPresence': true,
          'hasLightLevel': true,
          'hasTemperature': false,
        },
      );
    } else if (typeCode == 0x0101 ||
        (typeCode & 0xFF) == 0x01 && ((typeCode >> 8) & 0xFF) == 0x01) {
      return HelvarDriverEmergencyDevice(
        deviceId: deviceId,
        address: deviceAddress,
        state: deviceState,
        description: description,
        props: deviceTypeString,
        hexId: '0x${typeCode.toRadixString(16)}',
        helvarType: 'emergency',
        deviceTypeCode: typeCode,
        deviceStateCode: deviceStateCode,
        emergency: true,
      );
    } else {
      return HelvarDriverOutputDevice(
        deviceId: deviceId,
        address: deviceAddress,
        state: deviceState,
        description: description,
        props: deviceTypeString,
        hexId: '0x${typeCode.toRadixString(16)}',
        helvarType: 'output',
        deviceTypeCode: typeCode,
        deviceStateCode: deviceStateCode,
        level: loadLevel ?? 100,
      );
    }
  }

  static List<ButtonPoint> generateButtonPoints(String deviceName) {
    final points = <ButtonPoint>[];

    points.add(ButtonPoint(
      name: '${deviceName}_Missing',
      function: 'Status',
      buttonId: 0,
    ));

    for (int i = 1; i <= 7; i++) {
      points.add(ButtonPoint(
        name: '${deviceName}_Button$i',
        function: 'Button',
        buttonId: i,
      ));
    }

    for (int i = 1; i <= 7; i++) {
      points.add(ButtonPoint(
        name: '${deviceName}_IR$i',
        function: 'IR Receiver',
        buttonId: i + 100, // Using offset for IR receivers
      ));
    }

    return points;
  }

  static HelvarDevice createBasicDevice({
    required int deviceId,
    required String deviceAddress,
    required String helvarType,
    String? description,
  }) {
    final deviceDescription = description ?? 'Device $deviceId';

    switch (helvarType.toLowerCase()) {
      case 'input':
        return HelvarDriverInputDevice(
          deviceId: deviceId,
          address: deviceAddress,
          description: deviceDescription,
          helvarType: 'input',
        );
      case 'emergency':
        return HelvarDriverEmergencyDevice(
          deviceId: deviceId,
          address: deviceAddress,
          description: deviceDescription,
          helvarType: 'emergency',
          emergency: true,
        );
      case 'output':
      default:
        return HelvarDriverOutputDevice(
          deviceId: deviceId,
          address: deviceAddress,
          description: deviceDescription,
          helvarType: 'output',
        );
    }
  }
}
