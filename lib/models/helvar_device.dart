import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';

import 'emergency_device.dart';
import 'input_device.dart';
import 'output_device.dart';

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
    return {
      'name': name,
      'function': function,
      'buttonId': buttonId,
    };
  }

  factory ButtonPoint.fromJson(Map<String, dynamic> json) {
    return ButtonPoint(
      name: json['name'] as String,
      function: json['function'] as String,
      buttonId: json['buttonId'] as int,
    );
  }
}

abstract class HelvarDevice extends TreeNode {
  int cluster;
  int routerId;
  int subnet;
  int deviceIndex;
  int deviceId;
  String address;
  String state;
  String description;
  String props;
  String iconPath;
  String hexId;
  String addressingScheme;
  bool emergency;
  String blockId;
  String sceneId;
  int fadeTime;
  String out;
  String helvarType;
  bool pointsCreated;

  int? deviceTypeCode;
  int? deviceStateCode;

  bool isButtonDevice;
  bool isMultisensor;

  List<ButtonPoint> buttonPoints;

  Map<String, dynamic> sensorInfo;

  Map<String, dynamic> additionalInfo;

  HelvarDevice({
    this.cluster = 1,
    this.routerId = 1,
    this.subnet = 1,
    this.deviceIndex = 1,
    this.deviceId = 1,
    this.address = "@",
    this.state = "",
    this.description = "",
    this.props = "",
    this.iconPath = "",
    this.hexId = "",
    this.addressingScheme = "",
    this.emergency = false,
    this.blockId = "1",
    this.sceneId = "",
    this.fadeTime = 700,
    this.out = "",
    this.helvarType = "output",
    this.pointsCreated = false,
    this.deviceTypeCode,
    this.deviceStateCode,
    this.isButtonDevice = false,
    this.isMultisensor = false,
    List<ButtonPoint>? buttonPoints,
    Map<String, dynamic>? sensorInfo,
    Map<String, dynamic>? additionalInfo,
  })  : buttonPoints = buttonPoints ?? [],
        sensorInfo = sensorInfo ?? {},
        additionalInfo = additionalInfo ?? {} {
    if (address.startsWith('@')) {
      address = address.substring(1);
    }

    final parts = address.split('.');
    if (parts.length == 4) {
      try {
        cluster = int.parse(parts[0]);
        routerId = int.parse(parts[1]);
        subnet = int.parse(parts[2]);
        deviceIndex = int.parse(parts[3]);
      } catch (e) {
        print("Error in HelvarDevice creation:$e");
      }
    }
  }

  factory HelvarDevice.fromJson(Map<String, dynamic> json) {
    final helvarType = json['helvarType'] as String? ?? 'output';

    final buttonPoints = <ButtonPoint>[];
    if (json['buttonPoints'] != null) {
      for (var point in (json['buttonPoints'] as List)) {
        buttonPoints.add(ButtonPoint.fromJson(point));
      }
    }

    if (helvarType == "input") {
      return HelvarDriverInputDevice(
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
        helvarType: json['helvarType'] as String? ?? 'input',
        pointsCreated: json['pointsCreated'] as bool? ?? false,
        deviceTypeCode: json['deviceTypeCode'] as int?,
        deviceStateCode: json['deviceStateCode'] as int?,
        isButtonDevice: json['isButtonDevice'] as bool? ?? false,
        isMultisensor: json['isMultisensor'] as bool? ?? false,
        buttonPoints: buttonPoints,
        sensorInfo: json['sensorInfo'] as Map<String, dynamic>? ?? {},
        additionalInfo: json['additionalInfo'] as Map<String, dynamic>? ?? {},
      );
    }
    if (helvarType == "output") {
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
        buttonPoints: buttonPoints,
        sensorInfo: json['sensorInfo'] as Map<String, dynamic>? ?? {},
        additionalInfo: json['additionalInfo'] as Map<String, dynamic>? ?? {},
      );
    } else {
      // Default to emergency device if (json['helvarType'] == "emergency")
      return HelvarDriverEmergencyDevice(
        deviceId: json['deviceId'] as int? ?? 1,
        address: json['address'] as String? ?? '@',
        state: json['state'] as String? ?? '',
        description: json['description'] as String? ?? '',
        props: json['props'] as String? ?? '',
        iconPath: json['iconPath'] as String? ?? '',
        hexId: json['hexId'] as String? ?? '',
        addressingScheme: json['addressingScheme'] as String? ?? '',
        emergency: json['emergency'] as bool? ?? true,
        blockId: json['blockId'] as String? ?? '1',
        sceneId: json['sceneId'] as String? ?? '',
        fadeTime: json['fadeTime'] as int? ?? 700,
        out: json['out'] as String? ?? '',
        helvarType: json['helvarType'] as String? ?? 'emergency',
        pointsCreated: json['pointsCreated'] as bool? ?? false,
        missing: json['missing'] as String? ?? '',
        faulty: json['faulty'] as String? ?? '',
        deviceTypeCode: json['deviceTypeCode'] as int?,
        deviceStateCode: json['deviceStateCode'] as int?,
        isButtonDevice: json['isButtonDevice'] as bool? ?? false,
        isMultisensor: json['isMultisensor'] as bool? ?? false,
        buttonPoints: buttonPoints,
        sensorInfo: json['sensorInfo'] as Map<String, dynamic>? ?? {},
        additionalInfo: json['additionalInfo'] as Map<String, dynamic>? ?? {},
      );
    }
  }

  void updatePoints();
  void started();
  void stopped();
  void recallScene(String sceneParams);
  void clearResult() {
    out = "";
  }

  void generateButtonPoints() {
    if (!isButtonDevice) return;

    buttonPoints.clear();

    final deviceName = description.isEmpty ? "Device_$deviceId" : description;

    buttonPoints.add(ButtonPoint(
      name: '${deviceName}_Missing',
      function: 'Status',
      buttonId: 0,
    ));

    // Add buttons (typically 7 for Button 135)
    for (int i = 1; i <= 7; i++) {
      buttonPoints.add(ButtonPoint(
        name: '${deviceName}_Button$i',
        function: 'Button',
        buttonId: i,
      ));
    }

    // Add IR receivers
    for (int i = 1; i <= 7; i++) {
      buttonPoints.add(ButtonPoint(
        name: '${deviceName}_IR$i',
        function: 'IR Receiver',
        buttonId: i + 100, // Using offset for IR receivers
      ));
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'address': address,
      'state': state,
      'description': description,
      'props': props,
      'iconPath': iconPath,
      'hexId': hexId,
      'addressingScheme': addressingScheme,
      'emergency': emergency,
      'blockId': blockId,
      'sceneId': sceneId,
      'fadeTime': fadeTime,
      'out': out,
      'helvarType': helvarType,
      'pointsCreated': pointsCreated,
      'deviceTypeCode': deviceTypeCode,
      'deviceStateCode': deviceStateCode,
      'isButtonDevice': isButtonDevice,
      'isMultisensor': isMultisensor,
      'buttonPoints': buttonPoints.map((point) => point.toJson()).toList(),
      'sensorInfo': sensorInfo,
      'additionalInfo': additionalInfo,
    };
  }

  String getIconPath() => iconPath;
  void setIconPath(String path) {
    iconPath = path;
  }
}
