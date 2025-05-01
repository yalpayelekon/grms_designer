import 'dart:io';
import 'dart:typed_data';
import 'package:grms_designer/protocol/query_commands.dart';

import '../protocol/protocol_constants.dart';
import '../screens/network_interface_dialog.dart';

class DiscoveryManager {
  RawDatagramSocket? _socket;
  final List<String> workgroupList = [];
  final List<String> ipList = [];
  bool isRunning = false;

  Future<void> start(String interfaceIp) async {
    try {
      _socket = await RawDatagramSocket.bind(
          InternetAddress(interfaceIp), defaultUdpPort);
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
      print('Error starting discovery: $e');
      rethrow;
    }
  }

  Future<void> sendDiscoveryRequest(int timeout, String targetNetwork) async {
    if (_socket == null) {
      throw StateError('Socket not initialized. Call start() first.');
    }

    try {
      String command = HelvarNetCommands.queryWorkgroupName(2);
      List<int> commandBytes = List<int>.from(command.codeUnits);
      Uint8List data = Uint8List.fromList(commandBytes);

      _socket!.send(data, InternetAddress(targetNetwork), 50001);

      await Future.delayed(Duration(milliseconds: timeout));
    } catch (e) {
      print('Error sending discovery request: $e');
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

  Future<List<NetworkInterfaceDetails>> getNetworkInterfaces() async {
    final result = await Process.run('ipconfig', ['/all']);
    final output = result.stdout.toString();
    final interfaces = parseIpConfig(output);

    final filteredInterfaces = interfaces.where((interface) {
      return interface.ipv4 != null &&
          interface.subnetMask !=
              null; // You can also check gateway if you want
    }).toList();

    if (filteredInterfaces.isEmpty) {
      print('No valid interfaces found.');
      print('Raw ipconfig output:\n$output');
      return [];
    } else {
      return filteredInterfaces;
    }
  }

  String calculateBroadcastAddress(String ipAddress, String subnetMask) {
    List<String> ipParts = ipAddress.split('.');
    List<String> maskParts = subnetMask.split('.');

    List<String> broadcastParts = [];

    for (int i = 0; i < 4; i++) {
      int ip = int.parse(ipParts[i]);
      int mask = int.parse(maskParts[i]);
      int broadcast = ip | (~mask & 0xFF);
      broadcastParts.add(broadcast.toString());
    }

    return broadcastParts.join('.');
  }

  List<NetworkInterfaceDetails> parseIpConfig(String output) {
    final interfaces = <NetworkInterfaceDetails>[];
    final lines = output.split('\n');
    NetworkInterfaceDetails? currentInterface;

    for (final line in lines) {
      final trimmedLine = line.trim();

      if (trimmedLine.contains('adapter') && trimmedLine.endsWith(':')) {
        if (currentInterface != null &&
            (currentInterface.ipv4 != null ||
                currentInterface.subnetMask != null ||
                currentInterface.gateway != null)) {
          interfaces.add(currentInterface);
        }
        final name =
            trimmedLine.replaceAll('adapter', '').replaceAll(':', '').trim();
        currentInterface = NetworkInterfaceDetails(name: name);
      } else if (currentInterface != null) {
        if (trimmedLine.startsWith('IPv4 Address') ||
            trimmedLine.startsWith('IPv4-adres')) {
          currentInterface.ipv4 = _cleanValue(_extractAfterColon(trimmedLine));
        } else if (trimmedLine.startsWith('Subnet Mask') ||
            trimmedLine.startsWith('Subnetmasker')) {
          currentInterface.subnetMask =
              _cleanValue(_extractAfterColon(trimmedLine));
        } else if (trimmedLine.startsWith('Default Gateway') ||
            trimmedLine.startsWith('Standaardgateway')) {
          currentInterface.gateway =
              _cleanValue(_extractAfterColon(trimmedLine));
        }
      }
    }

    if (currentInterface != null &&
        (currentInterface.ipv4 != null ||
            currentInterface.subnetMask != null ||
            currentInterface.gateway != null)) {
      interfaces.add(currentInterface);
    }

    return interfaces;
  }

  String _extractAfterColon(String line) {
    final parts = line.split(':');
    if (parts.length < 2) return '';
    return parts.sublist(1).join(':').trim();
  }

  String _cleanValue(String value) {
    return value.replaceAll(RegExp(r'\(.*\)'), '').trim();
  }

  void stop() {
    isRunning = false;
    if (_socket != null) {
      _socket!.close();
      _socket = null;
    }
  }
}
