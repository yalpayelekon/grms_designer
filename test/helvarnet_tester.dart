import 'dart:convert';
import 'dart:io';

class HelvarRouter {
  final String ipAddress;
  final int clusterId;
  final int clusterMemberId;
  final String routerAddress;
  String? description;
  String? deviceType;
  String? deviceState;
  List<String>? deviceAddresses;
  final Map<int, List<HelvarDevice>> devicesBySubnet = {};

  HelvarRouter({
    required this.ipAddress,
    required this.clusterId,
    required this.clusterMemberId,
  }) : routerAddress = '$clusterId.$clusterMemberId';

  Map<String, dynamic> toJson() {
    final devicesJson = <String, List<Map<String, dynamic>>>{};
    devicesBySubnet.forEach((subnet, devices) {
      devicesJson['subnet$subnet'] = devices.map((d) => d.toJson()).toList();
    });

    return {
      'ipAddress': ipAddress,
      'clusterId': clusterId,
      'clusterMemberId': clusterMemberId,
      'routerAddress': routerAddress,
      'description': description,
      'deviceType': deviceType,
      'deviceState': deviceState,
      'deviceAddresses': deviceAddresses,
      'devices': devicesJson,
    };
  }
}

class HelvarDevice {
  final String address;
  final int subnet;
  final int deviceId;
  String? description;
  String? deviceType;
  String? deviceState;

  HelvarDevice({
    required this.address,
    required this.subnet,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'subnet': subnet,
      'deviceId': deviceId,
      'description': description,
      'deviceType': deviceType,
      'deviceState': deviceState,
    };
  }
}

class HelvarNetClient {
  final String routerIP;
  final int tcpPort = 50000;

  HelvarNetClient(this.routerIP);

