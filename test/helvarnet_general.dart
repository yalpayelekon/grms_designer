import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

void main() async {
  // Router configuration
  final routerIP = '10.11.1.85'; // Replace with your router's IP
  final tcpPort = 50000;
  final udpPort = 50001;

  print('HelvarNet Discovery Protocol Tester');
  print('==================================');

  try {
    // Test direct TCP commands for discovery
    print('\n[1] Testing TCP Discovery Commands:');
    await testTcpCommand(
        routerIP, tcpPort, '>V:2,C:107#', 'Query Workgroup Name');
    await testTcpCommand(
        routerIP, tcpPort, '>V:2,C:108#', 'Query Workgroup Membership');
    await testTcpCommand(routerIP, tcpPort, '>V:2,C:165#', 'Query Groups');
    await testTcpCommand(
        routerIP, tcpPort, '>V:2,C:164,G:1#', 'Query Group 1 Members');
    await testTcpCommand(routerIP, tcpPort, '>V:2,C:166#', 'Query Scene Names');

    // Test TCP discovery path - version query → clusters → routers → devices
    print('\n[2] Testing Basic Configuration Commands:');
    await testTcpCommand(
        routerIP, tcpPort, '>V:1,C:190#', 'Query Software Version');
    await testTcpCommand(
        routerIP, tcpPort, '>V:1,C:191#', 'Query HelvarNet Version');
    await testTcpCommand(routerIP, tcpPort, '>V:1,C:185#', 'Query Time');

    // Test subnet and device specific commands
    print(
        '\n[3] Testing Device Queries (change subnet/device values as needed):');
    await testTcpCommand(
        routerIP, tcpPort, '>V:1,C:104,@1.1.1.1#', 'Query Device Type');
    await testTcpCommand(
        routerIP, tcpPort, '>V:1,C:106,@1.1.1.1#', 'Query Device Description');
    await testTcpCommand(
        routerIP, tcpPort, '>V:1,C:152,@1.1.1.1#', 'Query Load Level');

    // Test UDP broadcast discovery (modify for direct communications)
    print('\n[4] Testing UDP Discovery Commands:');
    await testUdpCommand(routerIP, udpPort, '>V:2,C:107#',
        'Query Workgroup Name', 500); // Short timeout
    await testUdpCommand(routerIP, udpPort, '>V:2,C:107#',
        'Query Workgroup Name (without null bytes)', 500, false);

    print('\n[5] Testing UDP Broadcast Discovery:');
    final broadcastResult = await testUdpBroadcast(
        udpPort, '>V:2,C:107#', 'Query Workgroup Name Broadcast');
    if (broadcastResult.isEmpty) {
      print('No responses received from broadcast');
    }
  } catch (e) {
    print('Error: $e');
  }
}

Future<void> testTcpCommand(
    String ip, int port, String command, String description) async {
  print('\nTesting: $description');
  print('Command: $command');

  try {
    final socket = await Socket.connect(ip, port);

    // Set a timeout for receiving response
    socket.timeout(const Duration(seconds: 5));

    // Send command
    socket.write(command);
    print('Command sent, waiting for response...');

    // Wait for response
    final response =
        await socket.first.timeout(const Duration(seconds: 5), onTimeout: () {
      socket.destroy();
      return utf8.encode('TIMEOUT');
    });

    final responseStr = utf8.decode(response);
    print('Response: $responseStr');
    print(
        'Response bytes: ${response.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');

    // Parse the response if it's an error
    if (responseStr.startsWith('!')) {
      final errorCode = responseStr.split('=')[1].replaceAll('#', '');
      final errorMessage = getErrorMessage(int.parse(errorCode));
      print('Error Code: $errorCode - $errorMessage');
    }

    socket.destroy();
  } catch (e) {
    print('Communication error: $e');
  }
}

