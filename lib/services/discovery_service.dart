import 'dart:async';
import 'package:uuid/uuid.dart';
import '../comm/models/command_models.dart';
import '../models/helvar_models/helvar_device.dart';
import '../models/helvar_models/helvar_group.dart';
import '../models/helvar_models/helvar_router.dart';
import '../models/helvar_models/input_device.dart';
import '../models/helvar_models/output_device.dart';
import '../models/helvar_models/emergency_device.dart';
import '../protocol/device_types.dart';
import '../protocol/protocol_constants.dart';
import '../protocol/query_commands.dart';
import '../comm/router_command_service.dart';
import '../utils/logger.dart';

class DiscoveryService {
  final RouterCommandService commandService;

  DiscoveryService(this.commandService);

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
    try {
      bool connected = await commandService.ensureConnection(routerIpAddress);
      if (!connected) {
        return null;
      }

      return await discoverRouter(routerIpAddress);
    } catch (e) {
      logError('Error discovering router with persistent connection: $e');
      return null;
    }
  }

  Future<HelvarRouter?> _createBasicRouter(String routerIpAddress) async {
    final ipParts = routerIpAddress.split('.');
    if (ipParts.length != 4) {
      logDebug('Invalid router IP address format: $routerIpAddress');
      return null;
    }

    final clusterId = int.parse(ipParts[2]);
    final clusterMemberId = int.parse(ipParts[3]);
    final routerAddress = '$clusterId.$clusterMemberId';

    logInfo('Router address derived as: $routerAddress');

    return HelvarRouter(
      address: routerAddress,
      ipAddress: routerIpAddress,
      description: 'Router $clusterMemberId',
      clusterId: clusterId,
      clusterMemberId: clusterMemberId,
    );
  }

  Future<HelvarRouter?> discoverRouter(String routerIpAddress) async {
    try {
      final router = await _createBasicRouter(routerIpAddress);
      if (router == null) {
        return null;
      }

      final typeResponse = await commandService.sendCommand(
          routerIpAddress,
          HelvarNetCommands.queryDeviceType(
              "${router.clusterId}.${router.clusterMemberId}"),
          priority: CommandPriority.high);

      if (typeResponse.success && typeResponse.response != null) {
        final typeValue = extractResponseValue(typeResponse.response!);
        if (typeValue != null) {
          final typeCode = int.tryParse(typeValue) ?? 0;
          router.deviceTypeCode = typeCode;
          router.deviceType = getDeviceTypeDescription(typeCode);
        }
      } else {
        logDebug('Failed to get router type: $typeResponse');
      }

      final descResponse = await commandService.sendCommand(
          routerIpAddress,
          HelvarNetCommands.queryDescriptionDevice(
              "${router.clusterId}.${router.clusterMemberId}"));
      if (descResponse.success && descResponse.response != null) {
        final descValue = extractResponseValue(descResponse.response!);
        if (descValue != null) {
          router.description = descValue;
        } else {
          logDebug('Failed to get router description: $descResponse');
        }
      }

      final stateResponse = await commandService.sendCommand(
          routerIpAddress,
          HelvarNetCommands.queryDeviceState(
              "${router.clusterId}.${router.clusterMemberId}"));
      if (stateResponse.success && stateResponse.response != null) {
        final stateValue = extractResponseValue(stateResponse.response!);
        if (stateValue != null) {
          final stateCode = int.tryParse(stateValue) ?? 0;
          router.deviceStateCode = stateCode;
          router.deviceState = getStateFlagsDescription(stateCode);
        } else {
          logDebug('Failed to get router state: $stateResponse');
        }
      }

      final typesAndAddressesResponse = await commandService.sendCommand(
          routerIpAddress,
          HelvarNetCommands.queryDeviceTypesAndAddresses(router.address));
      if (typesAndAddressesResponse.success &&
          typesAndAddressesResponse.response != null) {
        final addressesValue =
            extractResponseValue(typesAndAddressesResponse.response!);
        if (addressesValue != null) {
          router.deviceAddresses = addressesValue.split(',');
        } else {
          logDebug(
              'Failed to get device types and addresses: $typesAndAddressesResponse');
        }
      }

      // Device discovery loop remains the same for now
      for (int subnet = 1; subnet <= 4; subnet++) {
        final devicesResponse = await commandService.sendCommand(
            routerIpAddress,
            HelvarNetCommands.queryDeviceTypesAndAddresses(
                '${router.clusterId}.${router.clusterMemberId}.$subnet'));
        if (devicesResponse.success && devicesResponse.response != null) {
          final devicesValue = extractResponseValue(devicesResponse.response!);
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

            final deviceAddress =
                '${router.clusterId}.${router.clusterMemberId}.$subnet.$deviceId';
            final descResponse = await commandService.sendCommand(
                routerIpAddress,
                HelvarNetCommands.queryDescriptionDevice(deviceAddress));
            final description =
                descResponse.success && descResponse.response != null
                    ? extractResponseValue(descResponse.response!)
                    : 'Device $deviceId';

            final deviceStateResponse = await commandService.sendCommand(
                routerIpAddress,
                HelvarNetCommands.queryDeviceState(deviceAddress));
            int? deviceStateCode;
            String deviceState = '';

            if (deviceStateResponse.success &&
                deviceStateResponse.response != null) {
              final deviceStateValue =
                  extractResponseValue(deviceStateResponse.response!);
              deviceStateCode = int.tryParse(deviceStateValue!) ?? 0;
              deviceState = getStateFlagsDescription(deviceStateCode);
              logInfo('  State: $deviceStateCode ($deviceState)');
            }

            int? loadLevel;
            if (typeCode == 1 || typeCode == 1025 || typeCode == 1537) {
              try {
                final levelResponse = await commandService.sendCommand(
                    routerIpAddress,
                    HelvarNetCommands.queryLoadLevel(deviceAddress));
                if (levelResponse.success && levelResponse.response != null) {
                  final levelValue =
                      extractResponseValue(levelResponse.response!);
                  loadLevel = int.tryParse(levelValue!) ?? 0;
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
                description: description!,
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
                description: description!,
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
                description: description!,
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
                description: description!,
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
          } else {
            logWarning('No devices found on subnet $subnet');
          }
        }
      }

      return router;
    } catch (e) {
      logError('Error discovering router: $e');
      return null;
    }
  }

  Future<List<HelvarGroup>> discoverGroups(String routerIpAddress) async {
    final groups = <HelvarGroup>[];

    try {
      final groupsResponse = await commandService.sendCommand(
        routerIpAddress,
        HelvarNetCommands.queryGroups(),
        priority: CommandPriority.high,
      );

      final groupsValue =
          DiscoveryService.extractResponseValue(groupsResponse.response ?? '');

      if (groupsValue != null && groupsValue.isNotEmpty) {
        final groupIds = groupsValue.split(',');

        for (final groupId in groupIds) {
          if (groupId.isEmpty) continue;

          try {
            final descResponse = await commandService.sendCommand(
              routerIpAddress,
              HelvarNetCommands.queryDescriptionGroup(int.parse(groupId)),
              priority: CommandPriority.high,
            );

            final description = DiscoveryService.extractResponseValue(
                    descResponse.response ?? '') ??
                'Group $groupId';

            groups.add(HelvarGroup(
              id: const Uuid().v4(),
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
}
