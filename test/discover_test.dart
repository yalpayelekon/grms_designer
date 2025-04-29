import 'dart:convert';
import 'dart:io';

void main() async {
  // Router configuration
  final routerIP = '10.11.1.85'; // Your router's IP
  final tcpPort = 50000;

  print('HelvarNet Complete Discovery Test');
  print('===============================');

  try {
    // Step 1: Get subnet list
    print('\nStep 1: Get Subnet List');
    final subnets = await discoverSubnets(routerIP, tcpPort);

    if (subnets.isEmpty) {
      print('No subnets found');
      return;
    }

    print('Found ${subnets.length} subnets: $subnets');

    // Step 2: Discover devices on each subnet
    print('\nStep 2: Discover Devices');
    for (final subnet in subnets) {
      print('\nScanning subnet: $subnet');
      final devices = await discoverDevicesOnSubnet(routerIP, tcpPort, subnet);

      if (devices.isEmpty) {
        print('No devices found on subnet $subnet');
        continue;
      }

      print('Found ${devices.length} devices on subnet $subnet: $devices');

      // Step 3: Get device details
      print('\nStep 3: Get Device Details');
      for (final device in devices) {
        print('\nQuering device: $device');
        await getDeviceDetails(routerIP, tcpPort, device);
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}

Future<List<String>> discoverSubnets(String routerIP, int port) async {
  final subnets = <String>[];

  final response =
      await sendCommand(routerIP, port, '>V:2,C:100,@#', 'Query Subnets');

  if (response.startsWith('?') && response.contains('=')) {
    final data = response.split('=')[1].replaceAll('#', '');
    final subnetList = data.split(',');

    for (final subnet in subnetList) {
      if (subnet.contains('@')) {
        final parts = subnet.split('@');
        if (parts.length >= 2) {
          // Check if this is a real subnet (not the 65xxx reserved values)
          final index = int.tryParse(parts[1]);
          if (index != null && index < 65000) {
            subnets.add(parts[1]);
          }
        }
      }
    }
  }

  return subnets;
}

Future<List<String>> discoverDevicesOnSubnet(
    String routerIP, int port, String subnet) async {
  final devices = <String>[];

  final response = await sendCommand(routerIP, port, '>V:2,C:100,@1.$subnet#',
      'Query Devices on Subnet $subnet');

  if (response.startsWith('?') && response.contains('=')) {
    final data = response.split('=')[1].replaceAll('#', '');
    final deviceList = data.split(',');

    for (final device in deviceList) {
      if (device.contains('@')) {
        final parts = device.split('@');
        if (parts.length >= 2) {
          devices.add('1.$subnet.${parts[1]}');
        }
      }
    }
  }

  return devices;
}

Future<void> getDeviceDetails(
    String routerIP, int port, String deviceAddress) async {
  // Get device type
  final typeResponse = await sendCommand(
      routerIP, port, '>V:1,C:104,@$deviceAddress#', 'Query Device Type');
  print('Type response: $typeResponse');

  // Get device description
  final descResponse = await sendCommand(routerIP, port,
      '>V:1,C:106,@$deviceAddress#', 'Query Device Description');
  print('Description response: $descResponse');

  // If it's a load, query load level
  final levelResponse = await sendCommand(
      routerIP, port, '>V:1,C:152,@$deviceAddress#', 'Query Load Level');
  print('Level response: $levelResponse');
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
    18: 'Incompatible version'
  };

  return errorMessages[code] ?? 'Unknown error';
}
