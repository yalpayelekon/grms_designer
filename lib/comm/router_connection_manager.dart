import 'dart:async';
import 'router_connection.dart';
import 'models/router_connection_status.dart';

class RouterConnectionManager {
  // Singleton pattern
  static final RouterConnectionManager _instance =
      RouterConnectionManager._internal();
  factory RouterConnectionManager() => _instance;
  RouterConnectionManager._internal();

  // Connection storage
  final Map<String, RouterConnection> connections = {};

  // Status stream controller
  final connectionstatusController =
      StreamController<RouterConnectionStatus>.broadcast();

  // Configuration
  int _maxConcurrentConnections = 1000; // Default limit, can be changed

  // Public getters
  Stream<RouterConnectionStatus> get connectionStatusStream =>
      connectionstatusController.stream;

  int get connectionCount => connections.length;
  int get maxConnections => _maxConcurrentConnections;

  List<RouterConnectionStatus> get allConnectionStatuses =>
      connections.values.map((conn) => conn.status).toList();

  // Configure the manager
  void configure({int? maxConnections}) {
    if (maxConnections != null) {
      _maxConcurrentConnections = maxConnections;
    }
  }

  // Get or create a connection to a router
  Future<RouterConnection> getConnection(
    String ipAddress,
    String routerId, {
    bool forceReconnect = false,
    int port = 50000,
    Duration? heartbeatInterval,
    Duration? connectionTimeout,
  }) async {
    final connectionKey = '$ipAddress:$port';

    // Check if we already have a connection
    if (connections.containsKey(connectionKey) && !forceReconnect) {
      final connection = connections[connectionKey]!;

      // If disconnected, try to reconnect
      if (!connection.isConnected) {
        await connection.connect();
      }

      return connection;
    }

    // Check if we've hit connection limit
    if (connections.length >= _maxConcurrentConnections) {
      throw Exception('Maximum connection limit reached ($maxConnections)');
    }

    // Create a new connection
    final connection = RouterConnection(
      ipAddress: ipAddress,
      routerId: routerId,
      port: port,
      heartbeatInterval: heartbeatInterval ?? const Duration(seconds: 30),
      connectionTimeout: connectionTimeout ?? const Duration(seconds: 5),
    );

    // Forward status updates to our global stream
    connection.statusStream.listen((status) {
      connectionstatusController.add(status);
    });

    // Store and connect
    connections[connectionKey] = connection;
    await connection.connect();

    return connection;
  }

  // Check if we have a connection to a router
  bool hasConnection(String ipAddress, [int port = 50000]) {
    final connectionKey = '$ipAddress:$port';
    return connections.containsKey(connectionKey);
  }

  // Close a specific connection
  Future<void> closeConnection(String ipAddress, [int port = 50000]) async {
    final connectionKey = '$ipAddress:$port';

    if (connections.containsKey(connectionKey)) {
      final connection = connections[connectionKey]!;
      await connection.dispose();
      connections.remove(connectionKey);
    }
  }

  // Close all connections
  Future<void> closeAllConnections() async {
    final futures =
        connections.values.map((connection) => connection.dispose());
    await Future.wait(futures);
    connections.clear();
  }

  // Dispose of the manager
  Future<void> dispose() async {
    await closeAllConnections();
    await connectionstatusController.close();
  }

  // Send a command to a router
  Future<bool> sendCommand(String ipAddress, String command,
      [int port = 50000]) async {
    final connectionKey = '$ipAddress:$port';

    if (!connections.containsKey(connectionKey)) {
      return false;
    }

    return await connections[connectionKey]!.sendCommand(command);
  }

  // Get connection stats
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
