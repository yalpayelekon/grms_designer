import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../comm/router_connection_manager.dart';
import '../comm/models/router_connection_status.dart';

final routerConnectionManagerProvider =
    Provider<RouterConnectionManager>((ref) {
  final manager = RouterConnectionManager();

  ref.onDispose(() {
    manager.dispose();
  });

  return manager;
});

final connectionStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final manager = ref.watch(routerConnectionManagerProvider);
  return manager.getConnectionStats();
});

final routerConnectionStatusesProvider =
    Provider<List<RouterConnectionStatus>>((ref) {
  final manager = ref.watch(routerConnectionManagerProvider);
  return manager.allConnectionStatuses;
});

final routerConnectionStatusStreamProvider =
    StreamProvider<RouterConnectionStatus>((ref) {
  final manager = ref.watch(routerConnectionManagerProvider);
  return manager.connectionStatusStream;
});
