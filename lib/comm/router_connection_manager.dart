import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/project_settings.dart';
import 'router_connection.dart';
import 'models/router_connection_status.dart';

class RouterConnectionManager {
  static final RouterConnectionManager _instance =
      RouterConnectionManager._internal();
  factory RouterConnectionManager() => _instance;
  RouterConnectionManager._internal();

  final Map<String, RouterConnection> connections = {};

  final connectionstatusController =
      StreamController<RouterConnectionStatus>.broadcast();

  int _maxConcurrentConnections = 10;
  Duration _defaultHeartbeatInterval = const Duration(seconds: 30);
  Duration _defaultConnectionTimeout = const Duration(seconds: 5);

  Stream<RouterConnectionStatus> get connectionStatusStream =>
      connectionstatusController.stream;

  int get connectionCount => connections.length;
  int get maxConnections => _maxConcurrentConnections;

  List<RouterConnectionStatus> get allConnectionStatuses =>
      connections.values.map((conn) => conn.status).toList();

  void configure({int? maxConnections}) {
    if (maxConnections != null) {
      _maxConcurrentConnections = maxConnections;
    }
  }

  void configureFromSettings(ProjectSettings settings) {
    _maxConcurrentConnections = settings.maxConcurrentCommandsPerRouter * 2;
    _defaultHeartbeatInterval =
        Duration(seconds: settings.heartbeatIntervalSeconds);
    _defaultConnectionTimeout =
        Duration(milliseconds: settings.socketTimeoutMs);
  }

  Future<RouterConnection> getConnection(
    String ipAddress, {
    bool forceReconnect = false,
    int port = 50000,
    Duration? heartbeatInterval,
    Duration? connectionTimeout,
  }) async {
    final connectionKey = '$ipAddress:$port';
    print("trying to get connection for:$connectionKey");
    try {
      if (connections.containsKey(connectionKey) && !forceReconnect) {
        final connection = connections[connectionKey]!;

        if (!connection.isConnected) {
          debugPrint('Reconnecting to router at $ipAddress');
          await connection.connect();
        }

        return connection;
      }

      if (connections.length >= _maxConcurrentConnections) {
        throw Exception(
            'Maximum connection limit reached ($_maxConcurrentConnections)');
      }

      debugPrint('Creating new connection to router at $ipAddress');
      final connection = RouterConnection(
        ipAddress: ipAddress,
        port: port,
        heartbeatInterval: heartbeatInterval ?? _defaultHeartbeatInterval,
        connectionTimeout: connectionTimeout ?? _defaultConnectionTimeout,
      );

      connection.statusStream.listen((status) {
        connectionstatusController.add(status);
        if (status.state == RouterConnectionState.failed ||
            status.state == RouterConnectionState.disconnected) {
          debugPrint('Router($ipAddress) connection status: ${status.state}');
          if (status.errorMessage != null) {
            debugPrint('Error: ${status.errorMessage}');
          }
        }
      });

      connections[connectionKey] = connection;
      connectionstatusController.add(connection.status);
      await connection.connect();

      return connection;
    } catch (e) {
      debugPrint('Failed to establish connection to $ipAddress: $e');
      throw Exception('Connection failed to $ipAddress: $e');
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
    await connectionstatusController.close();
  }

  Future<bool> sendCommand(String ipAddress, String command,
      [int port = 50000]) async {
    final connectionKey = '$ipAddress:$port';

    if (!connections.containsKey(connectionKey)) {
      return false;
    }

    return await connections[connectionKey]!.sendCommand(command);
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
