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

class Workgroup extends TreeNode {
  final String id;
  final String description;
  final String gatewayRouterIpAddress;
  final bool refreshPropsAfterAction;
  final bool pollEnabled;
  final DateTime? lastPollTime;
  final PointPollingRate pollingRate;
  List<HelvarRouter> routers;
  List<HelvarGroup> groups;

  Workgroup({
    required this.id,
    this.description = '',
    this.gatewayRouterIpAddress = '',
    this.refreshPropsAfterAction = false,
    this.pollEnabled = false,
    this.lastPollTime,
    this.pollingRate = PointPollingRate.normal,
    List<HelvarRouter>? routers,
    List<HelvarGroup>? groups,
  }) : routers = routers ?? [],
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
    PointPollingRate? pollingRate,
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
      pollingRate: pollingRate ?? this.pollingRate,
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
      pollingRate: json['pollingRate'] != null
          ? PointPollingRate.fromString(json['pollingRate'] as String)
          : PointPollingRate.normal,
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
      'pollingRate': pollingRate,
      'routers': routers.map((router) => router.toJson()).toList(),
      'groups': groups.map((group) => group.toJson()).toList(),
    };
  }
}
