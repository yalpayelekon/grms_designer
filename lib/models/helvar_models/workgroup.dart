import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';

import 'helvar_router.dart';
import 'helvar_group.dart';

class Workgroup extends TreeNode {
  final String id;
  final String description;
  final String networkInterface;
  final String gatewayRouterIpAddress;
  final bool refreshPropsAfterAction;
  final bool pollEnabled;
  final DateTime? lastPollTime;
  List<HelvarRouter> routers;
  List<HelvarGroup> groups;

  Workgroup({
    required this.id,
    this.description = '',
    required this.networkInterface,
    this.gatewayRouterIpAddress = '',
    this.refreshPropsAfterAction = false,
    this.pollEnabled = false,
    this.lastPollTime,
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
    List<HelvarRouter>? routers,
    List<HelvarGroup>? groups,
  }) {
    return Workgroup(
      id: id ?? this.id,
      description: description ?? this.description,
      networkInterface: networkInterface ?? this.networkInterface,
      gatewayRouterIpAddress:
          gatewayRouterIpAddress ?? this.gatewayRouterIpAddress,
      refreshPropsAfterAction:
          refreshPropsAfterAction ?? this.refreshPropsAfterAction,
      pollEnabled: pollEnabled ?? this.pollEnabled,
      lastPollTime: lastPollTime ?? this.lastPollTime,
      routers: routers ?? this.routers,
      groups: groups ?? this.groups,
    );
  }

  factory Workgroup.fromJson(Map<String, dynamic> json) {
    return Workgroup(
      id: json['id'] as String,
      description: json['description'] as String? ?? '',
      networkInterface: json['networkInterface'] as String,
      gatewayRouterIpAddress: json['gatewayRouterIpAddress'] as String? ?? '',
      refreshPropsAfterAction:
          json['refreshPropsAfterAction'] as bool? ?? false,
      pollEnabled: json['pollEnabled'] as bool? ?? false,
      lastPollTime: json['lastPollTime'] != null
          ? DateTime.parse(json['lastPollTime'] as String)
          : null,
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
      'networkInterface': networkInterface,
      'gatewayRouterIpAddress': gatewayRouterIpAddress,
      'refreshPropsAfterAction': refreshPropsAfterAction,
      'pollEnabled': pollEnabled,
      'lastPollTime': lastPollTime?.toIso8601String(),
      'routers': routers.map((router) => router.toJson()).toList(),
      'groups': groups.map((group) => group.toJson()).toList(),
    };
  }
}
