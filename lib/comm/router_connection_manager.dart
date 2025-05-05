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
  final Map<String, RouterConnection> _connections = {};

  // Status stream controller
  final _connectionStatusController =
      StreamController<RouterConnectionStatus>.broadcast();

  // Configuration
  int _maxConcurrentConnections = 1000; // Default limit, can be changed

  // Public getters
  Stream<RouterConnectionStatus> get connectionStatusStream =>
      _connectionStatusController.stream;

  int get connectionCount => _connections.length;
  int get maxConnections => _maxConcurrentConnections;

  List<RouterConnectionStatus> get allConnectionStatuses =>
      _connections.values.map((conn) => conn.status).toList();

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
    if (_connections.containsKey(connectionKey) && !forceReconnect) {
      final connection = _connections[connectionKey]!;

      // If disconnected, try to reconnect
      if (!connection.isConnected) {
        await connection.connect();
      }

      return connection;
    }

    // Check if we've hit connection limit
    if (_connections.length >= _maxConcurrentConnections) {
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
      _connectionStatusController.add(status);
    });

    // Store and connect
    _connections[connectionKey] = connection;
    await connection.connect();

    return connection;
  }

  // Check if we have a connection to a router
  bool hasConnection(String ipAddress, [int port = 50000]) {
    final connectionKey = '$ipAddress:$port';
    return _connections.containsKey(connectionKey);
  }

  // Close a specific connection
  Future<void> closeConnection(String ipAddress, [int port = 50000]) async {
    final connectionKey = '$ipAddress:$port';

    if (_connections.containsKey(connectionKey)) {
      final connection = _connections[connectionKey]!;
      await connection.dispose();
      _connections.remove(connectionKey);
    }
  }

  // Close all connections
  Future<void> closeAllConnections() async {
    final futures =
        _connections.values.map((connection) => connection.dispose());
    await Future.wait(futures);
    _connections.clear();
  }

  // Dispose of the manager
  Future<void> dispose() async {
    await closeAllConnections();
    await _connectionStatusController.close();
  }

  // Send a command to a router
  Future<bool> sendCommand(String ipAddress, String command,
      [int port = 50000]) async {
    final connectionKey = '$ipAddress:$port';

    if (!_connections.containsKey(connectionKey)) {
      return false;
    }

    return await _connections[connectionKey]!.sendCommand(command);
  }

  // Get connection stats
  Map<String, dynamic> getConnectionStats() {
    int connected = 0;
    int connecting = 0;
    int reconnecting = 0;
    int failed = 0;
    int disconnected = 0;

    for (var connection in _connections.values) {
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
      'total': _connections.length,
      'connected': connected,
      'connecting': connecting,
      'reconnecting': reconnecting,
      'failed': failed,
      'disconnected': disconnected,
    };
  }
}
