import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/utils/general_ui.dart';

import '../models/helvar_models/helvar_device.dart';
import '../models/helvar_models/helvar_group.dart';
import '../models/helvar_models/helvar_router.dart';
import '../models/helvar_models/output_device.dart';
import '../models/helvar_models/workgroup.dart';
import '../protocol/query_commands.dart';
import '../providers/router_connection_provider.dart';
import '../providers/workgroups_provider.dart';
import 'dialogs/action_dialogs.dart';

String _getWorkgroupIdForDevice(BuildContext context, HelvarDevice device) {
  final container = ProviderScope.containerOf(context);
  final workgroups = container.read(workgroupsProvider);

  for (final workgroup in workgroups) {
    for (final router in workgroup.routers) {
      for (final routerDevice in router.devices) {
        if (routerDevice.address == device.address) {
          return workgroup.id;
        }
      }
    }
  }

  return workgroups.isNotEmpty ? workgroups.first.id : "1";
}

void performRecallScene(
    BuildContext context, HelvarGroup group, int sceneNumber) {
  final container = ProviderScope.containerOf(context);
  final connectionManager = container.read(routerConnectionManagerProvider);

  final workgroups = container.read(workgroupsProvider);
  Workgroup? workgroup;

  for (final wg in workgroups) {
    if (wg.groups.any((g) => g.id == group.id)) {
      workgroup = wg;
      break;
    }
  }

  if (workgroup == null) {
    showSnackBarMsg(context, 'Workgroup not found for this group');
    return;
  }

  final groupId = int.tryParse(group.groupId);
  if (groupId == null) {
    showSnackBarMsg(context, 'Invalid group ID: ${group.groupId}');
    return;
  }

  String routerIpAddress = group.gatewayRouterIpAddress;
  if (routerIpAddress.isEmpty && workgroup.routers.isNotEmpty) {
    routerIpAddress = workgroup.routers.first.ipAddress;
  }

  if (routerIpAddress.isEmpty) {
    showSnackBarMsg(context, 'No router IP address available for this group');
    return;
  }

  final command = HelvarNetCommands.recallSceneGroup(
    2, // Protocol version
    groupId,
    1, // Block ID (default to 1)
    sceneNumber,
    fadeTime: 700, // Default fade time in 0.1 seconds
  );

  connectionManager
      .getConnection(
    routerIpAddress,
    connectionTimeout: const Duration(seconds: 5),
  )
      .then((connection) {
    if (connection.isConnected) {
      connection.sendCommand(command).then((success) {
        if (success) {
          showSnackBarMsg(context,
              'Recalled scene $sceneNumber for group ${group.groupId}');
        } else {
          showSnackBarMsg(context, 'Failed to send command to group');
        }
      });
    } else {
      showSnackBarMsg(context, 'Failed to establish connection to router');
    }
  }).catchError((error) {
    showSnackBarMsg(context, 'Connection error: $error');
  });
}

void performStoreScene(
    BuildContext context, HelvarGroup group, int sceneNumber) {
  final container = ProviderScope.containerOf(context);
  final connectionManager = container.read(routerConnectionManagerProvider);

  final workgroups = container.read(workgroupsProvider);
  Workgroup? workgroup;

  for (final wg in workgroups) {
    if (wg.groups.any((g) => g.id == group.id)) {
      workgroup = wg;
      break;
    }
  }

  if (workgroup == null) {
    showSnackBarMsg(context, 'Workgroup not found for this group');
    return;
  }

  final groupId = int.tryParse(group.groupId);
  if (groupId == null) {
    showSnackBarMsg(context, 'Invalid group ID: ${group.groupId}');
    return;
  }

  String routerIpAddress = group.gatewayRouterIpAddress;
  if (routerIpAddress.isEmpty && workgroup.routers.isNotEmpty) {
    routerIpAddress = workgroup.routers.first.ipAddress;
  }

  if (routerIpAddress.isEmpty) {
    showSnackBarMsg(context, 'No router IP address available for this group');
    return;
  }

  final command = HelvarNetCommands.storeAsSceneGroup(
    2, // Protocol version
    groupId,
    1, // Block ID (default to 1)
    sceneNumber,
    forceStore: true, // Force store
  );

  connectionManager
      .getConnection(
    routerIpAddress,
    connectionTimeout: const Duration(seconds: 5),
  )
      .then((connection) {
    if (connection.isConnected) {
      connection.sendCommand(command).then((success) {
        if (success) {
          showSnackBarMsg(
              context, 'Stored scene $sceneNumber for group ${group.groupId}');
        } else {
          showSnackBarMsg(context, 'Failed to send command to group');
        }
      });
    } else {
      showSnackBarMsg(context, 'Failed to establish connection to router');
    }
  }).catchError((error) {
    showSnackBarMsg(context, 'Connection error: $error');
  });
}

