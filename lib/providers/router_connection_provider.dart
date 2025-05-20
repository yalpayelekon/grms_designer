import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../comm/models/command_models.dart';
import '../comm/router_command_service.dart';
import '../comm/router_connection.dart';
import '../comm/router_connection_manager.dart';
import '../comm/models/router_connection_status.dart';
import '../services/discovery_service.dart';
import 'project_settings_provider.dart';

final routerConnectionManagerProvider =
    Provider<RouterConnectionManager>((ref) {
  final settings = ref.watch(projectSettingsProvider);
  final manager = RouterConnectionManager();
  manager.configureFromSettings(settings);
  return manager;
});

final routerCommandServiceProvider = Provider<RouterCommandService>((ref) {
  final connectionManager = ref.watch(routerConnectionManagerProvider);
  final settings = ref.watch(projectSettingsProvider);

  final service = RouterCommandService(connectionManager);
  service.configureFromSettings(settings);
  return service;
});

final routerConnectionsProvider =
    Provider<Map<String, RouterConnection>>((ref) {
  final manager = ref.watch(routerConnectionManagerProvider);
  return manager.connections;
});

final routerConnectionStatusesProvider =
    Provider<List<RouterConnectionStatus>>((ref) {
  ref.watch(routerConnectionsProvider);
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

final routerCommandConfigurationProvider = Provider<void>((ref) {
  final settings = ref.watch(projectSettingsProvider);
  final commandService = ref.watch(routerCommandServiceProvider);

  commandService.configureFromSettings(settings);

  return;
});

final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  final commandService = ref.watch(routerCommandServiceProvider);
  return DiscoveryService(commandService);
});

class RouterConnectionsNotifier
    extends StateNotifier<Map<String, RouterConnection>> {
  final RouterConnectionManager _manager;
  StreamSubscription? _subscription;

  RouterConnectionsNotifier(this._manager) : super({..._manager.connections}) {
    _subscription = _manager.connectionStatusStream.listen((_) {
      state = {..._manager.connections};
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
