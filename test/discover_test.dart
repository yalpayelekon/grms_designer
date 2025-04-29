import 'dart:convert';
import 'dart:io';

void main() async {
  // Router configuration
  final routerIP = '10.11.1.85'; // Your router's IP
  final tcpPort = 50000;

  print('HelvarNet Final Discovery Test');
  print('============================');

  try {
    // Step 1: Query fundamental information to understand the structure
    print('\nStep 1: Basic System Information');

    // Query software version
    await sendCommand(
        routerIP, tcpPort, '>V:1,C:190#', 'Query Software Version');

    // Query protocol version
    await sendCommand(
        routerIP, tcpPort, '>V:1,C:191#', 'Query HelvarNet Version');

    // Step 2: Try to discover subnets
    print('\nStep 2: Subnet Discovery Methods');

    // Standard subnet query that works
    await sendCommand(routerIP, tcpPort, '>V:2,C:100,@#', 'Query All Subnets');

    // Try with different cluster values (0-3) since we keep getting "cluster doesn't exist"
    for (int cluster = 0; cluster <= 3; cluster++) {
      await sendCommand(routerIP, tcpPort, '>V:2,C:100,@$cluster#',
          'Query Subnets in Cluster $cluster');
    }

    // Step 3: Group discovery works, let's explore that
    print('\nStep 3: Group Discovery');

    // Query multiple groups
    for (int group = 201; group <= 211; group++) {
      await sendCommand(routerIP, tcpPort, '>V:1,C:105,G:$group#',
          'Query Group $group Description');
    }

    // Step 4: Try device discovery through groups
    print('\nStep 4: Device Discovery Through Groups');

    // For each group, query the last scene
    for (int group = 201; group <= 211; group++) {
      // Query last scene in block for this group
      await sendCommand(routerIP, tcpPort, '>V:1,C:103,G:$group,B:1#',
          'Query Last Scene in Block 1 for Group $group');

      // Try to query group load level
      await sendCommand(routerIP, tcpPort, '>V:1,C:161,G:$group#',
          'Query Group $group Power Consumption');
    }

    // Step 5: Try different addressing formats for subnets
    print('\nStep 5: Alternative Subnet Addressing');

    // Try subnet 1 with different syntax (based on cluster ID from Designer: 10.11.1.0)
    final clusterValue = "10.11.1.0";
    await sendCommand(routerIP, tcpPort, '>V:2,C:100,@$clusterValue.1#',
        'Query Devices in Subnet 1 (with Cluster)');

    // Try using router ID value from the Designer image (202596)
    await sendCommand(routerIP, tcpPort, '>V:2,C:100,@202596.1#',
        'Query Devices in Subnet 1 (with Router ID)');
  } catch (e) {
    print('Error: $e');
  }
}

Future<String> sendCommand(
    String ip, int port, String command, String description) async {
  print('\nSending: $description');
  print('Command: $command');

  try {
    final socket = await Socket.connect(ip, port);

    // Set a timeout for receiving response
    socket.timeout(const Duration(seconds: 3));

    // Send command
    socket.write(command);

    // Wait for response
    final response =
        await socket.first.timeout(const Duration(seconds: 3), onTimeout: () {
      socket.destroy();
      return utf8.encode('TIMEOUT');
    });

    final responseStr = utf8.decode(response);
    print('Response: $responseStr');

    // Parse the response if it's an error
    if (responseStr.startsWith('!')) {
      final parts = responseStr.split('=');
      if (parts.length >= 2) {
        final errorCode = parts[1].replaceAll('#', '');
        final errorMessage = getErrorMessage(int.tryParse(errorCode) ?? -1);
        print('Error Code: $errorCode - $errorMessage');
      }
    }

    socket.destroy();
    return responseStr;
  } catch (e) {
    print('Communication error: $e');
    return 'ERROR: $e';
  }
}

String getErrorMessage(int code) {
  final errorMessages = {
    0: 'Success',
    1: 'Invalid group index parameter',
    2: 'Invalid cluster parameter',
    3: 'Invalid router parameter',
    4: 'Invalid subnet parameter',
    5: 'Invalid device parameter',
    6: 'Invalid sub device parameter',
    7: 'Invalid block parameter',
    8: 'Invalid scene parameter',
    9: 'Cluster does not exist',
    10: 'Router does not exist',
    11: 'Device does not exist',
    12: 'Property does not exist',
    13: 'Invalid RAW message size',
    14: 'Invalid messages type',
    15: 'Invalid message command',
    16: 'Missing ASCII terminator',
    17: 'Missing ASCII parameter',
    18: 'Incompatible version',
    27: 'Invalid colour parameter'
  };

  return errorMessages[code] ?? 'Unknown error';
}
