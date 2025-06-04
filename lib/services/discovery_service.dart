import 'dart:async';
import 'package:grms_designer/services/scene_query_service.dart';
import 'package:uuid/uuid.dart';
import '../comm/models/command_models.dart';
import '../models/helvar_models/helvar_device.dart';
import '../models/helvar_models/helvar_group.dart';
import '../models/helvar_models/helvar_router.dart';
import '../protocol/device_types.dart';
import '../protocol/protocol_constants.dart';
import '../protocol/query_commands.dart';
import '../comm/router_command_service.dart';
import '../utils/core/logger.dart';
import '../factories/helvar_device_factory.dart';
import '../protocol/protocol_parser.dart';

class DiscoveryService {
  final RouterCommandService commandService;

  DiscoveryService(this.commandService);

  Future<HelvarDevice?> _createDeviceFromDiscovery(
    HelvarRouter router,
    int subnet,
    int deviceId,
    int typeCode,
  ) async {
    final routerIpAddress = router.ipAddress;
    final deviceAddress =
        '${router.clusterId}.${router.clusterMemberId}.$subnet.$deviceId';

    final descResponse = await commandService.sendCommand(
      routerIpAddress,
      HelvarNetCommands.queryDescriptionDevice(deviceAddress),
    );
    final description = descResponse.success && descResponse.response != null
        ? ProtocolParser.extractResponseValue(descResponse.response!) ??
              'Device $deviceId'
        : 'Device $deviceId';

    final deviceStateResponse = await commandService.sendCommand(
      routerIpAddress,
      HelvarNetCommands.queryDeviceState(deviceAddress),
    );

    int? deviceStateCode;
    String deviceState = '';
    if (deviceStateResponse.success && deviceStateResponse.response != null) {
      final deviceStateValue = ProtocolParser.extractResponseValue(
        deviceStateResponse.response!,
      );
      deviceStateCode = int.tryParse(deviceStateValue!) ?? 0;
      deviceState = getStateFlagsDescription(deviceStateCode);
      logInfo('  State: $deviceStateCode ($deviceState)');
    }

    int? loadLevel;
    if (typeCode == 1 || typeCode == 1025 || typeCode == 1537) {
      try {
        final levelResponse = await commandService.sendCommand(
          routerIpAddress,
          HelvarNetCommands.queryLoadLevel(deviceAddress),
        );
        if (levelResponse.success && levelResponse.response != null) {
          final levelValue = ProtocolParser.extractResponseValue(
            levelResponse.response!,
          );
          loadLevel = int.tryParse(levelValue!) ?? 0;
        }
      } catch (e) {
        logError('Error getting load level: $e');
      }
    }

    final bool isButton = isButtonDevice(typeCode);
    final bool isMultisensor = isDeviceMultisensor(typeCode);
    final String deviceTypeString = getDeviceTypeDescription(typeCode);

    return HelvarDeviceFactory.createDevice(
      deviceId: deviceId,
      deviceAddress: deviceAddress,
      deviceState: deviceState,
      description: description,
      deviceTypeString: deviceTypeString,
      typeCode: typeCode,
      deviceStateCode: deviceStateCode,
      loadLevel: loadLevel,
      isButton: isButton,
      isMultisensor: isMultisensor,
    );
  }

  Future<HelvarGroup> discoverGroupScenes(
    String routerIpAddress,
    HelvarGroup group,
    SceneQueryService sceneQueryService,
  ) async {
    try {
      logInfo('Discovering scenes for group: ${group.groupId}');

      final groupIdInt = int.tryParse(group.groupId);
      if (groupIdInt == null) {
        logError('Invalid group ID: ${group.groupId}');
        return group;
      }

      final sceneData = await sceneQueryService.exploreGroupScenes(
        routerIpAddress,
        groupIdInt,
      );

      final lsig = await sceneQueryService.queryLastSceneInGroup(
        routerIpAddress,
        groupIdInt,
      );

      // TODO: Explore LSIB1 and LSIB2 commands when we understand the protocol better
      // For now, we'll leave them as null
      int? lsib1;
      int? lsib2;

      final sceneTable = sceneQueryService.buildSceneTable(sceneData);

      final updatedGroup = group.copyWith(
        lsig: lsig,
        lsib1: lsib1, // Will explore later
        lsib2: lsib2, // Will explore later
        sceneTable: sceneTable,
      );

      logInfo(
        'Scene discovery complete for group ${group.groupId}. Scene table: $sceneTable',
      );
      return updatedGroup;
    } catch (e) {
      logError('Error discovering group scenes: $e');
      return group;
    }
  }

  Future<List<HelvarGroup>> discoverScenesForGroups(
    String routerIpAddress,
    List<HelvarGroup> groups,
    SceneQueryService sceneQueryService,
  ) async {
    final updatedGroups = <HelvarGroup>[];

    for (final group in groups) {
      try {
        final updatedGroup = await discoverGroupScenes(
          routerIpAddress,
          group,
          sceneQueryService,
        );
        updatedGroups.add(updatedGroup);

        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        logError('Error discovering scenes for group ${group.groupId}: $e');
        updatedGroups.add(group);
      }
    }

    return updatedGroups;
  }

