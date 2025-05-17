import 'dart:async';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/helvar_models/helvar_device.dart';
import '../models/helvar_models/helvar_group.dart';
import '../models/helvar_models/helvar_router.dart';
import '../models/helvar_models/input_device.dart';
import '../models/helvar_models/output_device.dart';
import '../models/helvar_models/emergency_device.dart';
import '../protocol/device_types.dart';
import '../protocol/protocol_constants.dart';
import '../protocol/query_commands.dart';
import '../comm/router_connection_manager.dart';
import '../comm/router_command_service.dart';
import '../utils/logger.dart';

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
            logError('Error parsing device pair: $pair - $e');
          }
        }
      }
    }

    return deviceMap;
  }

  Future<HelvarRouter?> discoverRouterWithPersistentConnection(
      String routerIpAddress) async {
    final connectionManager = RouterConnectionManager();

    try {
      final router = await discoverRouter(routerIpAddress);

      if (router == null) {
        return null;
      }

      await connectionManager.getConnection(
        routerIpAddress,
      );

      return router;
    } catch (e) {
      logError('Error discovering router with persistent connection: $e');
      return null;
    }
  }

  Future<HelvarRouter?> discoverRouter(String routerIpAddress) async {
    Socket? socket;

    try {
      socket = await Socket.connect(routerIpAddress, defaultTcpPort);
      final broadcastStream = socket.asBroadcastStream();
      final ipParts = routerIpAddress.split('.');
      if (ipParts.length != 4) {
        logDebug('Invalid router IP address format: $routerIpAddress');
        return null;
      }

      final clusterId = int.parse(ipParts[2]);
      final clusterMemberId = int.parse(ipParts[3]);
      final routerAddress = '$clusterId.$clusterMemberId';

      logInfo('Router address derived as: $routerAddress');

      final router = HelvarRouter(
        address: routerAddress,
        ipAddress: routerIpAddress,
        description: 'Router $clusterMemberId',
        clusterId: clusterId,
        clusterMemberId: clusterMemberId,
      );

      final typeResponse = await _sendCommand(
          socket,
          HelvarNetCommands.queryDeviceType("$clusterId.$clusterMemberId"),
          broadcastStream);
      final typeValue = extractResponseValue(typeResponse);
      if (typeValue != null) {
        final typeCode = int.tryParse(typeValue) ?? 0;
        router.deviceTypeCode = typeCode;
        router.deviceType = getDeviceTypeDescription(typeCode);
      } else {
        logDebug('Failed to get router type: $typeResponse');
      }

      final descResponse = await _sendCommand(
          socket,
          HelvarNetCommands.queryDescriptionDevice(
              "$clusterId.$clusterMemberId"),
          broadcastStream);
      final descValue = extractResponseValue(descResponse);
      if (descValue != null) {
        router.description = descValue;
      } else {
        logDebug('Failed to get router description: $descResponse');
      }

      final stateResponse = await _sendCommand(
          socket,
          HelvarNetCommands.queryDeviceState("$clusterId.$clusterMemberId"),
          broadcastStream);
      final stateValue = extractResponseValue(stateResponse);
      if (stateValue != null) {
        final stateCode = int.tryParse(stateValue) ?? 0;
        router.deviceStateCode = stateCode;
        router.deviceState = getStateFlagsDescription(stateCode);
      } else {
        logDebug('Failed to get router state: $stateResponse');
      }

      final typesAndAddressesResponse = await _sendCommand(
          socket,
          HelvarNetCommands.queryDeviceTypesAndAddresses(routerAddress),
          broadcastStream);
      final addressesValue = extractResponseValue(typesAndAddressesResponse);
      if (addressesValue != null) {
        router.deviceAddresses = addressesValue.split(',');
      } else {
        logDebug(
            'Failed to get device types and addresses: $typesAndAddressesResponse');
      }

      for (int subnet = 1; subnet <= 4; subnet++) {
        final devicesResponse = await _sendCommand(
            socket,
            HelvarNetCommands.queryDeviceTypesAndAddresses(
                '$clusterId.$clusterMemberId.$subnet'),
            broadcastStream);
        final devicesValue = extractResponseValue(devicesResponse);

        if (devicesValue == null || devicesValue.isEmpty) {
          logWarning('No devices found on subnet $subnet');
          continue;
        }

        final deviceAddressTypes = parseDeviceAddressesAndTypes(devicesValue);
        final subnetDevices = <HelvarDevice>[];
        for (final entry in deviceAddressTypes.entries) {
          final deviceId = entry.key;
          final typeCode = entry.value;

          if (deviceId >= 65500) {
            logWarning('Skipping high device ID: $deviceId');
            continue;
          }

          final deviceAddress = '$clusterId.$clusterMemberId.$subnet.$deviceId';
          final descriptionCmd =
              HelvarNetCommands.queryDescriptionDevice(deviceAddress);
          final descResponse =
              await _sendCommand(socket, descriptionCmd, broadcastStream);
          final description =
              extractResponseValue(descResponse) ?? 'Device $deviceId';

          final deviceStateResponse = await _sendCommand(
              socket,
              HelvarNetCommands.queryDeviceState(deviceAddress),
              broadcastStream);
          int? deviceStateCode;
          String deviceState = '';

          final deviceStateValue = extractResponseValue(deviceStateResponse);
          if (deviceStateValue != null) {
            deviceStateCode = int.tryParse(deviceStateValue) ?? 0;
            deviceState = getStateFlagsDescription(deviceStateCode);
            logInfo('  State: $deviceStateCode ($deviceState)');
          }

          int? loadLevel;
          if (typeCode == 1 || typeCode == 1025 || typeCode == 1537) {
            try {
              final levelResponse = await _sendCommand(
                  socket,
                  HelvarNetCommands.queryLoadLevel(deviceAddress),
                  broadcastStream);
              final levelValue = extractResponseValue(levelResponse);
              if (levelValue != null) {
                loadLevel = int.tryParse(levelValue) ?? 0;
              }
            } catch (e) {
              logError('Error getting load level: $e');
            }
          }

          final bool isButton = isButtonDevice(typeCode);
          final bool isMultisensor = isDeviceMultisensor(typeCode);
          final String deviceTypeString = getDeviceTypeDescription(typeCode);

          HelvarDevice device;

          if (isButton) {
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
      logError('Error discovering router: $e');
      return null;
    } finally {
      socket?.destroy();
    }
  }

  Future<List<HelvarGroup>> discoverGroups(String routerIpAddress) async {
    Socket? socket;
    final groups = <HelvarGroup>[];

    try {
      socket = await Socket.connect(routerIpAddress, defaultTcpPort);
      final broadcastStream = socket.asBroadcastStream();

      final groupsResponse = await _sendCommand(
          socket, HelvarNetCommands.queryGroups(), broadcastStream);

      final groupsValue = extractResponseValue(groupsResponse);
      if (groupsValue != null && groupsValue.isNotEmpty) {
        final groupIds = groupsValue.split(',');

        for (final groupId in groupIds) {
          if (groupId.isEmpty) continue;

          try {
            final id = int.parse(groupId);

            final descResponse = await _sendCommand(socket,
                HelvarNetCommands.queryDescriptionGroup(id), broadcastStream);

            final description =
                extractResponseValue(descResponse) ?? 'Group $id';

            groups.add(HelvarGroup(
              id: const Uuid().v4(), // Generate a unique ID
              groupId: groupId,
              description: description,
              type: 'Group',
              powerPollingMinutes: 15,
              gatewayRouterIpAddress: routerIpAddress,
            ));
          } catch (e) {
            logError('Error processing group $groupId: $e');
          }
        }
      }

      return groups;
    } catch (e) {
      logError('Error discovering groups: $e');
      return [];
    } finally {
      socket?.destroy();
    }
  }

  Future<List<HelvarRouter>> discoverWorkgroup(
      List<String> routerIpAddresses) async {
    final routers = <HelvarRouter>[];

    for (final ipAddress in routerIpAddresses) {
      logInfo('Discovering router at $ipAddress...');
      final router = await discoverRouter(ipAddress);
      if (router != null) {
        routers.add(router);
      }
    }

    return routers;
  }

  static Future<String> _sendCommand(
      Socket socket, String command, Stream<List<int>> broadcastStream,
      {Duration timeout = const Duration(seconds: 15)}) async {
    final completer = Completer<String>();

    final subscription = broadcastStream.listen(
      (List<int> data) {
        final response = String.fromCharCodes(data).trim();
        completer.complete(response);
      },
      onError: (error) {
        logVerbose('Socket error: $error');
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
      timeout,
      onTimeout: () {
        logVerbose('Command timed out: $command');
        return 'TIMEOUT';
      },
    );

    await subscription.cancel();
    return result;
  }

  Future<String?> sendPersistentCommand(
      String routerIp, String routerId, String command,
      {Duration? timeout}) async {
    final commandService = RouterCommandService();

    try {
      final result = await commandService.sendCommand(
        routerIp,
        command,
        timeout: timeout,
      );

      if (result.success) {
        return result.response;
      } else {
        logVerbose('Command failed: ${result.errorMessage}');
        return null;
      }
    } catch (e) {
      logError('Error sending command: $e');
      return null;
    }
  }
}
