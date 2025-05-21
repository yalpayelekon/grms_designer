import '../comm/router_connection_manager.dart';
import '../models/helvar_models/helvar_router.dart';

class ConnectionBatchResult {
  final int successCount;
  final int failureCount;
  final List<String> errors;

  ConnectionBatchResult({
    required this.successCount,
    required this.failureCount,
    required this.errors,
  });
}

class ConnectionService {
  final RouterConnectionManager manager;

  ConnectionService(this.manager);

  Future<ConnectionBatchResult> connectToRouters(
      List<HelvarRouter> routers) async {
    int success = 0;
    int failure = 0;
    List<String> errors = [];

    for (final router in routers) {
      try {
        if (router.ipAddress.isNotEmpty) {
          await manager.getConnection(router.ipAddress);
          success++;
        }
      } catch (e) {
        failure++;
        errors.add('Failed to connect to ${router.ipAddress}: $e');
      }
    }

    return ConnectionBatchResult(
      successCount: success,
      failureCount: failure,
      errors: errors,
    );
  }
}