  Future<List<HelvarDevice>> _discoverSubnetDevices(
    HelvarRouter router,
    int subnet,
  ) async {
    final routerIpAddress = router.ipAddress;
    final subnetAddress =
        '${router.clusterId}.${router.clusterMemberId}.$subnet';

    final devicesResponse = await commandService.sendCommand(
      routerIpAddress,
      HelvarNetCommands.queryDeviceTypesAndAddresses(subnetAddress),
    );

    if (!devicesResponse.success || devicesResponse.response == null) {
      return [];
    }

    final devicesValue = ProtocolParser.extractResponseValue(
      devicesResponse.response!,
    );
    if (devicesValue == null || devicesValue.isEmpty) {
      logWarning('No devices found on subnet $subnet');
      return [];
    }

    final deviceAddressTypes = ProtocolParser.parseDeviceAddressesAndTypes(
      devicesValue,
    );
    final Map<String, int> descriptionCounts = {};
    final subnetDevices = <HelvarDevice>[];

    for (final entry in deviceAddressTypes.entries) {
      final deviceId = entry.key;
      final typeCode = entry.value;

      if (deviceId >= 65500) {
        logWarning('Skipping high device ID: $deviceId');
        continue;
      }

      final device = await _createDeviceFromDiscovery(
        router,
        subnet,
        deviceId,
        typeCode,
      );

      if (device != null) {
        String baseName = device.description;
        String uniqueName = baseName;

        if (descriptionCounts.containsKey(baseName)) {
          descriptionCounts[baseName] = descriptionCounts[baseName]! + 1;
          uniqueName = '${baseName}_${descriptionCounts[baseName]}';
        } else {
          descriptionCounts[baseName] = 0;
        }

        device.name = uniqueName;
        subnetDevices.add(device);
      }
    }

    return subnetDevices;
  }

  Future<void> _fetchRouterMetadata(HelvarRouter router) async {
    final routerIpAddress = router.ipAddress;
    final routerAddress = "${router.clusterId}.${router.clusterMemberId}";

    final typeResponse = await commandService.sendCommand(
      routerIpAddress,
      HelvarNetCommands.queryDeviceType(routerAddress),
      priority: CommandPriority.high,
    );

    if (typeResponse.success && typeResponse.response != null) {
      final typeValue = ProtocolParser.extractResponseValue(
        typeResponse.response!,
      );
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
      HelvarNetCommands.queryDescriptionDevice(routerAddress),
    );

    if (descResponse.success && descResponse.response != null) {
      final descValue = ProtocolParser.extractResponseValue(
        descResponse.response!,
      );
      if (descValue != null) {
        router.description = descValue;
      } else {
        logDebug('Failed to get router description: $descResponse');
      }
    }

    final stateResponse = await commandService.sendCommand(
      routerIpAddress,
      HelvarNetCommands.queryDeviceState(routerAddress),
    );

    if (stateResponse.success && stateResponse.response != null) {
      final stateValue = ProtocolParser.extractResponseValue(
        stateResponse.response!,
      );
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
      HelvarNetCommands.queryDeviceTypesAndAddresses(router.address),
    );

    if (typesAndAddressesResponse.success &&
        typesAndAddressesResponse.response != null) {
      final addressesValue = ProtocolParser.extractResponseValue(
        typesAndAddressesResponse.response!,
      );
      if (addressesValue != null) {
        router.deviceAddresses = addressesValue.split(',');
      } else {
        logDebug(
          'Failed to get device types and addresses: $typesAndAddressesResponse',
        );
      }
    }
  }

  Future<HelvarRouter?> discoverRouterWithPersistentConnection(
    String routerIpAddress,
  ) async {
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

  Future<void> _discoverRouterDevices(HelvarRouter router) async {
    for (int subnet = 1; subnet <= 4; subnet++) {
      final subnetDevices = await _discoverSubnetDevices(router, subnet);

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

  Future<HelvarRouter?> discoverRouter(String routerIpAddress) async {
    try {
      final router = await _createBasicRouter(routerIpAddress);
      if (router == null) {
        return null;
      }

      await _fetchRouterMetadata(router);
      await _discoverRouterDevices(router);

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

      final groupsValue = ProtocolParser.extractResponseValue(
        groupsResponse.response ?? '',
      );

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

            final description =
                ProtocolParser.extractResponseValue(
                  descResponse.response ?? '',
                ) ??
                'Group $groupId';

            groups.add(
              HelvarGroup(
                id: const Uuid().v4(),
                groupId: groupId,
                description: description,
                type: 'Group',
                powerPollingMinutes: 15,
                gatewayRouterIpAddress: routerIpAddress,
              ),
            );
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
    List<String> routerIpAddresses,
  ) async {
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