void performDirectLevel(BuildContext context, HelvarGroup group, int level) {
  final container = ProviderScope.containerOf(context);
  final connectionManager = container.read(routerConnectionManagerProvider);

  final workgroups = container.read(workgroupsProvider);
  Workgroup? workgroup;

  for (final wg in workgroups) {
    if (wg.groups.any((g) => g.id == group.id)) {
      workgroup = wg;
      break;
    }
  }

  if (workgroup == null) {
    showSnackBarMsg(context, 'Workgroup not found for this group');
    return;
  }

  final groupId = int.tryParse(group.groupId);
  if (groupId == null) {
    showSnackBarMsg(context, 'Invalid group ID: ${group.groupId}');
    return;
  }

  String routerIpAddress = group.gatewayRouterIpAddress;
  if (routerIpAddress.isEmpty && workgroup.routers.isNotEmpty) {
    routerIpAddress = workgroup.routers.first.ipAddress;
  }

  if (routerIpAddress.isEmpty) {
    showSnackBarMsg(context, 'No router IP address available for this group');
    return;
  }

  final command = HelvarNetCommands.directLevelGroup(
    2, // Protocol version
    groupId,
    level,
    fadeTime: 700, // Default fade time in 0.1 seconds
  );

  connectionManager
      .getConnection(
    routerIpAddress,
    connectionTimeout: const Duration(seconds: 5),
  )
      .then((connection) {
    if (connection.isConnected) {
      connection.sendCommand(command).then((success) {
        if (success) {
          showSnackBarMsg(
              context, 'Set direct level $level for group ${group.groupId}');
        } else {
          showSnackBarMsg(context, 'Failed to send command to group');
        }
      });
    } else {
      showSnackBarMsg(context, 'Failed to establish connection to router');
    }
  }).catchError((error) {
    showSnackBarMsg(context, 'Connection error: $error');
  });
}

void performDirectProportion(
    BuildContext context, HelvarGroup group, int proportion) {
  final container = ProviderScope.containerOf(context);
  final connectionManager = container.read(routerConnectionManagerProvider);

  final workgroups = container.read(workgroupsProvider);
  Workgroup? workgroup;

  for (final wg in workgroups) {
    if (wg.groups.any((g) => g.id == group.id)) {
      workgroup = wg;
      break;
    }
  }

  if (workgroup == null) {
    showSnackBarMsg(context, 'Workgroup not found for this group');
    return;
  }

  final groupId = int.tryParse(group.groupId);
  if (groupId == null) {
    showSnackBarMsg(context, 'Invalid group ID: ${group.groupId}');
    return;
  }

  String routerIpAddress = group.gatewayRouterIpAddress;
  if (routerIpAddress.isEmpty && workgroup.routers.isNotEmpty) {
    routerIpAddress = workgroup.routers.first.ipAddress;
  }

  if (routerIpAddress.isEmpty) {
    showSnackBarMsg(context, 'No router IP address available for this group');
    return;
  }

  final command = HelvarNetCommands.directProportionGroup(
    2, // Protocol version
    groupId,
    proportion,
    fadeTime: 700, // Default fade time
  );

  connectionManager
      .getConnection(
    routerIpAddress,
    connectionTimeout: const Duration(seconds: 5),
  )
      .then((connection) {
    if (connection.isConnected) {
      connection.sendCommand(command).then((success) {
        if (success) {
          showSnackBarMsg(context,
              'Set direct proportion $proportion for group ${group.groupId}');
        } else {
          showSnackBarMsg(context, 'Failed to send command to group');
        }
      });
    } else {
      showSnackBarMsg(context, 'Failed to establish connection to router');
    }
  }).catchError((error) {
    showSnackBarMsg(context, 'Connection error: $error');
  });
}

