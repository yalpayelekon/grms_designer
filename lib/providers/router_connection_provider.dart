import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../comm/models/command_models.dart';
import '../comm/models/connection_config.dart';
import '../comm/router_command_service.dart';
import '../comm/router_connection.dart';
import '../comm/router_connection_manager.dart';
import '../comm/models/router_connection_status.dart';
import '../services/connection_service.dart';
import '../services/discovery_service.dart';
import 'project_settings_provider.dart';

final connectionConfigProvider = Provider<ConnectionConfig>((ref) {
  final settings = ref.watch(projectSettingsProvider);
  return ConnectionConfig.fromProjectSettings(settings);
});

final routerConnectionManagerProvider =
    Provider<RouterConnectionManager>((ref) {
  final config = ref.watch(connectionConfigProvider);
  return RouterConnectionManager(config);
});

final routerCommandServiceProvider = Provider<RouterCommandService>((ref) {
  final connectionManager = ref.watch(routerConnectionManagerProvider);
  final config = ref.watch(connectionConfigProvider);
  return RouterCommandService(connectionManager, config);
});

final routerConnectionsProvider =
    Provider<Map<String, RouterConnection>>((ref) {
  final manager = ref.watch(routerConnectionManagerProvider);
  return manager.connections;
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

final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  final commandService = ref.watch(routerCommandServiceProvider);
  return DiscoveryService(commandService);
});

final connectionServiceProvider = Provider<ConnectionService>((ref) {
  final manager = ref.watch(routerConnectionManagerProvider);
  return ConnectionService(manager);
});
