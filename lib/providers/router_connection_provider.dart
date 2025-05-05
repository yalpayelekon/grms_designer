import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../comm/models/command_models.dart';
import '../comm/router_command_service.dart';
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

final routerCommandServiceProvider = Provider<RouterCommandService>((ref) {
  return RouterCommandService();
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

final commandHistoryProvider = Provider<List<QueuedCommand>>((ref) {
  final service = ref.watch(routerCommandServiceProvider);
  return service.commandHistory;
});
