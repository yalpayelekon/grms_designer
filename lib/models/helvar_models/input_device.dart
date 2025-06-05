import 'package:grms_designer/models/helvar_models/workgroup.dart';
import 'package:grms_designer/utils/device/device_utils.dart';

import '../../utils/core/logger.dart';
import 'device_action.dart';
import 'helvar_device.dart';

class HelvarDriverInputDevice extends HelvarDevice {
  List<ButtonPoint> buttonPoints;

  HelvarDriverInputDevice({
    super.deviceId,
    super.address,
    super.state,
    super.description,
    super.name,
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

  HelvarDriverInputDevice copyWith({
    int? deviceId,
    String? address,
    String? state,
    String? description,
    String? name,
    String? props,
    String? iconPath,
    String? hexId,
    String? addressingScheme,
    bool? emergency,
    String? blockId,
    String? sceneId,
    String? out,
    String? helvarType,
    int? deviceTypeCode,
    int? deviceStateCode,
    bool? isButtonDevice,
    bool? isMultisensor,
    Map<String, dynamic>? sensorInfo,
    Map<String, dynamic>? additionalInfo,
    List<ButtonPoint>? buttonPoints,
  }) {
    return HelvarDriverInputDevice(
      deviceId: deviceId ?? this.deviceId,
      address: address ?? this.address,
      state: state ?? this.state,
      description: description ?? this.description,
      name: name ?? this.name,
      props: props ?? this.props,
      iconPath: iconPath ?? this.iconPath,
      hexId: hexId ?? this.hexId,
      addressingScheme: addressingScheme ?? this.addressingScheme,
      emergency: emergency ?? this.emergency,
      blockId: blockId ?? this.blockId,
      sceneId: sceneId ?? this.sceneId,
      out: out ?? this.out,
      helvarType: helvarType ?? this.helvarType,
      deviceTypeCode: deviceTypeCode ?? this.deviceTypeCode,
      deviceStateCode: deviceStateCode ?? this.deviceStateCode,
      isButtonDevice: isButtonDevice ?? this.isButtonDevice,
      isMultisensor: isMultisensor ?? this.isMultisensor,
      sensorInfo: sensorInfo ?? Map<String, dynamic>.from(this.sensorInfo),
      additionalInfo:
          additionalInfo ?? Map<String, dynamic>.from(this.additionalInfo),
      buttonPoints: buttonPoints ?? List<ButtonPoint>.from(this.buttonPoints),
    );
  }
}

class ButtonPoint {
  final String name;
  final String function;
  final int buttonId;
  final PointPollingRate pollingRate; // Add this field

  ButtonPoint({
    required this.name,
    required this.function,
    required this.buttonId,
    this.pollingRate = PointPollingRate.normal, // Default to normal
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'function': function,
      'buttonId': buttonId,
      'pollingRate': pollingRate.name, // Add this
    };
  }

  factory ButtonPoint.fromJson(Map<String, dynamic> json) {
    return ButtonPoint(
      name: json['name'] as String,
      function: json['function'] as String,
      buttonId: json['buttonId'] as int,
      pollingRate: json['pollingRate'] != null
          ? PointPollingRate.fromString(json['pollingRate'] as String)
          : PointPollingRate.normal,
    );
  }

  ButtonPoint copyWith({
    String? name,
    String? function,
    int? buttonId,
    PointPollingRate? pollingRate,
  }) {
    return ButtonPoint(
      name: name ?? this.name,
      function: function ?? this.function,
      buttonId: buttonId ?? this.buttonId,
      pollingRate: pollingRate ?? this.pollingRate,
    );
  }
}
