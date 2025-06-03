import 'package:flutter/material.dart';
import 'package:grms_designer/models/helvar_models/output_device.dart';

enum PollingRate {
  disabled,
  fast,
  normal,
  slow;

  String get displayName {
    switch (this) {
      case PollingRate.disabled:
        return 'Disabled';
      case PollingRate.fast:
        return 'Fast';
      case PollingRate.normal:
        return 'Normal';
      case PollingRate.slow:
        return 'Slow';
    }
  }

  Color get color {
    switch (this) {
      case PollingRate.disabled:
        return Colors.grey;
      case PollingRate.fast:
        return Colors.red;
      case PollingRate.normal:
        return Colors.green;
      case PollingRate.slow:
        return Colors.blue;
    }
  }
}

class PointPollingConfig {
  final String pointId;
  final String pointName;
  final PollingRate rate;
  final DateTime? lastPolled;
  final bool isActive;

  PointPollingConfig({
    required this.pointId,
    required this.pointName,
    this.rate = PollingRate.disabled,
    this.lastPolled,
    this.isActive = false,
  });

  PointPollingConfig copyWith({
    String? pointId,
    String? pointName,
    PollingRate? rate,
    DateTime? lastPolled,
    bool? isActive,
  }) {
    return PointPollingConfig(
      pointId: pointId ?? this.pointId,
      pointName: pointName ?? this.pointName,
      rate: rate ?? this.rate,
      lastPolled: lastPolled ?? this.lastPolled,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pointId': pointId,
      'pointName': pointName,
      'rate': rate.name,
      'lastPolled': lastPolled?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory PointPollingConfig.fromJson(Map<String, dynamic> json) {
    return PointPollingConfig(
      pointId: json['pointId'] as String,
      pointName: json['pointName'] as String,
      rate: PollingRate.values.firstWhere(
        (e) => e.name == json['rate'],
        orElse: () => PollingRate.disabled,
      ),
      lastPolled: json['lastPolled'] != null
          ? DateTime.parse(json['lastPolled'])
          : null,
      isActive: json['isActive'] as bool? ?? false,
    );
  }
}

class DevicePollingConfig {
  final String deviceId;
  final String deviceAddress;
  final Map<String, PointPollingConfig> pointConfigs;

  DevicePollingConfig({
    required this.deviceId,
    required this.deviceAddress,
    Map<String, PointPollingConfig>? pointConfigs,
  }) : pointConfigs = pointConfigs ?? {};

  static DevicePollingConfig createForOutputDevice(
    HelvarDriverOutputDevice device,
  ) {
    final pointConfigs = <String, PointPollingConfig>{};

    for (final point in device.outputPoints) {
      final pointId = '${device.address}_${point.pointId}';
      pointConfigs[pointId] = PointPollingConfig(
        pointId: pointId,
        pointName: point.function,
        rate: PollingRate.normal,
      );
    }

    return DevicePollingConfig(
      deviceId: device.deviceId.toString(),
      deviceAddress: device.address,
      pointConfigs: pointConfigs,
    );
  }
}
