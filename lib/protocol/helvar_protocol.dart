// protocol/helvar_protocol.dart
//
// A Dart library for communicating with Helvar lighting systems using the Helvar Protocol

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'protocol_constants.dart';

/// Function definition for response handlers
typedef ResponseHandler = bool Function(String response);

/// HelvarProtocol is the core class for interacting with Helvar lighting routers.
/// It handles the low-level communication and message formatting.
class HelvarProtocol {
  final String _host;
  final int _port;
  Socket? _socket;
  bool _connected = false;

  // Map of command IDs to response handlers
  final Map<String, List<ResponseHandler>> _responseHandlers = {};

  // Stream controller for general message events
  final StreamController<String> _messageStreamController =
      StreamController<String>.broadcast();

  /// Stream of all messages received from the router
  Stream<String> get messageStream => _messageStreamController.stream;

  /// Constructor
  ///
  /// [host] - The IP address or hostname of the Helvar router
  /// [port] - The port number (default: 50000)
  HelvarProtocol(this._host, {int port = kHelvarDefaultPort}) : _port = port;

  /// Connect to the Helvar router
  ///
  /// Returns true if connection was successful
  Future<bool> connect() async {
    try {
      _socket = await Socket.connect(_host, _port);
      _connected = true;

      _socket!.listen(
        (Uint8List data) {
          String response = String.fromCharCodes(data);
          handleResponse(response);
        },
        onError: (error) {
          print('Error: $error');
          _connected = false;
        },
        onDone: () {
          print('Server closed connection');
          _connected = false;
        },
      );

      return true;
    } catch (e) {
      print('Failed to connect: $e');
      _connected = false;
      return false;
    }
  }

  /// Handle incoming response messages
  void handleResponse(String response) {
    // Add to the general message stream
    _messageStreamController.add(response);

    if (response.startsWith('?')) {
      // Query response format: ?V:1,C:xxx,@x.x.x.x=value#
      handleQueryResponse(response);
    } else if (response.startsWith('!')) {
      // Error response format: !V:1,C:xxx,@x.x.x.x=error_code#
      handleErrorResponse(response);
    } else {
      print('Unknown response: $response');
    }
  }

  /// Handle query response messages
  void handleQueryResponse(String response) {
    // Extract the command number
    final commandMatch = RegExp(r'C:(\d+)').firstMatch(response);
    if (commandMatch != null) {
      final command = commandMatch.group(1);

      // If we have handlers registered for this command, call them
      if (command != null && _responseHandlers.containsKey(command)) {
        List<ResponseHandler> handlersToRemove = [];

        for (var handler in _responseHandlers[command]!) {
          // If handler returns true, it should be removed after processing
          if (handler(response)) {
            handlersToRemove.add(handler);
          }
        }

        // Remove handlers that are done
        if (handlersToRemove.isNotEmpty) {
          _responseHandlers[command]!
              .removeWhere((handler) => handlersToRemove.contains(handler));

          // If no handlers left for this command, remove the entry
          if (_responseHandlers[command]!.isEmpty) {
            _responseHandlers.remove(command);
          }
        }
      }
    }
  }

  /// Handle error response messages
  void handleErrorResponse(String response) {
    final parts = response.split('=');
    if (parts.length > 1) {
      final errorCode = int.tryParse(parts[1].replaceAll('#', ''));
      if (errorCode != null) {
        final errorMessage = ErrorCodes.getMessage(errorCode);
        print('Error: $errorMessage');
      }
    }

    // Extract the command number from the error response to notify handlers
    final commandMatch = RegExp(r'C:(\d+)').firstMatch(response);
    if (commandMatch != null) {
      final command = commandMatch.group(1);

      if (command != null && _responseHandlers.containsKey(command)) {
        // Notify command handlers of the error
        for (var handler in _responseHandlers[command]!) {
          handler(response);
        }

        // Remove all handlers for this command since it errored
        _responseHandlers.remove(command);
      }
    }
  }

  /// Disconnect from the Helvar router
  void disconnect() {
    if (_socket != null) {
      _socket!.close();
      _connected = false;
    }
  }

  /// Send a message to the Helvar router
  void sendMessage(String message) {
    if (_connected && _socket != null) {
      _socket!.write(message);
    } else {
      print('Not connected to Helvar router');
    }
  }

  /// Send a message with acknowledgment request
  void sendMessageWithAck(String message) {
    final parts = message.split('#');
    if (parts.isNotEmpty) {
      final ackMessage = '${parts[0]},A:1#';
      sendMessage(ackMessage);
    } else {
      sendMessage(message);
    }
  }

  /// Add a response handler for a specific command
  ///
  /// [command] - The command number to register the handler for
  /// [handler] - A function that processes the response and returns true if it should be removed
  void addResponseHandler(String command, ResponseHandler handler) {
    if (!_responseHandlers.containsKey(command)) {
      _responseHandlers[command] = [];
    }
    _responseHandlers[command]!.add(handler);
  }

  /// Discover Helvar routers on the network
  ///
  /// [port] - The port to broadcast on (default: 50001)
  Future<void> discoverRouters({int port = kHelvarDiscoveryPort}) async {
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final broadcastAddr = InternetAddress('255.255.255.255');

      const message = '>V:2,C:107#';
      socket.send(message.codeUnits, broadcastAddr, port);

      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            final response = String.fromCharCodes(datagram.data);
            if (response.startsWith('?V:2,C:107=')) {
              final workgroupName = response.split('=')[1].replaceAll('#', '');
              print(
                'Found Helvar router in workgroup: $workgroupName at ${datagram.address.address}',
              );

              // Broadcast the discovery via the message stream
              _messageStreamController.add(
                  'DISCOVERY: Router found in workgroup "$workgroupName" at ${datagram.address.address}');
            }
          }
        }
      });

      await Future.delayed(Duration(seconds: 5));
      socket.close();
    } catch (e) {
      print('Error during router discovery: $e');
    }
  }

  /// Check if a set of address parameters is valid
  bool validateClusterRouterSubnetDevice(
      int cluster, int router, int subnet, int device) {
    if (cluster < 1 || cluster > 253) {
      print('Error: Cluster must be between 1 and 253');
      return false;
    }
    if (router < 1 || router > 254) {
      print('Error: Router must be between 1 and 254');
      return false;
    }
    if (subnet < 1 || subnet > 4) {
      print('Error: Subnet must be between 1 and 4');
      return false;
    }
    if (device < 1 || device > 255) {
      print('Error: Device must be between 1 and 255');
      return false;
    }
    return true;
  }

  /// Check if connected to the router
  bool get isConnected => _connected;

  /// Get the router host address
  String get host => _host;

  /// Get the router port
  int get port => _port;
}
