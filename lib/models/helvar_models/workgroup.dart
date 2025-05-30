import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';

import 'helvar_router.dart';
import 'helvar_group.dart';

class Workgroup extends TreeNode {
  final String id;
  final String description;
  final String networkInterface;
  final String gatewayRouterIpAddress;
  final bool refreshPropsAfterAction;

  List<HelvarRouter> routers;
  List<HelvarGroup> groups;

  Workgroup({
    required this.id,
    this.description = '',
    required this.networkInterface,
    this.gatewayRouterIpAddress = '',
    this.refreshPropsAfterAction = false,
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

  factory Workgroup.fromJson(Map<String, dynamic> json) {
    return Workgroup(
      id: json['id'] as String,
      description: json['description'] as String? ?? '',
      networkInterface: json['networkInterface'] as String,
      gatewayRouterIpAddress: json['gatewayRouterIpAddress'] as String? ?? '',
      refreshPropsAfterAction:
          json['refreshPropsAfterAction'] as bool? ?? false,
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
      'routers': routers.map((router) => router.toJson()).toList(),
      'groups': groups.map((group) => group.toJson()).toList(),
    };
  }
}
