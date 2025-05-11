import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/project_settings_provider.dart';
import '../comm/router_command_service.dart';
import '../comm/router_connection_manager.dart';

final serviceConfigurationProvider = Provider<void>((ref) {
  final settings = ref.watch(projectSettingsProvider);

  final commandService = RouterCommandService();
  commandService.configureFromSettings(settings);

  final connectionManager = RouterConnectionManager();
  connectionManager.configureFromSettings(settings);

  return;
});