void performModifyProportion(
    BuildContext context, HelvarGroup group, int proportion) {
  final container = ProviderScope.containerOf(context);
  final connectionManager = container.read(routerConnectionManagerProvider);

  final workgroups = container.read(workgroupsProvider);
  Workgroup? workgroup;

  for (final wg in workgroups) {
    if (wg.groups.any((g) => g.id == group.id)) {
      workgroup = wg;
      break;
    }
  }

  if (workgroup == null) {
    showSnackBarMsg(context, 'Workgroup not found for this group');
    return;
  }

  final groupId = int.tryParse(group.groupId);
  if (groupId == null) {
    showSnackBarMsg(context, 'Invalid group ID: ${group.groupId}');
    return;
  }

  String routerIpAddress = group.gatewayRouterIpAddress;
  if (routerIpAddress.isEmpty && workgroup.routers.isNotEmpty) {
    routerIpAddress = workgroup.routers.first.ipAddress;
  }

  if (routerIpAddress.isEmpty) {
    showSnackBarMsg(context, 'No router IP address available for this group');
    return;
  }

  final command = HelvarNetCommands.modifyProportionGroup(
    2, // Protocol version
    groupId,
    proportion,
    fadeTime: 700, // Default fade time
  );

  connectionManager
      .getConnection(
    routerIpAddress,
    connectionTimeout: const Duration(seconds: 5),
  )
      .then((connection) {
    if (connection.isConnected) {
      connection.sendCommand(command).then((success) {
        if (success) {
          showSnackBarMsg(context,
              'Modified proportion by $proportion for group ${group.groupId}');
        } else {
          showSnackBarMsg(context, 'Failed to send command to group');
        }
      });
    } else {
      showSnackBarMsg(context, 'Failed to establish connection to router');
    }
  }).catchError((error) {
    showSnackBarMsg(context, 'Connection error: $error');
  });
}

void performEmergencyFunctionTest(
    BuildContext context, HelvarGroup group, Workgroup workgroup) {
  final container = ProviderScope.containerOf(context);
  final connectionManager = container.read(routerConnectionManagerProvider);

  final groupId = int.tryParse(group.groupId);
  if (groupId == null) {
    showSnackBarMsg(context, 'Invalid group ID: ${group.groupId}');
    return;
  }

  String routerIpAddress = group.gatewayRouterIpAddress;
  if (routerIpAddress.isEmpty && workgroup.routers.isNotEmpty) {
    routerIpAddress = workgroup.routers.first.ipAddress;
  }

  if (routerIpAddress.isEmpty) {
    showSnackBarMsg(context, 'No router IP address available for this group');
    return;
  }

  final command = HelvarNetCommands.emergencyFunctionTestGroup(
    2, // Protocol version
    groupId,
  );

  connectionManager
      .getConnection(
    routerIpAddress,
    connectionTimeout: const Duration(seconds: 5),
  )
      .then((connection) {
    if (connection.isConnected) {
      connection.sendCommand(command).then((success) {
        if (success) {
          showSnackBarMsg(context,
              'Started emergency function test for group ${group.groupId}');
        } else {
          showSnackBarMsg(context, 'Failed to send command to group');
        }
      });
    } else {
      showSnackBarMsg(context, 'Failed to establish connection to router');
    }
  }).catchError((error) {
    showSnackBarMsg(context, 'Connection error: $error');
  });
}

