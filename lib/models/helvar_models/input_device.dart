import 'package:grms_designer/utils/device_utils.dart';

import '../../utils/logger.dart';
import 'device_action.dart';
import 'helvar_device.dart';

class HelvarDriverInputDevice extends HelvarDevice {
  List<ButtonPoint> buttonPoints;

  HelvarDriverInputDevice({
    super.deviceId,
    super.address,
    super.state,
    super.description,
    super.props,
    super.iconPath,
    super.hexId,
    super.addressingScheme,
    super.emergency,
    super.blockId,
    super.sceneId,
    super.out,
    super.helvarType = "input",
    super.deviceTypeCode,
    super.deviceStateCode,
    super.isButtonDevice,
    super.isMultisensor,
    super.sensorInfo,
    super.additionalInfo,
    List<ButtonPoint>? buttonPoints,
  }) : buttonPoints = buttonPoints ?? [];

  @override
  void recallScene(String sceneParams) {
    out = handleRecallScene(sceneParams, logInfoOutput: false);
  }

  @override
  void started() {
    createInputPoints(address, props, addressingScheme);

    if (isButtonDevice && buttonPoints.isEmpty) {
      generateButtonPoints();
    }

    if (isMultisensor && sensorInfo.isEmpty) {
      sensorInfo = {
        'hasPresence': true,
        'hasLightLevel': true,
        'hasTemperature': false,
      };
    }
  }

  @override
  void stopped() {}

  @override
  void performAction(DeviceAction action, dynamic value) {
    switch (action) {
      case DeviceAction.clearResult:
        clearResult();
        break;
      default:
        logWarning("Action $action not supported for input device");
    }
  }

  void createInputPoints(
    String deviceAddress,
    String pointProps,
    String subAddress,
  ) {}

  void generateButtonPoints() {
    if (!isButtonDevice) return;
    buttonPoints
      ..clear()
      ..addAll(
        generateStandardButtonPoints(
          description.isEmpty ? "Device_$deviceId" : description,
        ),
      );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['buttonPoints'] = buttonPoints.map((point) => point.toJson()).toList();
    return json;
  }
}

class ButtonPoint {
  final String name;
  final String function;
  final int buttonId;

  ButtonPoint({
    required this.name,
    required this.function,
    required this.buttonId,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'function': function, 'buttonId': buttonId};
  }

  factory ButtonPoint.fromJson(Map<String, dynamic> json) {
    return ButtonPoint(
      name: json['name'] as String,
      function: json['function'] as String,
      buttonId: json['buttonId'] as int,
    );
  }
}
