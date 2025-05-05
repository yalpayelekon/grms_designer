import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'models/router_connection_status.dart';
import '../protocol/protocol_constants.dart';

class RouterConnection {
  final String ipAddress;
  final String routerId;
  final int port;
  final Duration heartbeatInterval;
  final Duration connectionTimeout;

  Socket? _socket;
  StreamSubscription? _dataSubscription;
  StreamSubscription? _errorSubscription;
  StreamSubscription? _doneSubscription;
  StreamController<Uint8List> _incomingDataController =
      StreamController<Uint8List>.broadcast();
  StreamController<RouterConnectionStatus> _statusController =
      StreamController<RouterConnectionStatus>.broadcast();
  Timer? _heartbeatTimer;
  DateTime _lastActivity = DateTime.now();
  int _reconnectAttempts = 0;
  bool _isClosing = false;

  RouterConnectionStatus _status;

  RouterConnection({
    required this.ipAddress,
    required this.routerId,
    this.port = defaultTcpPort,
    this.heartbeatInterval = const Duration(seconds: 30),
    this.connectionTimeout = const Duration(seconds: 5),
  }) : _status = RouterConnectionStatus(
          routerIp: ipAddress,
          routerId: routerId,
          state: RouterConnectionState.disconnected,
          lastStateChange: DateTime.now(),
        );

  bool get isConnected =>
      _socket != null && _status.state == RouterConnectionState.connected;
  RouterConnectionStatus get status => _status;
  Stream<Uint8List> get dataStream => _incomingDataController.stream;
  Stream<RouterConnectionStatus> get statusStream => _statusController.stream;

  Future<void> connect() async {
    if (_isClosing) return;

    if (_socket != null) {
      await disconnect();
    }

    _updateStatus(RouterConnectionState.connecting);

    try {
      _socket =
          await Socket.connect(ipAddress, port, timeout: connectionTimeout);

      _dataSubscription = _socket!.listen(
        _handleData,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      _updateStatus(RouterConnectionState.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();
    } catch (e) {
      _updateStatus(RouterConnectionState.failed, errorMessage: e.toString());
      _scheduleReconnect();
    }
  }

  Future<void> disconnect() async {
    _stopHeartbeat();

    await _dataSubscription?.cancel();
    _dataSubscription = null;

    if (_socket != null) {
      try {
        await _socket!.close();
      } catch (e) {
        debugPrint('Error closing socket: $e');
      }
      _socket = null;
    }

    _updateStatus(RouterConnectionState.disconnected);
  }

  Future<bool> sendCommand(String command) async {
    if (!isConnected) {
      return false;
    }

    try {
      _socket!.write(command);
      _lastActivity = DateTime.now();
      return true;
    } catch (e) {
      debugPrint('Error sending command: $e');
      _handleError(e);
      return false;
    }
  }

  Future<bool> sendBytes(List<int> data) async {
    if (!isConnected) {
      return false;
    }

    try {
      _socket!.add(data);
      _lastActivity = DateTime.now();
      return true;
    } catch (e) {
      debugPrint('Error sending data: $e');
      _handleError(e);
      return false;
    }
  }

  Future<void> dispose() async {
    _isClosing = true;
    await disconnect();

    await _statusController.close();
    await _incomingDataController.close();
  }

  void _handleData(Uint8List data) {
    _lastActivity = DateTime.now();
    _incomingDataController.add(data);
  }

  void _handleError(dynamic error) {
    debugPrint('Socket error for router $ipAddress: $error');
    _updateStatus(RouterConnectionState.failed, errorMessage: error.toString());
    _scheduleReconnect();
  }

  void _handleDisconnect() {
    if (_isClosing) return;

    debugPrint('Disconnected from router $ipAddress');
    _socket = null;
    _updateStatus(RouterConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _updateStatus(RouterConnectionState state, {String? errorMessage}) {
    _status = _status.copyWith(
      state: state,
      errorMessage: errorMessage,
      reconnectAttempts: _reconnectAttempts,
    );

    _statusController.add(_status);
  }

  void _scheduleReconnect() {
    if (_isClosing) return;

    _stopHeartbeat();
    _reconnectAttempts++;

    // Calculate backoff time (exponential with a cap)
    int backoffSeconds = _reconnectAttempts < 10
        ? (1 << _reconnectAttempts) // 2^n seconds (2, 4, 8, 16...)
        : 300; // Cap at 5 minutes

    backoffSeconds = backoffSeconds.clamp(1, 300);

    debugPrint(
        'Scheduling reconnect to $ipAddress in $backoffSeconds seconds (attempt $_reconnectAttempts)');
    _updateStatus(RouterConnectionState.reconnecting);

    Future.delayed(Duration(seconds: backoffSeconds), () {
      if (_isClosing) return;
      connect();
    });
  }

  void _startHeartbeat() {
    _stopHeartbeat();

    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      _sendHeartbeat();
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _sendHeartbeat() {
    if (!isConnected) return;

    final now = DateTime.now();
    if (now.difference(_lastActivity) < heartbeatInterval) {
      return;
    }

    // Send a heartbeat command that won't affect router state
    // Using the query version command as it's lightweight
    sendCommand('>V:2,C:191#');
  }
}