void performEmergencyDurationTest(
    BuildContext context, HelvarGroup group, Workgroup workgroup) {
  final container = ProviderScope.containerOf(context);
  final connectionManager = container.read(routerConnectionManagerProvider);

  final groupId = int.tryParse(group.groupId);
  if (groupId == null) {
    showSnackBarMsg(context, 'Invalid group ID: ${group.groupId}');
    return;
  }

  String routerIpAddress = group.gatewayRouterIpAddress;
  if (routerIpAddress.isEmpty && workgroup.routers.isNotEmpty) {
    routerIpAddress = workgroup.routers.first.ipAddress;
  }

  if (routerIpAddress.isEmpty) {
    showSnackBarMsg(context, 'No router IP address available for this group');
    return;
  }

  final command = HelvarNetCommands.emergencyDurationTestGroup(
    2, // Protocol version
    groupId,
  );

  connectionManager
      .getConnection(
    routerIpAddress,
    connectionTimeout: const Duration(seconds: 5),
  )
      .then((connection) {
    if (connection.isConnected) {
      connection.sendCommand(command).then((success) {
        if (success) {
          showSnackBarMsg(context,
              'Started emergency duration test for group ${group.groupId}');
        } else {
          showSnackBarMsg(context, 'Failed to send command to group');
        }
      });
    } else {
      showSnackBarMsg(context, 'Failed to establish connection to router');
    }
  }).catchError((error) {
    showSnackBarMsg(context, 'Connection error: $error');
  });
}

void stopEmergencyTest(
    BuildContext context, HelvarGroup group, Workgroup workgroup) {
  final container = ProviderScope.containerOf(context);
  final connectionManager = container.read(routerConnectionManagerProvider);

  final groupId = int.tryParse(group.groupId);
  if (groupId == null) {
    showSnackBarMsg(context, 'Invalid group ID: ${group.groupId}');
    return;
  }

  String routerIpAddress = group.gatewayRouterIpAddress;
  if (routerIpAddress.isEmpty && workgroup.routers.isNotEmpty) {
    routerIpAddress = workgroup.routers.first.ipAddress;
  }

  if (routerIpAddress.isEmpty) {
    showSnackBarMsg(context, 'No router IP address available for this group');
    return;
  }

  final command = HelvarNetCommands.stopEmergencyTestsGroup(
    2, // Protocol version
    groupId,
  );

  connectionManager
      .getConnection(
    routerIpAddress,
    connectionTimeout: const Duration(seconds: 5),
  )
      .then((connection) {
    if (connection.isConnected) {
      connection.sendCommand(command).then((success) {
        if (success) {
          showSnackBarMsg(
              context, 'Stopped emergency tests for group ${group.groupId}');
        } else {
          showSnackBarMsg(context, 'Failed to send command to group');
        }
      });
    } else {
      showSnackBarMsg(context, 'Failed to establish connection to router');
    }
  }).catchError((error) {
    showSnackBarMsg(context, 'Connection error: $error');
  });
}

void resetEmergencyBatteryTotalLampTime(
    BuildContext context, HelvarGroup group, Workgroup workgroup) {
  final container = ProviderScope.containerOf(context);
  final connectionManager = container.read(routerConnectionManagerProvider);

  final groupId = int.tryParse(group.groupId);
  if (groupId == null) {
    showSnackBarMsg(context, 'Invalid group ID: ${group.groupId}');
    return;
  }

  String routerIpAddress = group.gatewayRouterIpAddress;
  if (routerIpAddress.isEmpty && workgroup.routers.isNotEmpty) {
    routerIpAddress = workgroup.routers.first.ipAddress;
  }

  if (routerIpAddress.isEmpty) {
    showSnackBarMsg(context, 'No router IP address available for this group');
    return;
  }

  final command = HelvarNetCommands.resetEmergencyBatteryAndTotalLampTimeGroup(
    2, // Protocol version
    groupId,
  );

  connectionManager
      .getConnection(
    routerIpAddress,
    connectionTimeout: const Duration(seconds: 5),
  )
      .then((connection) {
    if (connection.isConnected) {
      connection.sendCommand(command).then((success) {
        if (success) {
          showSnackBarMsg(context,
              'Reset emergency battery and total lamp time for group ${group.groupId}');
        } else {
          showSnackBarMsg(context, 'Failed to send command to group');
        }
      });
    } else {
      showSnackBarMsg(context, 'Failed to establish connection to router');
    }
  }).catchError((error) {
    showSnackBarMsg(context, 'Connection error: $error');
  });
}

