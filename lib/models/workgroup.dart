import 'helvar_node.dart';
import 'helvar_router.dart';
import 'helvar_group.dart';

class Workgroup extends TreeViewNode {
  final String id;
  final String description;
  final String networkInterface;
  final int groupPowerPollingMinutes;
  final String gatewayRouterIpAddress;
  final bool refreshPropsAfterAction;

  List<HelvarRouter> routers;
  List<HelvarGroup> groups;

  Workgroup({
    required this.id,
    this.description = '',
    required this.networkInterface,
    this.groupPowerPollingMinutes = 15,
    this.gatewayRouterIpAddress = '',
    this.refreshPropsAfterAction = false,
    List<HelvarRouter>? routers,
    List<HelvarGroup>? groups,
    super.children,
  })  : routers = routers ?? [],
        groups = groups ?? [],
        super(
          id: id,
          name: description.isNotEmpty ? description : 'Workgroup $id',
          nodeType: TreeViewNodeType.group,
        );

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
      groupPowerPollingMinutes: json['groupPowerPollingMinutes'] as int? ?? 15,
      gatewayRouterIpAddress: json['gatewayRouterIpAddress'] as String? ?? '',
      refreshPropsAfterAction:
          json['refreshPropsAfterAction'] as bool? ?? false,
      routers: (json['routers'] as List?)
          ?.map((routerJson) => HelvarRouter.fromJson(routerJson))
          .toList(),
      groups: (json['groups'] as List?)
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
      'groupPowerPollingMinutes': groupPowerPollingMinutes,
      'gatewayRouterIpAddress': gatewayRouterIpAddress,
      'refreshPropsAfterAction': refreshPropsAfterAction,
      'routers': routers.map((router) => router.toJson()).toList(),
      'groups': groups
          .map((group) => group.toJson())
          .toList(), // Include groups in JSON
    };
  }
}
