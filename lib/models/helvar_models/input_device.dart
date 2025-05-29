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
    try {
      if (sceneParams.isNotEmpty) {
        List<String> temp = sceneParams.split(',');

        String timestamp = DateTime.now().toString();
        String s = "Success ($timestamp) Recalled Scene: ${temp[1]}";
        out = s;
      } else {
        logWarning("Please pass a valid scene number!");
        out = "Please pass a valid scene number!";
      }
    } catch (e) {
      logError(e.toString());
      out = e.toString();
    }
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

    buttonPoints.clear();

    final deviceName = description.isEmpty ? "Device_$deviceId" : description;

    buttonPoints.add(
      ButtonPoint(
        name: '${deviceName}_Missing',
        function: 'Status',
        buttonId: 0,
      ),
    );

    for (int i = 1; i <= 7; i++) {
      buttonPoints.add(
        ButtonPoint(
          name: '${deviceName}_Button$i',
          function: 'Button',
          buttonId: i,
        ),
      );
    }

    for (int i = 1; i <= 7; i++) {
      buttonPoints.add(
        ButtonPoint(
          name: '${deviceName}_IR$i',
          function: 'IR Receiver',
          buttonId: i + 100, // Using offset for IR receivers
        ),
      );
    }
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
