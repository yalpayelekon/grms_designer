enum RouterConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed
}

class RouterConnectionStatus {
  final String routerIp;
  final RouterConnectionState state;
  final DateTime lastStateChange;
  final String? errorMessage;
  final int reconnectAttempts;

  RouterConnectionStatus({
    required this.routerIp,
    required this.state,
    required this.lastStateChange,
    this.errorMessage,
    this.reconnectAttempts = 0,
  });

  RouterConnectionStatus copyWith({
    RouterConnectionState? state,
    String? errorMessage,
    int? reconnectAttempts,
  }) {
    return RouterConnectionStatus(
      routerIp: routerIp,
      state: state ?? this.state,
      lastStateChange: DateTime.now(),
      errorMessage: errorMessage ?? this.errorMessage,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
    );
  }
}
