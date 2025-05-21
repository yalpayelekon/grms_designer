import 'dart:async';

import 'package:grms_designer/protocol/protocol_constants.dart';

import '../models/project_settings.dart';
import 'models/connection_config.dart';
import 'router_connection.dart';
import 'models/router_connection_status.dart';

class RouterConnectionManager {
  final ConnectionConfig config;
  final Map<String, RouterConnection> connections = {};
  final connectionStatusController =
      StreamController<RouterConnectionStatus>.broadcast();

  RouterConnectionManager([this.config = const ConnectionConfig()]);

  int _maxConcurrentConnections = 10;

  Stream<RouterConnectionStatus> get connectionStatusStream =>
      connectionStatusController.stream;

  List<RouterConnectionStatus> get allConnectionStatuses =>
      connections.values.map((conn) => conn.status).toList();

  int get connectionCount => connections.length;
  int get maxConnections => _maxConcurrentConnections;

  void configure({int? maxConnections}) {
    if (maxConnections != null) {
      _maxConcurrentConnections = maxConnections;
    }
  }

  void configureFromSettings(ProjectSettings settings) {
    _maxConcurrentConnections = settings.maxConcurrentCommandsPerRouter * 2;
  }

  Future<RouterConnection> getConnection(
    String ipAddress, {
    bool forceReconnect = false,
    int port = defaultTcpPort,
  }) async {
    final connectionKey = '$ipAddress:$port';

    try {
      if (connections.containsKey(connectionKey) && !forceReconnect) {
        final connection = connections[connectionKey]!;

        if (!connection.isConnected) {
          await connection.connect();
        }

        return connection;
      }

      if (connections.length >= config.maxConcurrentCommands * 2) {
        throw Exception(
            'Maximum connection limit reached (${config.maxConcurrentCommands * 2})');
      }

      final connection = RouterConnection(
        ipAddress: ipAddress,
        port: port,
        heartbeatInterval: config.heartbeatInterval,
        connectionTimeout: config.timeout,
      );

      connection.statusStream.listen((status) {
        connectionStatusController.add(status);
      });

      connections[connectionKey] = connection;
      await connection.connect();

      return connection;
    } catch (e) {
      throw Exception('Failed to establish connection to $ipAddress: $e');
    }
  }

  bool hasConnection(String ipAddress, [int port = 50000]) {
    final connectionKey = '$ipAddress:$port';
    return connections.containsKey(connectionKey);
  }

  Future<void> closeConnection(String ipAddress, [int port = 50000]) async {
    final connectionKey = '$ipAddress:$port';

    if (connections.containsKey(connectionKey)) {
      final connection = connections[connectionKey]!;
      await connection.dispose();
      connections.remove(connectionKey);
    }
  }

  Future<void> closeAllConnections() async {
    final futures =
        connections.values.map((connection) => connection.dispose());
    await Future.wait(futures);
    connections.clear();
  }

  Future<void> dispose() async {
    await closeAllConnections();
    await connectionStatusController.close();
  }

  Map<String, dynamic> getConnectionStats() {
    int connected = 0;
    int connecting = 0;
    int reconnecting = 0;
    int failed = 0;
    int disconnected = 0;

    for (var connection in connections.values) {
      switch (connection.status.state) {
        case RouterConnectionState.connected:
          connected++;
          break;
        case RouterConnectionState.connecting:
          connecting++;
          break;
        case RouterConnectionState.reconnecting:
          reconnecting++;
          break;
        case RouterConnectionState.failed:
          failed++;
          break;
        case RouterConnectionState.disconnected:
          disconnected++;
          break;
      }
    }

    return {
      'total': connections.length,
      'connected': connected,
      'connecting': connecting,
      'reconnecting': reconnecting,
      'failed': failed,
      'disconnected': disconnected,
    };
  }
}