void refreshGroupProperties(
    BuildContext context, HelvarGroup group, Workgroup workgroup) {
  final container = ProviderScope.containerOf(context);
  final connectionManager = container.read(routerConnectionManagerProvider);

  final groupId = int.tryParse(group.groupId);
  if (groupId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invalid group ID: ${group.groupId}')),
    );
    return;
  }

  final descriptionCommand = HelvarNetCommands.queryDescriptionGroup(
    2, // Protocol version
    groupId,
  );

  String routerIpAddress = group.gatewayRouterIpAddress;
  if (routerIpAddress.isEmpty && workgroup.routers.isNotEmpty) {
    routerIpAddress = workgroup.routers.first.ipAddress;
  }

  if (routerIpAddress.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('No router IP address available for this group')),
    );
    return;
  }

  connectionManager
      .getConnection(
    routerIpAddress,
    connectionTimeout: const Duration(seconds: 5),
  )
      .then((connection) {
    if (connection.isConnected) {
      connection.sendCommandWithResponse(descriptionCommand).then((response) {
        if (response != null && response.contains('=')) {
          final parts = response.split('=');
          if (parts.length > 1) {
            final description = parts[1].replaceAll('#', '');

            final updatedGroup = group.copyWith(
              description: description,
              lastMessage: 'Group properties refreshed',
              lastMessageTime: DateTime.now(),
            );

            final workgroupsNotifier =
                container.read(workgroupsProvider.notifier);
            workgroupsNotifier.updateGroup(workgroup.id, updatedGroup);
            showSnackBarMsg(context, 'Group properties refreshed');
          }
        }
      });
    } else {
      showSnackBarMsg(context, 'Failed to establish connection to router');
    }
  }).catchError((error) {
    showSnackBarMsg(context, 'Connection error: $error');
  });
}

void performDeviceDirectLevel(
    BuildContext context, HelvarDevice device, int level) {
  final container = ProviderScope.containerOf(context);
  final connectionManager = container.read(routerConnectionManagerProvider);

  final parts = device.address.split('.');
  if (parts.length >= 4) {
    final cluster = int.parse(parts[0]);
    final router = int.parse(parts[1]);
    final routerAddress = '@$cluster.$router';

    final workgroups = container.read(workgroupsProvider);
    Workgroup? workgroup;
    HelvarRouter? helvarRouter;

    for (final wg in workgroups) {
      for (final r in wg.routers) {
        if (r.address == routerAddress) {
          workgroup = wg;
          helvarRouter = r;
          break;
        }
      }
      if (workgroup != null) break;
    }

    if (workgroup == null || helvarRouter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Router not found for this device')),
      );
      return;
    }

    final command = HelvarNetCommands.directLevelDevice(
      2,
      device.address,
      level,
      fadeTime: 700, // Default fade time
    );

    connectionManager
        .getConnection(
      helvarRouter.ipAddress,
      connectionTimeout: const Duration(seconds: 5),
    )
        .then((connection) {
      if (connection.isConnected) {
        connection.sendCommand(command).then((success) {
          if (success) {
            if (device is HelvarDriverOutputDevice) {
              device.level = level;
            }
            device.out = "Level set to $level";
            showSnackBarMsg(
                context, 'Set level to $level for device ${device.deviceId}');
          } else {
            device.out = "Failed to set level: no response";
            showSnackBarMsg(context, 'Failed to send command to device');
          }
        });
      } else {
        showSnackBarMsg(context, 'Failed to establish connection to router');
      }
    }).catchError((error) {
      showSnackBarMsg(context, 'Connection error: $error');
    });
  } else {
    showSnackBarMsg(
        context, 'Invalid device address format: ${device.address}');
  }
}

