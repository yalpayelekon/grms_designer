import '../../models/project_settings.dart';

class ConnectionConfig {
  final Duration timeout;
  final Duration heartbeatInterval;
  final Duration commandTimeout;
  final int maxRetries;
  final int maxConcurrentCommands;
  final int historySize;
  final int maxConnections;

  const ConnectionConfig({
    this.timeout = const Duration(seconds: 5),
    this.heartbeatInterval = const Duration(seconds: 30),
    this.commandTimeout = const Duration(seconds: 10),
    this.maxRetries = 3,
    this.maxConcurrentCommands = 5,
    this.historySize = 100,
    this.maxConnections = 10,
  });

  factory ConnectionConfig.fromProjectSettings(ProjectSettings settings) {
    return ConnectionConfig(
      timeout: Duration(milliseconds: settings.socketTimeoutMs),
      heartbeatInterval: Duration(seconds: settings.heartbeatIntervalSeconds),
      commandTimeout: Duration(milliseconds: settings.commandTimeoutMs),
      maxRetries: settings.maxCommandRetries,
      maxConcurrentCommands: settings.maxConcurrentCommandsPerRouter,
      historySize: settings.commandHistorySize,
      maxConnections: settings.maxConcurrentCommandsPerRouter * 2, // NEW
    );
  }
}
