import 'dart:io';
import 'dart:typed_data';
import 'package:grms_designer/protocol/query_commands.dart';
import 'package:grms_designer/utils/core/logger.dart';

import '../protocol/protocol_constants.dart';

class DiscoveryManager {
  RawDatagramSocket? _socket;
  final List<String> workgroupList = [];
  final List<String> ipList = [];
  bool isRunning = false;

  Future<void> start(String interfaceIp) async {
    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress(interfaceIp),
        defaultUdpPort,
      );
      isRunning = true;

      _socket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read && isRunning) {
          Datagram? datagram = _socket!.receive();
          if (datagram != null) {
            String response = String.fromCharCodes(datagram.data).trim();

            for (int i = 0; i < datagram.data.length; i++) {
              if (datagram.data[i] == 63) {
                String ip = datagram.address.address;
                workgroupList.add(response);
                ipList.add(ip);
                break;
              }
            }
          }
        }
      });
    } catch (e) {
      logError(
        'Error starting discovery: $e. Check Anydesk or other programs that might be using the port',
      );
      rethrow;
    }
  }

  Future<void> sendDiscoveryRequest(int timeout, String targetNetwork) async {
    if (_socket == null) {
      throw StateError('Socket not initialized. Call start() first.');
    }

    try {
      String command = HelvarNetCommands.queryWorkgroupName();
      List<int> commandBytes = List<int>.from(command.codeUnits);
      Uint8List data = Uint8List.fromList(commandBytes);

      _socket!.send(data, InternetAddress(targetNetwork), defaultUdpPort);

      await Future.delayed(Duration(milliseconds: timeout));
    } catch (e) {
      logError('Error sending discovery request: $e');
      rethrow;
    }
  }

  List<Map<String, String>> getDiscoveredRouters() {
    List<Map<String, String>> result = [];

    for (int i = 0; i < ipList.length; i++) {
      String workgroupName = "Unknown";
      if (i < workgroupList.length) {
        String response = workgroupList[i];
        if (response.contains('=')) {
          workgroupName = response.split('=')[1].replaceAll('#', '');
        }
      }
      result.add({'ip': ipList[i], 'workgroup': workgroupName});
    }

    return result;
  }

  void stop() {
    isRunning = false;
    if (_socket != null) {
      _socket!.close();
      _socket = null;
    }
  }
}