void performDeviceRecallScene(
    BuildContext context, HelvarDevice device, int sceneNumber) {
  final container = ProviderScope.containerOf(context);
  final connectionManager = container.read(routerConnectionManagerProvider);

  final parts = device.address.split('.');
  if (parts.length >= 4) {
    final cluster = int.parse(parts[0]);
    final router = int.parse(parts[1]);
    final routerAddress = '@$cluster.$router';

    final workgroups = container.read(workgroupsProvider);
    Workgroup? workgroup;
    HelvarRouter? helvarRouter;

    for (final wg in workgroups) {
      for (final r in wg.routers) {
        if (r.address == routerAddress) {
          workgroup = wg;
          helvarRouter = r;
          break;
        }
      }
      if (workgroup != null) break;
    }

    if (workgroup == null || helvarRouter == null) {
      showSnackBarMsg(context, 'Router not found for this device');
      return;
    }

    final command = HelvarNetCommands.recallSceneDevice(
      2, // Protocol version
      cluster,
      router,
      int.parse(parts[2]), // subnet
      int.parse(parts[3]), // device
      1, // Block ID (default to 1)
      sceneNumber,
      fadeTime: 700, // Default fade time in 0.1 seconds
    );

    connectionManager
        .getConnection(
      helvarRouter.ipAddress,
      connectionTimeout: const Duration(seconds: 5),
    )
        .then((connection) {
      if (connection.isConnected) {
        connection.sendCommand(command).then((success) {
          if (success) {
            device.out = "Scene $sceneNumber recalled";
            showSnackBarMsg(context,
                'Recalled scene $sceneNumber for device ${device.deviceId}');
          } else {
            device.out = "Failed to recall scene: no response";
            showSnackBarMsg(context, 'Failed to send command to device');
          }
        });
      } else {
        showSnackBarMsg(context, 'Failed to establish connection to router');
      }
    }).catchError((error) {
      showSnackBarMsg(context, 'Connection error: $error');
    });
  } else {
    showSnackBarMsg(
        context, 'Invalid device address format: ${device.address}');
  }
}

void performDeviceDirectProportion(
    BuildContext context, HelvarDevice device, int proportion) {
  final container = ProviderScope.containerOf(context);
  final connectionManager = container.read(routerConnectionManagerProvider);

  final parts = device.address.split('.');
  if (parts.length >= 4) {
    final cluster = int.parse(parts[0]);
    final router = int.parse(parts[1]);
    final routerAddress = '@$cluster.$router';

    final workgroups = container.read(workgroupsProvider);
    Workgroup? workgroup;
    HelvarRouter? helvarRouter;

    for (final wg in workgroups) {
      for (final r in wg.routers) {
        if (r.address == routerAddress) {
          workgroup = wg;
          helvarRouter = r;
          break;
        }
      }
      if (workgroup != null) break;
    }

    if (workgroup == null || helvarRouter == null) {
      showSnackBarMsg(context, 'Router not found for this device');
      return;
    }

    final command = HelvarNetCommands.directProportionDevice(
      2, // Protocol version
      cluster,
      router,
      int.parse(parts[2]), // subnet
      int.parse(parts[3]), // device
      proportion,
      fadeTime: 700, // Default fade time
    );

    connectionManager
        .getConnection(
      helvarRouter.ipAddress,
      connectionTimeout: const Duration(seconds: 5),
    )
        .then((connection) {
      if (connection.isConnected) {
        connection.sendCommand(command).then((success) {
          if (success) {
            if (device is HelvarDriverOutputDevice) {
              device.proportion = proportion;
            }
            device.out = "Proportion set to $proportion";
            showSnackBarMsg(context,
                'Set proportion to $proportion for device ${device.deviceId}');
          } else {
            device.out = "Failed to set proportion: no response";
            showSnackBarMsg(context, 'Failed to send command to device');
          }
        });
      } else {
        showSnackBarMsg(context, 'Failed to establish connection to router');
      }
    }).catchError((error) {
      showSnackBarMsg(context, 'Connection error: $error');
    });
  } else {
    showSnackBarMsg(
        context, 'Invalid device address format: ${device.address}');
  }
}

