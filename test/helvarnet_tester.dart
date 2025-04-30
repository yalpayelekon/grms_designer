import 'dart:convert';
import 'dart:io';

class HelvarRouter {
  final String ipAddress;
  final int clusterId;
  final int clusterMemberId;
  final String routerAddress;
  String? description;
  String? deviceType;
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
      'devices': devicesJson,
    };
  }
}

class HelvarDevice {
  final String address; // Full address @clusterId.memberId.subnet.device
  final int subnet;
  final int deviceId;
  String? description;
  String? deviceType;

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

  /// Discover router information
  Future<HelvarRouter?> discoverRouterInfo() async {
    // Parse router address from IP
    final ipParts = routerIP.split('.');
    if (ipParts.length != 4) return null;

    // Extract cluster ID and member ID from the IP address
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

      return router;
    }

    return null;
  }

  /// Discover devices on a subnet
  Future<List<HelvarDevice>> discoverDevices(HelvarRouter router, int subnet,
      {int maxDevices = 20}) async {
    final devices = <HelvarDevice>[];

    for (int deviceId = 1; deviceId <= maxDevices; deviceId++) {
      final deviceAddress = '${router.routerAddress}.$subnet.$deviceId';
      final typeResponse = await queryDeviceType(deviceAddress);

      if (typeResponse.startsWith('?')) {
        final device = HelvarDevice(
          address: deviceAddress,
          subnet: subnet,
          deviceId: deviceId,
        );

        device.deviceType = typeResponse.split('=')[1].replaceAll('#', '');

        // Get device description
        final descResponse = await queryDeviceDescription(deviceAddress);
        if (descResponse.startsWith('?')) {
          device.description = descResponse.split('=')[1].replaceAll('#', '');
        }

        devices.add(device);
      }
    }

    return devices;
  }

  /// Discover all devices on all possible subnets (1-4)
  Future<void> discoverAllDevices(HelvarRouter router,
      {int maxDevices = 20}) async {
    // According to documentation, subnets range from 1 to 4
    for (int subnet = 1; subnet <= 4; subnet++) {
      print('\nScanning subnet $subnet...');
      final devices =
          await discoverDevices(router, subnet, maxDevices: maxDevices);

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
      print('Router found:');
      print('- Address: @${router.routerAddress}');
      print('- Cluster ID: ${router.clusterId}');
      print('- Cluster Member ID: ${router.clusterMemberId}');
      print('- Type: ${router.deviceType}');
      print('- Description: ${router.description}');

      // Discover devices on all subnets (1-4)
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
              '  @${device.address}: ${device.description} (${device.deviceType})');
        }
      });
    } else {
      print('Router not found or not responding');
    }
  } catch (e) {
    print('Error: $e');
  }

  print('\nTest completed.');
}
