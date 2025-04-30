import 'dart:convert';
import 'dart:io';

/// Device State Flag mapping
class DeviceStateFlags {
  static const int disabled = 0x00000001;
  static const int lampFailure = 0x00000002;
  static const int missing = 0x00000004;
  static const int faulty = 0x00000008;
  static const int refreshing = 0x00000010;
  static const int emergencyResting = 0x00000100;
  static const int inEmergency = 0x00000400;
  static const int inProlong = 0x00000800;
  static const int funcTestInProgress = 0x00001000;
  static const int durationTestInProgress = 0x00002000;
  static const int durationTestPending = 0x00010000;
  static const int funcTestPending = 0x00020000;
  static const int batteryFailure = 0x00040000;
  static const int emergencyInhibit = 0x00200000;
  static const int funcTestRequested = 0x00400000;
  static const int durationTestRequested = 0x00800000;
  static const int unknown = 0x01000000;
  static const int overTemperature = 0x02000000;
  static const int overCurrent = 0x04000000;
  static const int commsError = 0x08000000;
  static const int severeError = 0x10000000;
  static const int badReply = 0x20000000;
  static const int deviceMismatch = 0x80000000;

  static String getStateFlagsDescription(int flags) {
    final descriptions = <String>[];

    if (flags == 0) return 'Normal';

    if ((flags & disabled) != 0) descriptions.add('Disabled');
    if ((flags & lampFailure) != 0) descriptions.add('Lamp Failure');
    if ((flags & missing) != 0) descriptions.add('Missing');
    if ((flags & faulty) != 0) descriptions.add('Faulty');
    if ((flags & refreshing) != 0) descriptions.add('Refreshing');
    if ((flags & emergencyResting) != 0) descriptions.add('Emergency Resting');
    if ((flags & inEmergency) != 0) descriptions.add('In Emergency');
    if ((flags & inProlong) != 0) descriptions.add('In Prolong');
    if ((flags & funcTestInProgress) != 0)
      descriptions.add('Function Test In Progress');
    if ((flags & durationTestInProgress) != 0)
      descriptions.add('Duration Test In Progress');
    if ((flags & durationTestPending) != 0)
      descriptions.add('Duration Test Pending');
    if ((flags & funcTestPending) != 0)
      descriptions.add('Function Test Pending');
    if ((flags & batteryFailure) != 0) descriptions.add('Battery Failure');
    if ((flags & emergencyInhibit) != 0) descriptions.add('Emergency Inhibit');
    if ((flags & funcTestRequested) != 0)
      descriptions.add('Function Test Requested');
    if ((flags & durationTestRequested) != 0)
      descriptions.add('Duration Test Requested');
    if ((flags & unknown) != 0) descriptions.add('Unknown State');
    if ((flags & overTemperature) != 0) descriptions.add('Over Temperature');
    if ((flags & overCurrent) != 0) descriptions.add('Over Current');
    if ((flags & commsError) != 0) descriptions.add('Communications Error');
    if ((flags & severeError) != 0) descriptions.add('Severe Error');
    if ((flags & badReply) != 0) descriptions.add('Bad Reply');
    if ((flags & deviceMismatch) != 0) descriptions.add('Device Mismatch');

    return descriptions.join(', ');
  }
}

/// Device Type mapping
class DeviceTypes {
  // Protocol constants
  static const int dali = 0x01;
  static const int digidim = 0x02;
  static const int imagine = 0x04;
  static const int dmx = 0x08;

  // DALI device types
  static final Map<int, String> daliTypes = {
    0x0001: 'Fluorescent Lamps',
    0x0101: 'Self-contained emergency lighting',
    0x0201: 'Discharge lamps',
    0x0301: 'Low voltage halogen lamps',
    0x0401: 'Incandescent lamps',
    0x0501: 'Conversion into D.C. voltage',
    0x0601: 'LED modules',
    0x0701: 'Switching function (Relay)',
    0x0801: 'Colour control',
    0x0901: 'Sequencer',
  };

  // Digidim device types (partial list)
  static final Map<int, String> digidimTypes = {
    0x00100802: '100 – Rotary',
    0x00110702: '110 – Single Sider',
    0x00111402: '111 – Double Sider',
    0x00121302: '121 – 2 Button On/Off + IR',
    0x00124402: '124 – 5 Button + IR',
    0x00125102: '125 – 5 Button + Modifier + IR',
    0x00126802: '126 – 8 Button + IR',
    0x00170102: '170 – IR Receiver',
    0x00312502: '312 – Multisensor',
    0x00494802: '494 – Relay Unit',
    0x00496602: '498 – Relay Unit',
  };

  // Imagine (SDIM) device types (partial list)
  static final Map<int, String> imagineTypes = {
    0x0000F104: '474 – 4 Channel Ballast Controller - Relay Unit',
    0x0000F204: '474 – 4 Channel Ballast Controller - Output Unit',
    0x0000F304: '458/SW8 – 8-Channel Relay Module',
    0x0000F404: '458/CTR8 – 8-Channel Ballast Controller',
    0x0000F504: '458/OPT4 – Options Module',
    0x0000F604: '498 – 8-Channel Relay Unit',
  };

  // DMX device types
  static final Map<int, String> dmxTypes = {
    0x00000008: 'DMX No device present',
    0x00000108: 'DMX Channel In',
    0x00000208: 'DMX Channel Out',
  };

