import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';

import 'emergency_device.dart';
import 'input_device.dart';
import 'output_device.dart';

abstract class HelvarDevice extends TreeNode {
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
  HelvarDevice({
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
  });

  factory HelvarDevice.fromJson(Map<String, dynamic> json) {
    if (json['helvarType'] == "input") {
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
      );
    }
    if (json['helvarType'] == "output") {
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
    };
  }

  String getIconPath() => iconPath;
  void setIconPath(String path) {
    iconPath = path;
  }
}
