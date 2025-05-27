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
    int? deviceStateCode,
    int? loadLevel,
    bool isButton = false,
    bool isMultisensor = false,
  }) {
    HelvarDevice? device;

    if (isButton || deviceTypeString.toLowerCase().contains('button')) {
      device = HelvarDriverInputDevice(
        deviceId: deviceId,
        address: deviceAddress,
        state: deviceState,
        description: description,
        props: deviceTypeString,
        deviceTypeCode: typeCode,
        deviceStateCode: deviceStateCode,
        isButtonDevice: isButton,
        isMultisensor: isMultisensor,
      );
    } else if (deviceTypeString.toLowerCase().contains('emergency')) {
      device = HelvarDriverEmergencyDevice(
        deviceId: deviceId,
        address: deviceAddress,
        state: deviceState,
        description: description,
        props: deviceTypeString,
        deviceTypeCode: typeCode,
        deviceStateCode: deviceStateCode,
        emergency: true,
      );
    } else {
      device = HelvarDriverOutputDevice(
        deviceId: deviceId,
        address: deviceAddress,
        state: deviceState,
        description: description,
        props: deviceTypeString,
        deviceTypeCode: typeCode,
        deviceStateCode: deviceStateCode,
        level: loadLevel ?? 0,
      );
    }

    device.started();

    return device;
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
