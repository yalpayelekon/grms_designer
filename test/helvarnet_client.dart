import 'dart:convert';
import 'dart:io';

class HelvarNetClient {
  final String routerIP;
  final int tcpPort = 50000;
  final int udpPort = 50001;

  HelvarNetClient(this.routerIP);

  Future<List<String>> discoverWorkgroups() async {
    final workgroups = <String>[];
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

    socket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        final datagram = socket.receive();
        if (datagram != null) {
          final response = String.fromCharCodes(datagram.data);
          if (response.startsWith('?') && response.contains('=')) {
            final workgroupName = response.split('=')[1].replaceAll('#', '');
            workgroups.add(workgroupName);
          }
        }
      }
    });

    try {
      final command = '>V:2,C:107#';
      final commandBytes = utf8.encode(command);
      socket.send(commandBytes, InternetAddress(routerIP), udpPort);

      // Wait for responses
      await Future.delayed(const Duration(seconds: 1));
    } finally {
      socket.close();
    }

    return workgroups;
  }

  /// Discovers subnets on the router
  Future<List<int>> discoverSubnets() async {
    final subnets = <int>[];
    final response = await sendTcpCommand('>V:2,C:100,@#');

    if (response.startsWith('?') && response.contains('=')) {
      final data = response.split('=')[1].replaceAll('#', '');
      final subnetEntries = data.split(',');

      for (final entry in subnetEntries) {
        if (entry.contains('@')) {
          final parts = entry.split('@');
          if (parts.length >= 2 && parts[0] == '1') {
            final index = int.tryParse(parts[1]);
            if (index != null && index < 65000) {
              subnets.add(index);
            }
          }
        }
      }
    }

    return subnets;
  }

  /// Discovers all groups in the system
  Future<List<int>> discoverGroups() async {
    // Since we don't have a direct way to query all groups,
    // we'll check a range of potential group numbers based on your system
    final groups = <int>[];

    // Test from 201 to 300 - adjust range based on your system
    for (int i = 201; i <= 300; i++) {
      final response = await sendTcpCommand('>V:1,C:105,G:$i#');

      if (response.startsWith('?')) {
        groups.add(i);
      }
    }

    return groups;
  }

  /// Get group information
  Future<Map<String, dynamic>> getGroupInfo(int groupId) async {
    final result = <String, dynamic>{'id': groupId};

    // Get group description
    final descResponse = await sendTcpCommand('>V:1,C:105,G:$groupId#');
    if (descResponse.startsWith('?') && descResponse.contains('=')) {
      result['name'] = descResponse.split('=')[1].replaceAll('#', '');
    }

    // Get last scene
    final sceneResponse = await sendTcpCommand('>V:1,C:103,G:$groupId,B:1#');
    if (sceneResponse.startsWith('?') && sceneResponse.contains('=')) {
      final sceneStr = sceneResponse.split('=')[1].replaceAll('#', '');
      result['lastScene'] = int.tryParse(sceneStr) ?? 0;
    }

    // Get power consumption
    final powerResponse = await sendTcpCommand('>V:1,C:161,G:$groupId#');
    if (powerResponse.startsWith('?') && powerResponse.contains('=')) {
      final powerStr = powerResponse.split('=')[1].replaceAll('#', '');
      result['powerConsumption'] = double.tryParse(powerStr) ?? 0.0;
    }

    return result;
  }

  /// Control a group (recall scene)
  Future<bool> recallGroupScene(int groupId, int block, int scene,
      {int fadeTime = 0}) async {
    final command = '>V:1,C:11,G:$groupId,B:$block,S:$scene,F:$fadeTime#';
    final response = await sendTcpCommand(command);

    // No response means success for control commands
    return !response.startsWith('!');
  }

  /// Control a group (direct level)
  Future<bool> setGroupLevel(int groupId, int level, {int fadeTime = 0}) async {
    final command = '>V:1,C:13,G:$groupId,L:$level,F:$fadeTime#';
    final response = await sendTcpCommand(command);

    // No response means success for control commands
    return !response.startsWith('!');
  }

  /// Send a TCP command and get the response
  Future<String> sendTcpCommand(String command) async {
    try {
      final socket = await Socket.connect(routerIP, tcpPort);
      socket.write(command);

      final responseData = await socket.first
          .timeout(const Duration(milliseconds: 17), onTimeout: () {
        socket.destroy();
        return utf8.encode('TIMEOUT');
      });

      final response = String.fromCharCodes(responseData);
      socket.destroy();
      return response;
    } catch (e) {
      return 'ERROR: $e';
    }
  }
}
