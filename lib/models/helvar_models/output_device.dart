import '../../utils/logger.dart';
import 'device_action.dart';
import 'helvar_device.dart';

class OutputPoint {
  final String name;
  final String function;
  final int pointId;
  final String pointType;
  dynamic value;

  OutputPoint({
    required this.name,
    required this.function,
    required this.pointId,
    required this.pointType,
    this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'function': function,
      'pointId': pointId,
      'pointType': pointType,
      'value': value,
    };
  }

  factory OutputPoint.fromJson(Map<String, dynamic> json) {
    return OutputPoint(
      name: json['name'] as String,
      function: json['function'] as String,
      pointId: json['pointId'] as int,
      pointType: json['pointType'] as String,
      value: json['value'],
    );
  }
}

class HelvarDriverOutputDevice extends HelvarDevice {
  String missing;
  String faulty;
  int level;
  int proportion;
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
    super.fadeTime,
    super.out,
    super.helvarType = "output",
    super.pointsCreated,
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
    List<OutputPoint>? outputPoints,
  }) : outputPoints = outputPoints ?? [];

  @override
  void recallScene(String sceneParams) {
    logInfo("Recalling scene with params: $sceneParams");
    try {
      if (sceneParams.isNotEmpty) {
        List<String> temp = sceneParams.split(',');

        String timestamp = DateTime.now().toString();
        String s = "Success ($timestamp) Recalled Scene: ${temp[1]}";
        logInfo(s);
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
  void updatePoints() {
    // This method can be used to update point values from real device queries
  }

  @override
  void started() {
    if (!pointsCreated) {
      createOutputPoints(address, getName());
      generateOutputPoints();
      pointsCreated = true;
    }
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
    if (outputPoints.isNotEmpty) return; // Already generated

    final deviceName = description.isEmpty ? "Device_$deviceId" : description;

    // Create the 6 standard output points as shown in Niagara
    outputPoints.addAll([
      OutputPoint(
        name: '${deviceName}_DeviceState',
        function: 'Device State',
        pointId: 1,
        pointType: 'boolean',
        value: false,
      ),
      OutputPoint(
        name: '${deviceName}_LampFailure',
        function: 'Lamp Failure',
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
        function: 'Output Level',
        pointId: 5,
        pointType: 'numeric',
        value: 0.0,
      ),
      OutputPoint(
        name: '${deviceName}_PowerConsumption',
        function: 'Power Consumption',
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

  void createOutputPoints(String deviceAddress, String name) {
    // This method can be overridden to create points in specific systems
  }

  void queryLoadLevel() {
    // This method can be implemented to query the actual load level
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

  static HelvarDriverOutputDevice fromJson(Map<String, dynamic> json) {
    final outputPoints = <OutputPoint>[];
    if (json['outputPoints'] != null) {
      for (var point in (json['outputPoints'] as List)) {
        outputPoints.add(OutputPoint.fromJson(point));
      }
    }

    return HelvarDriverOutputDevice(
      deviceId: json['deviceId'] as int? ?? 1,
      address: json['address'] as String? ?? '@',
      state: json['state'] as String? ?? '',
      description: json['description'] as String? ?? '',
      props: json['props'] as String? ?? '',
      iconPath: json['iconPath'] as String? ?? '',
      hexId: json['hexId'] as String? ?? '',
      addressingScheme: json['addressingScheme'] as String? ?? '',
      emergency: json['emergency'] as bool? ?? false,
      blockId: json['blockId'] as String? ?? '1',
      sceneId: json['sceneId'] as String? ?? '',
      fadeTime: json['fadeTime'] as int? ?? 700,
      out: json['out'] as String? ?? '',
      helvarType: json['helvarType'] as String? ?? 'output',
      pointsCreated: json['pointsCreated'] as bool? ?? false,
      missing: json['missing'] as String? ?? '',
      faulty: json['faulty'] as String? ?? '',
      level: json['level'] as int? ?? 100,
      proportion: json['proportion'] as int? ?? 0,
      deviceTypeCode: json['deviceTypeCode'] as int?,
      deviceStateCode: json['deviceStateCode'] as int?,
      isButtonDevice: json['isButtonDevice'] as bool? ?? false,
      isMultisensor: json['isMultisensor'] as bool? ?? false,
      sensorInfo: json['sensorInfo'] as Map<String, dynamic>? ?? {},
      additionalInfo: json['additionalInfo'] as Map<String, dynamic>? ?? {},
      outputPoints: outputPoints,
    );
  }
}
