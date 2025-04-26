import 'dart:io';
import 'dart:typed_data';
import '../protocol/commands/discovery_commands.dart';

class DiscoveryManager {
  late RawDatagramSocket socket;
  String targetNetwork;
  final List<String> workgroupList = [];
  final List<String> ipList = [];
  bool isRunning = false;

  DiscoveryManager(this.targetNetwork);

  Future<void> start() async {
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 50001);
      isRunning = true;

      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read && isRunning) {
          Datagram? datagram = socket.receive();
          if (datagram != null) {
            String response = String.fromCharCodes(datagram.data).trim();

            // Check for Helvar protocol marker (63 = '?')
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

  Future<void> sendDiscoveryRequest(int timeout) async {
    try {
      String command = DiscoveryCommands.queryWorkgroupName();

      List<int> commandBytes = command.codeUnits;
      commandBytes.addAll([0, 0, 0, 0]);

      Uint8List data = Uint8List.fromList(commandBytes);

      socket.send(data, InternetAddress(targetNetwork), 50001);

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

  void stop() {
    isRunning = false;
    socket.close();
  }

  static Future<List<NetworkInterface>> getNetworkInterfaces() async {
    try {
      List<NetworkInterface> interfaces = await NetworkInterface.list(
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );
      return interfaces.where((iface) => !iface.name.contains('lo')).toList();
    } catch (e) {
      print('Error getting network interfaces: $e');
      return [];
    }
  }

  static String getBroadcastAddress(String ipAddress, String subnetMask) {
    try {
      List<int> ipParts = ipAddress.split('.').map(int.parse).toList();
      List<int> maskParts = subnetMask.split('.').map(int.parse).toList();
      List<int> broadcastParts = [];

      for (int i = 0; i < 4; i++) {
        int broadcastPart = ipParts[i] | (~maskParts[i] & 0xFF);
        broadcastParts.add(broadcastPart);
      }

      return broadcastParts.join('.');
    } catch (e) {
      return '255.255.255.255';
    }
  }
}
