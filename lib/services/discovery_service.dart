import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/helvar_device.dart';
import '../models/helvar_router.dart';
import '../models/input_device.dart';
import '../models/output_device.dart';
import '../models/emergency_device.dart';
import '../protocol/device_types.dart';
import '../protocol/protocol_constants.dart';
import '../protocol/query_commands.dart';

class DiscoveryService {
  static List<ButtonPoint> generateButtonPoints(String deviceName) {
    final points = <ButtonPoint>[];
    points.add(ButtonPoint(
      name: '${deviceName}_Missing',
      function: 'Status',
      buttonId: 0,
    ));
    for (int i = 1; i <= 7; i++) {
      points.add(ButtonPoint(
        name: '${deviceName}_Button$i',
        function: 'Button',
        buttonId: i,
      ));
    }
    for (int i = 1; i <= 7; i++) {
      points.add(ButtonPoint(
        name: '${deviceName}_IR$i',
        function: 'IR Receiver',
        buttonId: i + 100, // Using offset for IR receivers
      ));
    }

    return points;
  }

  static String? extractResponseValue(String response) {
    if ((response.startsWith('?') || response.startsWith('!')) &&
        response.contains('=')) {
      final parts = response.split('=');
      if (parts.length > 1) {
        return parts[1].replaceAll('#', '');
      }
    }
    return null;
  }