  // Get formatted type description
  static String getTypeDescription(int typeCode) {
    // Try to identify by protocol first (last byte)
    final protocol = typeCode & 0xFF;
    final deviceType = typeCode >> 8;

    if (protocol == dali) {
      return daliTypes[typeCode] ??
          'DALI Device (Type: 0x${typeCode.toRadixString(16)})';
    } else if (protocol == digidim) {
      return digidimTypes[typeCode] ??
          'Digidim Device (Type: 0x${typeCode.toRadixString(16)})';
    } else if (protocol == imagine) {
      return imagineTypes[typeCode] ??
          'Imagine Device (Type: 0x${typeCode.toRadixString(16)})';
    } else if (protocol == dmx) {
      return dmxTypes[typeCode] ??
          'DMX Device (Type: 0x${typeCode.toRadixString(16)})';
    }

    // Special handling for common detected types
    if (typeCode == 4818434) {
      return '498 – Relay Unit';
    } else if (typeCode == 3220738) {
      return '312 – Multisensor';
    } else if (typeCode == 1537) {
      return 'LED Unit';
    } else if (typeCode == 1265666) {
      return 'Button Panel';
    }

    return 'Unknown Device (Type: 0x${typeCode.toRadixString(16)})';
  }
}

class HelvarRouter {
  final String ipAddress;
  final int clusterId;
  final int clusterMemberId;
  final String routerAddress;
  String? description;
  String? deviceType;
  int? deviceStateCode;
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
      'deviceStateCode': deviceStateCode,
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
  int? deviceTypeCode;
  String? deviceType;
  int? deviceStateCode;
  String? deviceState;
  Map<String, dynamic> additionalInfo = {};

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
      'deviceTypeCode': deviceTypeCode,
      'deviceType': deviceType,
      'deviceStateCode': deviceStateCode,
      'deviceState': deviceState,
      'additionalInfo': additionalInfo,
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

  /// Extract response value
  String? extractResponseValue(String response) {
    if (response.startsWith('?') && response.contains('=')) {
      return response.split('=')[1].replaceAll('#', '');
    }
    return null;
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
      final typeValue = extractResponseValue(typeResponse);
      if (typeValue != null) {
        router.deviceType = typeValue;
      }

      final descResponse = await queryDeviceDescription(routerAddress);
      final descValue = extractResponseValue(descResponse);
      if (descValue != null) {
        router.description = descValue;
      }

      // Query device state (Command 110)
      print('Querying router state...');
      final stateResponse = await queryDeviceState(routerAddress);
      final stateValue = extractResponseValue(stateResponse);
      if (stateValue != null) {
        final stateCode = int.tryParse(stateValue) ?? 0;
        router.deviceStateCode = stateCode;
        router.deviceState =
            DeviceStateFlags.getStateFlagsDescription(stateCode);
        print('Router state: $stateCode (${router.deviceState})');
      } else {
        print('Failed to get router state: $stateResponse');
      }

      // Query device types and addresses (Command 100)
      print('Querying router for device types and addresses...');
      final typesAndAddressesResponse =
          await queryDeviceTypesAndAddresses(routerAddress);
      final addressesValue = extractResponseValue(typesAndAddressesResponse);
      if (addressesValue != null) {
        print('Router device types and addresses: $addressesValue');
        router.deviceAddresses = addressesValue.split(',');
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
    final subnetValue = extractResponseValue(subnetResponse);

    if (subnetValue != null) {
      print('Subnet $subnet device information: $subnetValue');

      // Parse the device information
      final deviceMap = parseDeviceAddressesAndTypes(subnetValue);
      print('Found ${deviceMap.length} devices in subnet $subnet');

      // Query each device
      for (final entry in deviceMap.entries) {
        final deviceId = entry.key;
        final typeCode = entry.value;

        // Skip special device IDs that might be reserved
        if (deviceId > 10000) {
          print('Skipping high device ID: $deviceId');
          continue;
        }

        final deviceAddress = '${router.routerAddress}.$subnet.$deviceId';
        print('Querying device: $deviceAddress (TypeCode: $typeCode)');

        final device = HelvarDevice(
          address: deviceAddress,
          subnet: subnet,
          deviceId: deviceId,
        );

        // Set the device type from the map
        device.deviceTypeCode = typeCode;
        device.deviceType = DeviceTypes.getTypeDescription(typeCode);

        // Get device description
        final descResponse = await queryDeviceDescription(deviceAddress);
        final descValue = extractResponseValue(descResponse);
        if (descValue != null) {
          device.description = descValue;
          print('  Description: ${device.description}');
        } else {
          print('  Failed to get description: $descResponse');
        }

        // Get device state
        final stateResponse = await queryDeviceState(deviceAddress);
        final stateValue = extractResponseValue(stateResponse);
        if (stateValue != null) {
          final stateCode = int.tryParse(stateValue) ?? 0;
          device.deviceStateCode = stateCode;
          device.deviceState =
              DeviceStateFlags.getStateFlagsDescription(stateCode);
          print('  State: $stateCode (${device.deviceState})');
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
      print(
          '- State: ${router.deviceState} [Code: ${router.deviceStateCode ?? "Unknown"}]');

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
              '  @${device.address}: ${device.description ?? "No description"}');
          print(
              '    Type: ${device.deviceType} [Code: ${device.deviceTypeCode}]');
          print(
              '    State: ${device.deviceState} [Code: ${device.deviceStateCode}]');
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
