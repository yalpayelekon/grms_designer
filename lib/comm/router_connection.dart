import 'dart:async';
import 'models/router_connection_status.dart';
import '../protocol/protocol_constants.dart';
import 'router_socket_handler.dart';

class RouterConnection {
  final String ipAddress;
  final int port;
  final Duration heartbeatInterval;
  final Duration connectionTimeout;

  final RouterSocketHandler _socketHandler;
  RouterConnectionStatus _status;
  int _reconnectAttempts = 0;
  bool _isClosing = false;

  RouterConnection({
    required this.ipAddress,
    this.port = defaultTcpPort,
    this.heartbeatInterval = const Duration(seconds: 30),
    this.connectionTimeout = const Duration(seconds: 5),
  })  : _status = RouterConnectionStatus(
          routerIp: ipAddress,
          state: RouterConnectionState.disconnected,
          lastStateChange: DateTime.now(),
        ),
        _socketHandler = RouterSocketHandler(
          ipAddress: ipAddress,
          port: port,
          heartbeatInterval: heartbeatInterval,
          timeout: connectionTimeout,
        ) {
    _socketHandler.statusStream.listen(_onSocketStatusChange);
  }

  bool get isConnected => _status.state == RouterConnectionState.connected;

  RouterConnectionStatus get status => _status;

  Stream<String> get messageStream => _socketHandler.messageStream;

  Stream<RouterConnectionStatus> get statusStream => _statusController.stream;

  final _statusController =
      StreamController<RouterConnectionStatus>.broadcast();

  Future<void> connect() async {
    await _socketHandler.connect();
  }

  Future<void> disconnect() async {
    await _socketHandler.disconnect();
  }

  Future<bool> sendFireAndForget(String text) async {
    return _socketHandler.send(text);
  }

  Future<void> dispose() async {
    _isClosing = true;
    await _socketHandler.dispose();
    await _statusController.close();
  }

  void _onSocketStatusChange(SocketStatus status) {
    if (_isClosing) return;

    switch (status) {
      case SocketStatus.connected:
        _reconnectAttempts = 0;
        _updateStatus(RouterConnectionState.connected);
        break;
      case SocketStatus.connecting:
        _updateStatus(RouterConnectionState.connecting);
        break;
      case SocketStatus.reconnecting:
        _reconnectAttempts++;
        _updateStatus(RouterConnectionState.reconnecting);
        break;
      case SocketStatus.failed:
        _updateStatus(RouterConnectionState.failed,
            errorMessage: 'Socket connection failed');
        break;
      case SocketStatus.disconnected:
        _updateStatus(RouterConnectionState.disconnected);
        break;
    }
  }

  void _updateStatus(RouterConnectionState state, {String? errorMessage}) {
    _status = _status.copyWith(
      state: state,
      errorMessage: errorMessage,
      reconnectAttempts: _reconnectAttempts,
    );
    _statusController.add(_status);
  }
}
