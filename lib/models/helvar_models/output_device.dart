import 'package:grms_designer/models/helvar_models/output_point.dart';
import 'package:grms_designer/utils/device/device_utils.dart';

import '../../utils/core/logger.dart';
import 'device_action.dart';
import 'helvar_device.dart';

class HelvarDriverOutputDevice extends HelvarDevice {
  String missing;
  String faulty;
  int level;
  int proportion;
  double powerConsumption;
  List<OutputPoint> outputPoints;

  HelvarDriverOutputDevice({
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
    super.helvarType = "output",
    super.deviceTypeCode,
    super.deviceStateCode,
    super.isButtonDevice,
    super.isMultisensor,
    super.sensorInfo,
    super.additionalInfo,
    this.missing = "",
    this.faulty = "",
    this.level = 100,
    this.proportion = 0,
    this.powerConsumption = 0,
    List<OutputPoint>? outputPoints,
  }) : outputPoints = outputPoints ?? [];

  @override
  void recallScene(String sceneParams) {
    out = handleRecallScene(sceneParams, logInfoOutput: true);
  }

  void directLevel(String levelParams) {
    try {
      List<String> temp = levelParams.split(',');
      String timestamp = DateTime.now().toString();
      String s = "Success ($timestamp) Direct Level Device: ${temp[0]}";
      logInfo(s);
      out = s;
    } catch (e) {
      logError(e.toString());
      out = e.toString();
    }
  }

  void directProportion(String proportionParams) {
    try {
      List<String> temp = proportionParams.split(',');
      String timestamp = DateTime.now().toString();
      String s = "Success ($timestamp) Direct Proportion Device: ${temp[0]}";
      out = s;
      logInfo(s);
    } catch (e) {
      logError(e.toString());
      out = e.toString();
    }
  }

  void modifyProportion(String proportionParams) {
    try {
      List<String> temp = proportionParams.split(',');
      String timestamp = DateTime.now().toString();
      String s = "Success ($timestamp) Direct Proportion Device: ${temp[0]}";
      logInfo(s);
      out = s;
    } catch (e) {
      logError(e.toString());
      out = e.toString();
    }
  }

  @override
  void started() {
    generateOutputPoints();
  }

  String getName() {
    return description.isNotEmpty ? description : "Device_$deviceId";
  }

  @override
  void stopped() {}

  @override
  void performAction(DeviceAction action, dynamic value) {
    switch (action) {
      case DeviceAction.clearResult:
        clearResult();
        break;
      case DeviceAction.recallScene:
        if (value is int) {
          recallScene("1,$value");
        }
        break;
      case DeviceAction.directLevel:
        if (value is int) {
          directLevel("$value");
        }
        break;
      case DeviceAction.directProportion:
        if (value is int) {
          directProportion("$value");
        }
        break;
      case DeviceAction.modifyProportion:
        if (value is int) {
          modifyProportion("$value");
        }
        break;
      default:
        logWarning("Action $action not supported for output device");
    }
  }

  void generateOutputPoints() {
    if (outputPoints.isNotEmpty) return;

    final deviceName = description.isEmpty ? "Device_$deviceId" : description;

    outputPoints.addAll([
      OutputPoint(
        name: '${deviceName}_DeviceState',
        function: 'DeviceState',
        pointId: 1,
        pointType: 'boolean',
        value: false,
      ),
      OutputPoint(
        name: '${deviceName}_LampFailure',
        function: 'LampFailure',
        pointId: 2,
        pointType: 'boolean',
        value: false,
      ),
      OutputPoint(
        name: '${deviceName}_Missing',
        function: 'Missing',
        pointId: 3,
        pointType: 'boolean',
        value: false,
      ),
      OutputPoint(
        name: '${deviceName}_Faulty',
        function: 'Faulty',
        pointId: 4,
        pointType: 'boolean',
        value: false,
      ),
      OutputPoint(
        name: '${deviceName}_OutputLevel',
        function: 'OutputLevel',
        pointId: 5,
        pointType: 'numeric',
        value: 0.0,
      ),
      OutputPoint(
        name: '${deviceName}_PowerConsumption',
        function: 'PowerConsumption',
        pointId: 6,
        pointType: 'numeric',
        value: 0.0,
      ),
    ]);
  }

  Future<void> updatePointValue(int pointId, dynamic value) async {
    final point = outputPoints.firstWhere(
      (p) => p.pointId == pointId,
      orElse: () => throw ArgumentError('Point with ID $pointId not found'),
    );

    point.value = value;
    logInfo('Updated point ${point.name} to value: $value');
  }

  OutputPoint? getPointById(int pointId) {
    try {
      return outputPoints.firstWhere((p) => p.pointId == pointId);
    } catch (e) {
      return null;
    }
  }

  OutputPoint? getPointByName(String name) {
    try {
      return outputPoints.firstWhere((p) => p.name == name);
    } catch (e) {
      return null;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['missing'] = missing;
    json['faulty'] = faulty;
    json['level'] = level;
    json['proportion'] = proportion;
    json['outputPoints'] = outputPoints.map((point) => point.toJson()).toList();
    return json;
  }
}
