import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:grms_designer/utils/logger.dart';

import 'emergency_device.dart';
import 'device_action.dart';
import 'input_device.dart';
import 'output_device.dart';

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
  String out;
  String helvarType;

  int? deviceTypeCode;
  int? deviceStateCode;

  bool isButtonDevice;
  bool isMultisensor;

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
    this.out = "",
    this.helvarType = "output",
    this.deviceTypeCode,
    this.deviceStateCode,
    this.isButtonDevice = false,
    this.isMultisensor = false,
    Map<String, dynamic>? sensorInfo,
    Map<String, dynamic>? additionalInfo,
  }) : sensorInfo = sensorInfo ?? {},
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
        logError("Error in HelvarDevice creation:$e");
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
        out: json['out'] as String? ?? '',
        helvarType: json['helvarType'] as String? ?? 'input',
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
        out: json['out'] as String? ?? '',
        helvarType: json['helvarType'] as String? ?? 'output',
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
    } else {
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
        out: json['out'] as String? ?? '',
        helvarType: json['helvarType'] as String? ?? 'emergency',
        missing: json['missing'] as String? ?? '',
        faulty: json['faulty'] as String? ?? '',
        deviceTypeCode: json['deviceTypeCode'] as int?,
        deviceStateCode: json['deviceStateCode'] as int?,
        isButtonDevice: json['isButtonDevice'] as bool? ?? false,
        isMultisensor: json['isMultisensor'] as bool? ?? false,
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

  void performAction(DeviceAction action, dynamic value);

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
      'out': out,
      'helvarType': helvarType,
      'deviceTypeCode': deviceTypeCode,
      'deviceStateCode': deviceStateCode,
      'isButtonDevice': isButtonDevice,
      'isMultisensor': isMultisensor,
      'sensorInfo': sensorInfo,
      'additionalInfo': additionalInfo,
    };
  }

  String getIconPath() => iconPath;
  void setIconPath(String path) {
    iconPath = path;
  }
}
