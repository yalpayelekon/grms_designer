import '../../models/helvar_models/helvar_group.dart';
import '../../models/helvar_models/workgroup.dart';

extension HelvarGroupExtensions on HelvarGroup {
  int? get parsedGroupId {
    return int.tryParse(groupId);
  }

  String resolveRouterIp(Workgroup workgroup) {
    if (gatewayRouterIpAddress.isNotEmpty) return gatewayRouterIpAddress;
    if (workgroup.routers.isNotEmpty) return workgroup.routers.first.ipAddress;
    return '';
  }
}