  /// Send a TCP command and get the response
  Future<String> sendTcpCommand(String command) async {
    try {
      final socket = await Socket.connect(routerIP, tcpPort);
      socket.write(command);

      final responseData =
          await socket.first.timeout(const Duration(seconds: 3), onTimeout: () {
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

  /// Query device type
  Future<String> queryDeviceType(String address) async {
    final command = '>V:2,C:104,@$address#';
    return sendTcpCommand(command);
  }

  /// Query device description
  Future<String> queryDeviceDescription(String address) async {
    final command = '>V:2,C:106,@$address#';
    return sendTcpCommand(command);
  }

  /// Query device state
  Future<String> queryDeviceState(String address) async {
    final command = '>V:2,C:110,@$address#';
    return sendTcpCommand(command);
  }

  /// Query device types and addresses
  Future<String> queryDeviceTypesAndAddresses(String address) async {
    final command = '>V:2,C:100,@$address#';
    return sendTcpCommand(command);
  }

  /// Parse device addresses from command 100 response
  Map<int, int> parseDeviceAddressesAndTypes(String response) {
    final deviceMap = <int, int>{};

    // The response format is deviceType@deviceId pairs
    final pairs = response.split(',');

    for (final pair in pairs) {
      if (pair.contains('@')) {
        final parts = pair.split('@');
        if (parts.length == 2) {
          try {
            final deviceType = int.parse(parts[0]);
            final deviceId = int.parse(parts[1]);
            deviceMap[deviceId] = deviceType;
          } catch (e) {
            print('Error parsing device pair: $pair - $e');
          }
        }
      }
    }

    return deviceMap;
  }

  /// Discover router information
  Future<HelvarRouter?> discoverRouterInfo() async {
    final ipParts = routerIP.split('.');
    if (ipParts.length != 4) return null;

    final clusterId = int.parse(ipParts[2]);
    final clusterMemberId = int.parse(ipParts[3]);
    final routerAddress = '$clusterId.$clusterMemberId';

    final router = HelvarRouter(
      ipAddress: routerIP,
      clusterId: clusterId,
      clusterMemberId: clusterMemberId,
    );

    // Query router type and description
    final typeResponse = await queryDeviceType(routerAddress);
    if (typeResponse.startsWith('?')) {
      router.deviceType = typeResponse.split('=')[1].replaceAll('#', '');

      final descResponse = await queryDeviceDescription(routerAddress);
      if (descResponse.startsWith('?')) {
        router.description = descResponse.split('=')[1].replaceAll('#', '');
      }

      // Query device state (Command 110)
      print('Querying router state...');
      final stateResponse = await queryDeviceState(routerAddress);
      if (stateResponse.startsWith('?')) {
        router.deviceState = stateResponse.split('=')[1].replaceAll('#', '');
        print('Router state: ${router.deviceState}');
      } else {
        print('Failed to get router state: $stateResponse');
      }

      // Query device types and addresses (Command 100)
      print('Querying router for device types and addresses...');
      final typesAndAddressesResponse =
          await queryDeviceTypesAndAddresses(routerAddress);
      if (typesAndAddressesResponse.startsWith('?')) {
        final data =
            typesAndAddressesResponse.split('=')[1].replaceAll('#', '');
        print('Router device types and addresses: $data');

        // Store raw response for reference
        router.deviceAddresses = data.split(',');
      } else {
        print(
            'Failed to get device types and addresses: $typesAndAddressesResponse');
      }

      return router;
    }

    return null;
  }

  /// Discover devices on a subnet
  Future<List<HelvarDevice>> discoverDevices(
      HelvarRouter router, int subnet) async {
    final devices = <HelvarDevice>[];

    // Query for subnet information
    print('Querying for subnet $subnet information...');
    final subnetResponse =
        await queryDeviceTypesAndAddresses('${router.routerAddress}.$subnet');

    if (subnetResponse.startsWith('?')) {
      final data = subnetResponse.split('=')[1].replaceAll('#', '');
      print('Subnet $subnet device information: $data');

      // Parse the device information
      final deviceMap = parseDeviceAddressesAndTypes(data);
      print('Found ${deviceMap.length} devices in subnet $subnet');

      // Query each device
      for (final entry in deviceMap.entries) {
        final deviceId = entry.key;
        final deviceType = entry.value;

        // Skip special device IDs that might be reserved
        if (deviceId > 10000) {
          print('Skipping high device ID: $deviceId');
          continue;
        }

        final deviceAddress = '${router.routerAddress}.$subnet.$deviceId';
        print('Querying device: $deviceAddress (Type: $deviceType)');

        final device = HelvarDevice(
          address: deviceAddress,
          subnet: subnet,
          deviceId: deviceId,
        );

        // Set the device type from the map
        device.deviceType = deviceType.toString();

        // Get device description
        final descResponse = await queryDeviceDescription(deviceAddress);
        if (descResponse.startsWith('?')) {
          device.description = descResponse.split('=')[1].replaceAll('#', '');
          print('  Description: ${device.description}');
        } else {
          print('  Failed to get description: $descResponse');
        }

        // Get device state
        final stateResponse = await queryDeviceState(deviceAddress);
        if (stateResponse.startsWith('?')) {
          device.deviceState = stateResponse.split('=')[1].replaceAll('#', '');
          print('  State: ${device.deviceState}');
        } else {
          print('  Failed to get state: $stateResponse');
        }

        devices.add(device);
      }
    } else {
      print('No subnet information found for subnet $subnet');
    }

    return devices;
  }

  /// Discover all devices on all possible subnets (1-4)
  Future<void> discoverAllDevices(HelvarRouter router) async {
    // According to documentation, subnets range from 1 to 4
    for (int subnet = 1; subnet <= 4; subnet++) {
      print('\nScanning subnet $subnet...');
      final devices = await discoverDevices(router, subnet);

      if (devices.isNotEmpty) {
        router.devicesBySubnet[subnet] = devices;
        print('Found ${devices.length} devices on subnet $subnet');
      } else {
        print('No devices found on subnet $subnet');
      }
    }
  }
}

void main() async {
  // Connect to the router
  final routerIP = '10.11.10.150';
  final client = HelvarNetClient(routerIP);

  print('HelvarNet Device Query Test');
  print('==========================');
  print('Router IP: $routerIP\n');

  try {
    // Discover router information
    print('Discovering router information...');
    final router = await client.discoverRouterInfo();

    if (router != null) {
      print('\nRouter found:');
      print('- Address: @${router.routerAddress}');
      print('- Cluster ID: ${router.clusterId}');
      print('- Cluster Member ID: ${router.clusterMemberId}');
      print('- Type: ${router.deviceType}');
      print('- Description: ${router.description}');
      print('- State: ${router.deviceState}');

      // Discover devices on all subnets
      print('\nDiscovering devices on all subnets...');
      await client.discoverAllDevices(router);

      // Print summary of found devices
      int totalDevices = 0;
      router.devicesBySubnet.forEach((subnet, devices) {
        totalDevices += devices.length;
      });

      print(
          '\nSummary: Found $totalDevices devices across ${router.devicesBySubnet.length} subnets');

      // Print device details for each subnet
      router.devicesBySubnet.forEach((subnet, devices) {
        print('\nSubnet $subnet (${devices.length} devices):');
        for (final device in devices) {
          print(
              '  @${device.address}: ${device.description ?? "No description"} (Type: ${device.deviceType ?? "Unknown"}, State: ${device.deviceState ?? "Unknown"})');
        }
      });
    } else {
      print('Router not found or not responding');
    }
  } catch (e) {
    print('Error: $e');
    print(e.toString());
  }

  print('\nTest completed.');
}