void performDeviceModifyProportion(
    BuildContext context, HelvarDevice device, int proportion) {
  final container = ProviderScope.containerOf(context);
  final connectionManager = container.read(routerConnectionManagerProvider);

  final parts = device.address.split('.');
  if (parts.length >= 4) {
    final cluster = int.parse(parts[0]);
    final router = int.parse(parts[1]);
    final routerAddress = '@$cluster.$router';

    final workgroups = container.read(workgroupsProvider);
    Workgroup? workgroup;
    HelvarRouter? helvarRouter;

    for (final wg in workgroups) {
      for (final r in wg.routers) {
        if (r.address == routerAddress) {
          workgroup = wg;
          helvarRouter = r;
          break;
        }
      }
      if (workgroup != null) break;
    }

    if (workgroup == null || helvarRouter == null) {
      showSnackBarMsg(context, 'Router not found for this device');
      return;
    }

    final command = HelvarNetCommands.modifyProportionDevice(
      2, // Protocol version
      cluster,
      router,
      int.parse(parts[2]), // subnet
      int.parse(parts[3]), // device
      proportion,
      fadeTime: 700, // Default fade time
    );

    connectionManager
        .getConnection(
      helvarRouter.ipAddress,
      connectionTimeout: const Duration(seconds: 5),
    )
        .then((connection) {
      if (connection.isConnected) {
        connection.sendCommand(command).then((success) {
          if (success) {
            device.out = "Proportion modified by $proportion";
            showSnackBarMsg(context,
                'Modified proportion by $proportion for device ${device.deviceId}');
          } else {
            device.out = "Failed to modify proportion: no response";
            showSnackBarMsg(context, 'Failed to send command to device');
          }
        });
      } else {
        showSnackBarMsg(context, 'Failed to establish connection to router');
      }
    }).catchError((error) {
      showSnackBarMsg(context, 'Connection error: $error');
    });
  } else {
    showSnackBarMsg(
        context, 'Invalid device address format: ${device.address}');
  }
}

void showGroupContextMenu(
    BuildContext context, HelvarGroup group, Workgroup workgroup) {
  final RenderBox button = context.findRenderObject() as RenderBox;
  final RenderBox overlay =
      Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;

  final buttonBottomCenter = button.localToGlobal(
    Offset(300, button.size.height / 3),
    ancestor: overlay,
  );

  final RelativeRect position = RelativeRect.fromRect(
    Rect.fromPoints(
        buttonBottomCenter, buttonBottomCenter + const Offset(1, 1)),
    Offset.zero & overlay.size,
  );

  showMenu(context: context, position: position, items: [
    PopupMenuItem(
      child: const Text('Recall Scene'),
      onTap: () => showRecallSceneDialog(context, group, workgroup),
    ),
    PopupMenuItem(
      child: const Text('Store Scene'),
      onTap: () => showStoreSceneDialog(context, group, workgroup),
    ),
    PopupMenuItem(
      child: const Text('Direct Level'),
      onTap: () => showDirectLevelDialog(context, group, workgroup),
    ),
    PopupMenuItem(
      child: const Text('Direct Proportion'),
      onTap: () => showDirectProportionDialog(context, group, workgroup),
    ),
    PopupMenuItem(
      child: const Text('Modify Proportion'),
      onTap: () => showModifyProportionDialog(context, group, workgroup),
    ),
    PopupMenuItem(
      child: const Text('Emergency Function Test'),
      onTap: () => performEmergencyFunctionTest(context, group, workgroup),
    ),
    PopupMenuItem(
      child: const Text('Emergency Duration Test'),
      onTap: () => performEmergencyDurationTest(context, group, workgroup),
    ),
    PopupMenuItem(
      child: const Text('Stop Emergency Test'),
      onTap: () => stopEmergencyTest(context, group, workgroup),
    ),
    PopupMenuItem(
      child: const Text('Reset Emergency Battery Total Lamp Time'),
      onTap: () =>
          resetEmergencyBatteryTotalLampTime(context, group, workgroup),
    ),
    PopupMenuItem(
      child: const Text('Refresh Group Properties'),
      onTap: () => refreshGroupProperties(context, group, workgroup),
    ),
  ]);
}