Future<void> testUdpCommand(
    String ip, int port, String command, String description,
    [int timeoutMs = 5000, bool addNullBytes = true]) async {
  print('\nTesting: $description');
  print('Command: $command');

  try {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);

    // Set socket to listen for responses
    final responses = <String>[];

    socket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        final datagram = socket.receive();
        if (datagram != null) {
          final response = utf8.decode(datagram.data);
          responses.add('From ${datagram.address.address}: $response');
          print(
              'Received response from ${datagram.address.address}: $response');
          print(
              'Response bytes: ${datagram.data.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
        }
      }
    });

    // Send command
    List<int> data;
    if (addNullBytes) {
      // Add null bytes as your original implementation did
      List<int> commandBytes = List<int>.from(command.codeUnits);
      commandBytes.addAll([0, 0, 0, 0]);
      data = Uint8List.fromList(commandBytes);
    } else {
      data = utf8.encode(command);
    }

    print('Sending UDP packet to $ip:$port...');
    print(
        'Packet bytes: ${data.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(' ')}');
    socket.send(data, InternetAddress(ip), port);

    // Wait for response with timeout
    await Future.delayed(Duration(milliseconds: timeoutMs));

    if (responses.isEmpty) {
      print('No response received within timeout period');
    } else {
      for (var response in responses) {
        print('Response: $response');
      }
    }

    socket.close();
  } catch (e) {
    print('Communication error: $e');
  }
}

Future<List<String>> testUdpBroadcast(
    int port, String command, String description) async {
  print('\nTesting: $description');
  print('Command: $command');

  final responses = <String>[];

  try {
    // Find all network interfaces
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      includeLinkLocal: false,
      type: InternetAddressType.IPv4,
    );

    print('Found ${interfaces.length} network interfaces');

    for (var interface in interfaces) {
      print('Interface: ${interface.name}');

      for (var addr in interface.addresses) {
        // Calculate broadcast address (for simplicity using 255.255.255.255)
        final broadcastAddress = InternetAddress('255.255.255.255');

        print(
            'Sending broadcast from ${addr.address} to ${broadcastAddress.address}:$port');

        // Create a socket with broadcast permission
        final socket = await RawDatagramSocket.bind(addr, 0);
        socket.broadcastEnabled = true;

        socket.listen((RawSocketEvent event) {
          if (event == RawSocketEvent.read) {
            final datagram = socket.receive();
            if (datagram != null) {
              final response = utf8.decode(datagram.data);
              final entry = 'From ${datagram.address.address}: $response';
              if (!responses.contains(entry)) {
                responses.add(entry);
                print('Received response: $entry');
              }
            }
          }
        });

        // Send command
        List<int> commandBytes = List<int>.from(command.codeUnits);
        Uint8List data = Uint8List.fromList(commandBytes);
        socket.send(data, broadcastAddress, port);

        // Wait some time for responses
        await Future.delayed(Duration(milliseconds: 1000));
      }
    }

    // Additional wait for any late responses
    await Future.delayed(Duration(milliseconds: 500));

    if (responses.isEmpty) {
      print('No responses received from broadcast');
    }

    return responses;
  } catch (e) {
    print('Broadcast error: $e');
    return [];
  }
}

String getErrorMessage(int code) {
  switch (code) {
    case 0:
      return 'Success';
    case 1:
      return 'Invalid group index parameter';
    case 2:
      return 'Invalid cluster parameter';
    case 3:
      return 'Invalid router parameter';
    case 4:
      return 'Invalid subnet parameter';
    case 5:
      return 'Invalid device parameter';
    case 6:
      return 'Invalid sub device parameter';
    case 7:
      return 'Invalid block parameter';
    case 8:
      return 'Invalid scene parameter';
    case 9:
      return 'Cluster does not exist';
    case 10:
      return 'Router does not exist';
    case 11:
      return 'Device does not exist';
    case 12:
      return 'Property does not exist';
    case 13:
      return 'Invalid RAW message size';
    case 14:
      return 'Invalid messages type';
    case 15:
      return 'Invalid message command';
    case 16:
      return 'Missing ASCII terminator';
    case 17:
      return 'Missing ASCII parameter';
    case 18:
      return 'Incompatible version';
    default:
      return 'Unknown error';
  }
}
