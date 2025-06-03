import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:grms_designer/services/polling/polling_presets.dart';

import 'helvar_router.dart';
import 'helvar_group.dart';

enum PointPollingRate {
  disabled,
  fast,
  normal,
  slow;

  String get displayName {
    switch (this) {
      case PointPollingRate.disabled:
        return 'Disabled';
      case PointPollingRate.fast:
        return 'Fast (10s)';
      case PointPollingRate.normal:
        return 'Normal (1m)';
      case PointPollingRate.slow:
        return 'Slow (5m)';
    }
  }

  Duration get duration {
    switch (this) {
      case PointPollingRate.disabled:
        return Duration.zero;
      case PointPollingRate.fast:
        return PollingPresets.fast;
      case PointPollingRate.normal:
        return PollingPresets.normal;
      case PointPollingRate.slow:
        return PollingPresets.slow;
    }
  }

  static PointPollingRate fromString(String value) {
    return PointPollingRate.values.firstWhere(
      (rate) => rate.name == value,
      orElse: () => PointPollingRate.normal,
    );
  }
}

class DevicePointPollingConfig {
  final Map<int, PointPollingRate> outputPointRates; // pointId -> rate
  final PointPollingRate inputPointRate; // For input device points

  DevicePointPollingConfig({
    Map<int, PointPollingRate>? outputPointRates,
    this.inputPointRate = PointPollingRate.normal,
  }) : outputPointRates = outputPointRates ?? _getDefaultOutputPointRates();

  static Map<int, PointPollingRate> _getDefaultOutputPointRates() {
    return {
      1: PointPollingRate.normal, // Device State
      2: PointPollingRate.normal, // Lamp Failure
      3: PointPollingRate.normal, // Missing
      4: PointPollingRate.normal, // Faulty
      5: PointPollingRate.fast, // Output Level (more frequent)
      6: PointPollingRate.slow, // Power Consumption (less frequent)
    };
  }

  DevicePointPollingConfig copyWith({
    Map<int, PointPollingRate>? outputPointRates,
    PointPollingRate? inputPointRate,
  }) {
    return DevicePointPollingConfig(
      outputPointRates: outputPointRates ?? this.outputPointRates,
      inputPointRate: inputPointRate ?? this.inputPointRate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'outputPointRates': outputPointRates.map(
        (key, value) => MapEntry(key.toString(), value.name),
      ),
      'inputPointRate': inputPointRate.name,
    };
  }

  factory DevicePointPollingConfig.fromJson(Map<String, dynamic> json) {
    final outputRatesJson =
        json['outputPointRates'] as Map<String, dynamic>? ?? {};
    final outputPointRates = <int, PointPollingRate>{};

    outputRatesJson.forEach((key, value) {
      final pointId = int.tryParse(key);
      if (pointId != null) {
        outputPointRates[pointId] = PointPollingRate.fromString(
          value as String,
        );
      }
    });

    final defaultRates = _getDefaultOutputPointRates();
    defaultRates.forEach((pointId, defaultRate) {
      outputPointRates.putIfAbsent(pointId, () => defaultRate);
    });

    return DevicePointPollingConfig(
      outputPointRates: outputPointRates,
      inputPointRate: PointPollingRate.fromString(
        json['inputPointRate'] as String? ?? 'normal',
      ),
    );
  }
}

class Workgroup extends TreeNode {
  final String id;
  final String description;
  final String gatewayRouterIpAddress;
  final bool refreshPropsAfterAction;
  final bool pollEnabled;
  final DateTime? lastPollTime;
  final DevicePointPollingConfig pointPollingConfig;
  List<HelvarRouter> routers;
  List<HelvarGroup> groups;

  Workgroup({
    required this.id,
    this.description = '',
    this.gatewayRouterIpAddress = '',
    this.refreshPropsAfterAction = false,
    this.pollEnabled = false,
    this.lastPollTime,
    DevicePointPollingConfig? pointPollingConfig,
    List<HelvarRouter>? routers,
    List<HelvarGroup>? groups,
  }) : pointPollingConfig = pointPollingConfig ?? DevicePointPollingConfig(),
       routers = routers ?? [],
       groups = groups ?? [];

  void addRouter(HelvarRouter router) {
    routers.add(router);
  }

  void removeRouter(HelvarRouter router) {
    routers.remove(router);
  }

  void addGroup(HelvarGroup group) {
    groups.add(group);
  }

  void removeGroup(HelvarGroup group) {
    groups.remove(group);
  }

  Workgroup copyWith({
    String? id,
    String? description,
    String? networkInterface,
    int? groupPowerPollingMinutes,
    String? gatewayRouterIpAddress,
    bool? refreshPropsAfterAction,
    bool? pollEnabled,
    DateTime? lastPollTime,
    DevicePointPollingConfig? pointPollingConfig,
    List<HelvarRouter>? routers,
    List<HelvarGroup>? groups,
  }) {
    return Workgroup(
      id: id ?? this.id,
      description: description ?? this.description,
      gatewayRouterIpAddress:
          gatewayRouterIpAddress ?? this.gatewayRouterIpAddress,
      refreshPropsAfterAction:
          refreshPropsAfterAction ?? this.refreshPropsAfterAction,
      pollEnabled: pollEnabled ?? this.pollEnabled,
      lastPollTime: lastPollTime ?? this.lastPollTime,
      pointPollingConfig: pointPollingConfig ?? this.pointPollingConfig,
      routers: routers ?? this.routers,
      groups: groups ?? this.groups,
    );
  }

  factory Workgroup.fromJson(Map<String, dynamic> json) {
    return Workgroup(
      id: json['id'] as String,
      description: json['description'] as String? ?? '',
      gatewayRouterIpAddress: json['gatewayRouterIpAddress'] as String? ?? '',
      refreshPropsAfterAction:
          json['refreshPropsAfterAction'] as bool? ?? false,
      pollEnabled: json['pollEnabled'] as bool? ?? false,
      lastPollTime: json['lastPollTime'] != null
          ? DateTime.parse(json['lastPollTime'] as String)
          : null,
      pointPollingConfig: json['pointPollingConfig'] != null
          ? DevicePointPollingConfig.fromJson(json['pointPollingConfig'])
          : DevicePointPollingConfig(),
      routers: (json['routers'] as List?)
          ?.map((routerJson) => HelvarRouter.fromJson(routerJson))
          .toList(),
      groups:
          (json['groups'] as List?)
              ?.map((groupJson) => HelvarGroup.fromJson(groupJson))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'gatewayRouterIpAddress': gatewayRouterIpAddress,
      'refreshPropsAfterAction': refreshPropsAfterAction,
      'pollEnabled': pollEnabled,
      'lastPollTime': lastPollTime?.toIso8601String(),
      'pointPollingConfig': pointPollingConfig.toJson(),
      'routers': routers.map((router) => router.toJson()).toList(),
      'groups': groups.map((group) => group.toJson()).toList(),
    };
  }

  PointPollingRate getOutputPointRate(int pointId) {
    return pointPollingConfig.outputPointRates[pointId] ??
        PointPollingRate.normal;
  }

  PointPollingRate get inputPointRate => pointPollingConfig.inputPointRate;

  void updateOutputPointRate(int pointId, PointPollingRate rate) {
    final newRates = Map<int, PointPollingRate>.from(
      pointPollingConfig.outputPointRates,
    );
    newRates[pointId] = rate;
  }
}
