// lib/comm/router_socket_handler.dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../protocol/protocol_constants.dart';
import '../protocol/query_commands.dart';
import '../utils/logger.dart';

enum SocketStatus { disconnected, connecting, connected, reconnecting, failed }

class RouterSocketHandler {
  final String ipAddress;
  final int port;
  final Duration timeout;
  final Duration heartbeatInterval;

  Socket? _socket;
  StreamSubscription? _subscription;
  final _messageStream = StreamController<String>.broadcast();
  final _statusStream = StreamController<SocketStatus>.broadcast();

  Timer? _heartbeatTimer;
  DateTime _lastActivity = DateTime.now();
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  final _buffer = StringBuffer();

  RouterSocketHandler({
    required this.ipAddress,
    this.port = defaultTcpPort,
    this.timeout = const Duration(seconds: 5),
    this.heartbeatInterval = const Duration(seconds: 30),
  });

  Stream<String> get messageStream => _messageStream.stream;
  Stream<SocketStatus> get statusStream => _statusStream.stream;

  Future<void> connect() async {
    if (_socket != null) await disconnect();
    _setStatus(SocketStatus.connecting);

    try {
      _socket = await Socket.connect(ipAddress, port, timeout: timeout);
      _subscription = _socket!.listen(
        _handleData,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      _reconnectAttempts = 0;
      _startHeartbeat();
      _setStatus(SocketStatus.connected);
    } catch (e) {
      logError('Connection error: $e');
      _setStatus(SocketStatus.failed);
      _scheduleReconnect();
    }
  }

  Future<void> disconnect() async {
    _stopHeartbeat();
    await _subscription?.cancel();
    await _socket?.close();
    _socket = null;
    _setStatus(SocketStatus.disconnected);
  }

  Future<bool> send(String text) async {
    if (_socket == null) return false;
    try {
      _socket!.write(text);
      _lastActivity = DateTime.now();
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  void _handleData(Uint8List data) {
    _lastActivity = DateTime.now();
    final msg = String.fromCharCodes(data);
    _buffer.write(msg);
    _flushBuffer();
  }

  void _flushBuffer() {
    final buffer = _buffer.toString();
    final endIdx = buffer.indexOf(MessageType.terminator);
    if (endIdx != -1) {
      final complete = buffer.substring(0, endIdx + 1);
      _messageStream.add(complete);
      _buffer.clear();
      if (endIdx + 1 < buffer.length) {
        _buffer.write(buffer.substring(endIdx + 1));
        _flushBuffer(); // Recursive for multiple terminators
      }
    }
  }

  void _handleError(dynamic e) {
    logError('Socket error for $ipAddress: $e');
    _setStatus(SocketStatus.failed);
    _scheduleReconnect();
  }

  void _handleDisconnect() {
    logInfo('Socket closed from $ipAddress');
    _setStatus(SocketStatus.disconnected);
    _scheduleReconnect();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      final diff = DateTime.now().difference(_lastActivity);
      if (diff >= heartbeatInterval) {
        send(HelvarNetCommands.queryHelvarNetVersion());
      }
    });
  }

  void _stopHeartbeat() => _heartbeatTimer?.cancel();

  void _scheduleReconnect() {
    if (_isReconnecting) return;
    _isReconnecting = true;
    _reconnectAttempts++;
    final backoff = Duration(seconds: (1 << _reconnectAttempts).clamp(1, 300));
    _setStatus(SocketStatus.reconnecting);

    Future.delayed(backoff, () {
      _isReconnecting = false;
      connect();
    });
  }

  void _setStatus(SocketStatus status) {
    _statusStream.add(status);
  }

  Future<void> dispose() async {
    await disconnect();
    await _messageStream.close();
    await _statusStream.close();
  }
}
