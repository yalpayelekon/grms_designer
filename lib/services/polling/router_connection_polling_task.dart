import 'package:grms_designer/utils/core/logger.dart';

import '../../comm/router_connection_manager.dart';
import '../../models/helvar_models/helvar_router.dart';
import 'polling_task.dart';

class RouterConnectionPollingTask extends PollingTask {
  final RouterConnectionManager connectionManager;
  final HelvarRouter router;
  final Function(HelvarRouter router, bool isConnected)? onConnectionChanged;

  RouterConnectionPollingTask({
    required this.connectionManager,
    required this.router,
    this.onConnectionChanged,
    super.interval = const Duration(seconds: 30),
  }) : super(
         id: 'router_connection_${router.address}',
         name: 'Router ${router.address} Connection',
         parameters: {
           'routerAddress': router.address,
           'routerIp': router.ipAddress,
         },
       );

  @override
  Future<PollingResult> execute() async {
    try {
      if (router.ipAddress.isEmpty) {
        return PollingResult.failure('Router has no IP address');
      }

      final connection = connectionManager.connections[router.ipAddress];
      final isConnected = connection?.isConnected ?? false;

      final previousState = router.isNormal;
      router.isNormal = isConnected;
      router.isMissing = !isConnected;

      if (previousState != isConnected) {
        onConnectionChanged?.call(router, isConnected);
        logInfo(
          'Router ${router.address} connection changed: ${isConnected ? 'Connected' : 'Disconnected'}',
        );
      }

      return PollingResult.success({
        'isConnected': isConnected,
        'connectionState': connection?.status.state.name,
        'lastStateChange': connection?.status.lastStateChange,
        'reconnectAttempts': connection?.status.reconnectAttempts ?? 0,
      });
    } catch (e) {
      return PollingResult.failure('Error checking router connection: $e');
    }
  }

  @override
  void onStart() {
    logInfo('Started connection monitoring for router ${router.address}');
  }

  @override
  void onStop() {
    logInfo('Stopped connection monitoring for router ${router.address}');
  }
}
