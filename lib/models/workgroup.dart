import 'helvar_router.dart';

class Workgroup {
  final String id;
  final String description;
  final String networkInterface;
  final int groupPowerPollingMinutes;
  final String gatewayRouterIpAddress;
  final bool refreshPropsAfterAction;

  List<HelvarRouter> routers;

  Workgroup({
    required this.id,
    this.description = '',
    required this.networkInterface,
    this.groupPowerPollingMinutes = 15,
    this.gatewayRouterIpAddress = '',
    this.refreshPropsAfterAction = false,
    List<HelvarRouter>? routers,
  }) : routers = routers ?? [];

  void addRouter(HelvarRouter router) {
    routers.add(router);
  }

  void removeRouter(HelvarRouter router) {
    routers.remove(router);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Workgroup && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

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
    };
  }
}