  static Map<int, int> parseDeviceAddressesAndTypes(String response) {
    final deviceMap = <int, int>{};
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
            debugPrint('Error parsing device pair: $pair - $e');
          }
        }
      }
    }

    return deviceMap;
  }

  Future<HelvarRouter?> discoverRouter(String routerIpAddress) async {
    Socket? socket;

    try {
      socket = await Socket.connect(routerIpAddress, defaultTcpPort);

      final ipParts = routerIpAddress.split('.');
      if (ipParts.length != 4) {
        debugPrint('Invalid router IP address format: $routerIpAddress');
        return null;
      }

      final clusterId = int.parse(ipParts[2]);
      final clusterMemberId = int.parse(ipParts[3]);
      final routerAddress = '$clusterId.$clusterMemberId';

      debugPrint('Router address derived as: $routerAddress');

      final router = HelvarRouter(
        address: routerAddress,
        ipAddress: routerIpAddress,
        description: 'Router $clusterMemberId', // Default description
        clusterId: clusterId,
        clusterMemberId: clusterMemberId,
      );

      debugPrint('Querying router type...');
      final typeResponse = await _sendCommand(
          socket,
          HelvarNetCommands.queryDeviceType(
              router.version, clusterId, clusterMemberId, 0, 0));
      final typeValue = extractResponseValue(typeResponse);
      if (typeValue != null) {
        final typeCode = int.tryParse(typeValue) ?? 0;
        router.deviceTypeCode = typeCode;
        router.deviceType = getDeviceTypeDescription(typeCode);
        debugPrint('Router type: $typeCode (${router.deviceType})');
      } else {
        debugPrint('Failed to get router type: $typeResponse');
      }

      debugPrint('Querying router description...');
      final descResponse = await _sendCommand(
          socket,
          HelvarNetCommands.queryDescriptionDevice(
              router.version, clusterId, clusterMemberId, 0, 0));
      final descValue = extractResponseValue(descResponse);
      if (descValue != null) {
        router.description = descValue;
        debugPrint('Router description: ${router.description}');
      } else {
        debugPrint('Failed to get router description: $descResponse');
      }

      debugPrint('Querying router state...');
      final stateResponse = await _sendCommand(
          socket,
          HelvarNetCommands.queryDeviceState(
              router.version, clusterId, clusterMemberId, 0, 0));
      final stateValue = extractResponseValue(stateResponse);
      if (stateValue != null) {
        final stateCode = int.tryParse(stateValue) ?? 0;
        router.deviceStateCode = stateCode;
        router.deviceState = getStateFlagsDescription(stateCode);
        debugPrint('Router state: $stateCode (${router.deviceState})');
      } else {
        debugPrint('Failed to get router state: $stateResponse');
      }

      debugPrint('Querying router for device types and addresses...');
      final typesAndAddressesResponse = await _sendCommand(
          socket, '>V:1,C:100,@$clusterId.$clusterMemberId#');
      final addressesValue = extractResponseValue(typesAndAddressesResponse);
      if (addressesValue != null) {
        debugPrint('Router device types and addresses: $addressesValue');
        router.deviceAddresses = addressesValue.split(',');
      } else {
        debugPrint(
            'Failed to get device types and addresses: $typesAndAddressesResponse');
      }

      for (int subnet = 1; subnet <= 4; subnet++) {
        debugPrint('\nScanning subnet $subnet...');

        final devicesResponse = await _sendCommand(
            socket, '>V:1,C:100,@$clusterId.$clusterMemberId.$subnet#');
        final devicesValue = extractResponseValue(devicesResponse);

        if (devicesValue == null || devicesValue.isEmpty) {
          debugPrint('No devices found on subnet $subnet');
          continue;
        }

        debugPrint('Subnet $subnet device information: $devicesValue');
        final deviceAddressTypes = parseDeviceAddressesAndTypes(devicesValue);
        debugPrint(
            'Found ${deviceAddressTypes.length} devices in subnet $subnet');

        final subnetDevices = <HelvarDevice>[];

        for (final entry in deviceAddressTypes.entries) {
          final deviceId = entry.key;
          final typeCode = entry.value;

          if (deviceId >= 65500) {
            debugPrint('Skipping high device ID: $deviceId');
            continue;
          }

          final deviceAddress = '$clusterId.$clusterMemberId.$subnet.$deviceId';
          debugPrint('Querying device: $deviceAddress (TypeCode: $typeCode)');

          final descResponse = await _sendCommand(
              socket,
              HelvarNetCommands.queryDescriptionDevice(router.version,
                  clusterId, clusterMemberId, subnet, deviceId));
          final description =
              extractResponseValue(descResponse) ?? 'Device $deviceId';
          debugPrint('  Description: $description');

          final deviceStateResponse = await _sendCommand(
              socket,
              HelvarNetCommands.queryDeviceState(router.version, clusterId,
                  clusterMemberId, subnet, deviceId));
          int? deviceStateCode;
          String deviceState = '';

          final deviceStateValue = extractResponseValue(deviceStateResponse);
          if (deviceStateValue != null) {
            deviceStateCode = int.tryParse(deviceStateValue) ?? 0;
            deviceState = getStateFlagsDescription(deviceStateCode);
            debugPrint('  State: $deviceStateCode ($deviceState)');
          }

          int? loadLevel;
          if (typeCode == 1 || typeCode == 1025 || typeCode == 1537) {
            try {
              final levelResponse = await _sendCommand(
                  socket,
                  HelvarNetCommands.queryLoadLevel(router.version, clusterId,
                      clusterMemberId, subnet, deviceId));
              final levelValue = extractResponseValue(levelResponse);
              if (levelValue != null) {
                loadLevel = int.tryParse(levelValue) ?? 0;
                debugPrint('  Load level: $loadLevel%');
              }
            } catch (e) {
              debugPrint('Error getting load level: $e');
            }
          }

          final bool isButton = isButtonDevice(typeCode);
          final bool isMultisensor = isDeviceMultisensor(typeCode);
          final String deviceTypeString = getDeviceTypeDescription(typeCode);

          HelvarDevice device;

          if (isButton) {
            debugPrint('  Creating Input Device (Button Panel): $description');
            device = HelvarDriverInputDevice(
              deviceId: deviceId,
              address: deviceAddress,
              state: deviceState,
              description: description,
              props: deviceTypeString,
              hexId: '0x${typeCode.toRadixString(16)}',
              helvarType: 'input',
              deviceTypeCode: typeCode,
              deviceStateCode: deviceStateCode,
              isButtonDevice: true,
              buttonPoints: generateButtonPoints(description),
            );
          } else if (isMultisensor) {
            debugPrint('  Creating Input Device (Multisensor): $description');
            device = HelvarDriverInputDevice(
              deviceId: deviceId,
              address: deviceAddress,
              state: deviceState,
              description: description,
              props: deviceTypeString,
              hexId: '0x${typeCode.toRadixString(16)}',
              helvarType: 'input',
              deviceTypeCode: typeCode,
              deviceStateCode: deviceStateCode,
              isMultisensor: true,
              sensorInfo: {
                'hasPresence': true,
                'hasLightLevel': true,
                'hasTemperature': false,
              },
            );
          } else if (typeCode == 0x0101 ||
              (typeCode & 0xFF) == 0x01 && ((typeCode >> 8) & 0xFF) == 0x01) {
            debugPrint('  Creating Emergency Device: $description');
            device = HelvarDriverEmergencyDevice(
              deviceId: deviceId,
              address: deviceAddress,
              state: deviceState,
              description: description,
              props: deviceTypeString,
              hexId: '0x${typeCode.toRadixString(16)}',
              helvarType: 'emergency',
              deviceTypeCode: typeCode,
              deviceStateCode: deviceStateCode,
              emergency: true,
            );
          } else {
            debugPrint('  Creating Output Device: $description');
            device = HelvarDriverOutputDevice(
              deviceId: deviceId,
              address: deviceAddress,
              state: deviceState,
              description: description,
              props: deviceTypeString,
              hexId: '0x${typeCode.toRadixString(16)}',
              helvarType: 'output',
              deviceTypeCode: typeCode,
              deviceStateCode: deviceStateCode,
              level: loadLevel ?? 100,
            );
          }

          subnetDevices.add(device);
        }

        if (subnetDevices.isNotEmpty) {
          router.devicesBySubnet[subnet] = subnetDevices;
          for (final device in subnetDevices) {
            router.devices.add(device);
          }
        }
      }

      return router;
    } catch (e) {
      debugPrint('Error discovering router: $e');
      return null;
    } finally {
      socket?.destroy();
    }
  }

  Future<List<HelvarRouter>> discoverWorkgroup(
      List<String> routerIpAddresses) async {
    final routers = <HelvarRouter>[];

    for (final ipAddress in routerIpAddresses) {
      debugPrint('Discovering router at $ipAddress...');
      final router = await discoverRouter(ipAddress);
      if (router != null) {
        routers.add(router);
      }
    }

    return routers;
  }

  static Future<String> _sendCommand(Socket socket, String command) async {
    final completer = Completer<String>();

    final subscription = socket.asBroadcastStream().listen(
      (List<int> data) {
        final response = String.fromCharCodes(data).trim();
        completer.complete(response);
      },
      onError: (error) {
        debugPrint('Socket error: $error');
        completer.complete('ERROR: $error');
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete('NO_RESPONSE');
        }
      },
    );

    socket.write(command);

    final result = await completer.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        debugPrint('Command timed out: $command');
        return 'TIMEOUT';
      },
    );

    await subscription.cancel();
    return result;
  }
}
