import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/helvar_models/helvar_device.dart';
import '../models/helvar_models/helvar_group.dart';
import '../models/helvar_models/output_device.dart';
import '../models/helvar_models/workgroup.dart';
import '../protocol/query_commands.dart';
import '../providers/workgroups_provider.dart';
import 'dialogs/action_dialogs.dart';

void performDeviceRecallScene(
    BuildContext context, HelvarDevice device, int sceneNumber) {
  final container = ProviderScope.containerOf(context);
  final workgroupsNotifier = container.read(workgroupsProvider.notifier);

  final parts = device.address.split('.');
  if (parts.length >= 4) {
    final cluster = int.parse(parts[0]);
    final router = int.parse(parts[1]);
    final subnet = int.parse(parts[2]);
    final deviceIndex = int.parse(parts[3]);
    final routerAddress = '$cluster.$router';

    final command = HelvarNetCommands.recallSceneDevice(
      2, // Protocol version
      cluster,
      router,
      subnet,
      deviceIndex,
      1, // Block ID (default to 1)
      sceneNumber,
      fadeTime: 700, // Default fade time in 0.1 seconds
    );

    workgroupsNotifier
        .sendRouterCommand(
      _getWorkgroupIdForDevice(context, device),
      routerAddress,
      command,
    )
        .then((result) {
      if (result.success) {
        device.out = "Scene $sceneNumber recalled (${result.response})";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Recalled scene $sceneNumber for device ${device.deviceId}')),
        );
      } else {
        device.out = "Failed to recall scene: ${result.errorMessage}";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to recall scene: ${result.errorMessage}')),
        );
      }
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Invalid device address format: ${device.address}')),
    );
  }
}

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
  final workgroupsNotifier = container.read(workgroupsProvider.notifier);

  // Find the workgroup that contains this group
  final workgroups = container.read(workgroupsProvider);
  Workgroup? workgroup;

  for (final wg in workgroups) {
    if (wg.groups.any((g) => g.id == group.id)) {
      workgroup = wg;
      break;
    }
  }

  if (workgroup == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workgroup not found for this group')),
    );
    return;
  }

  final groupId = int.tryParse(group.groupId);
  if (groupId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invalid group ID: ${group.groupId}')),
    );
    return;
  }

  final command = HelvarNetCommands.recallSceneGroup(
    2, // Protocol version
    groupId,
    1, // Block ID (default to 1)
    sceneNumber,
    fadeTime: 700, // Default fade time in 0.1 seconds
  );

  // Use gateway router IP address from the group if available, otherwise try to use a router from the workgroup
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

  workgroupsNotifier
      .sendRouterCommand(
    workgroup.id,
    routerIpAddress,
    command,
  )
      .then((result) {
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Recalled scene $sceneNumber for group ${group.groupId}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to recall scene: ${result.errorMessage}')),
      );
    }
  });
}

void performDeviceDirectProportion(
    BuildContext context, HelvarDevice device, int proportion) {
  final container = ProviderScope.containerOf(context);
  final workgroupsNotifier = container.read(workgroupsProvider.notifier);

  final parts = device.address.split('.');
  if (parts.length >= 4) {
    final cluster = int.parse(parts[0]);
    final router = int.parse(parts[1]);
    final subnet = int.parse(parts[2]);
    final deviceIndex = int.parse(parts[3]);
    final routerAddress = '$cluster.$router';

    // Use HelvarNetCommands to format a proper direct proportion command
    final command = HelvarNetCommands.directProportionDevice(
      2, // Protocol version
      cluster,
      router,
      subnet,
      deviceIndex,
      proportion,
      fadeTime: 700, // Default fade time
    );

    workgroupsNotifier
        .sendRouterCommand(
      _getWorkgroupIdForDevice(context, device),
      routerAddress,
      command,
    )
        .then((result) {
      if (result.success) {
        if (device is HelvarDriverOutputDevice) {
          device.proportion = proportion;
        }
        device.out = "Proportion set to $proportion (${result.response})";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Set proportion to $proportion for device ${device.deviceId}')),
        );
      } else {
        device.out = "Failed to set proportion: ${result.errorMessage}";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to set proportion: ${result.errorMessage}')),
        );
      }
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Invalid device address format: ${device.address}')),
    );
  }
}

void performDeviceModifyProportion(
    BuildContext context, HelvarDevice device, int proportion) {
  final container = ProviderScope.containerOf(context);
  final workgroupsNotifier = container.read(workgroupsProvider.notifier);

  final parts = device.address.split('.');
  if (parts.length >= 4) {
    final cluster = int.parse(parts[0]);
    final router = int.parse(parts[1]);
    final subnet = int.parse(parts[2]);
    final deviceIndex = int.parse(parts[3]);
    final routerAddress = '$cluster.$router';

    // Use HelvarNetCommands to format a proper modify proportion command
    final command = HelvarNetCommands.modifyProportionDevice(
      2, // Protocol version
      cluster,
      router,
      subnet,
      deviceIndex,
      proportion,
      fadeTime: 700, // Default fade time
    );

    workgroupsNotifier
        .sendRouterCommand(
      _getWorkgroupIdForDevice(context, device),
      routerAddress,
      command,
    )
        .then((result) {
      if (result.success) {
        device.out = "Proportion modified by $proportion (${result.response})";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Modified proportion by $proportion for device ${device.deviceId}')),
        );
      } else {
        device.out = "Failed to modify proportion: ${result.errorMessage}";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to modify proportion: ${result.errorMessage}')),
        );
      }
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Invalid device address format: ${device.address}')),
    );
  }
}

void performStoreScene(
    BuildContext context, HelvarGroup group, int sceneNumber) {
  final container = ProviderScope.containerOf(context);
  final workgroupsNotifier = container.read(workgroupsProvider.notifier);

  // Find the workgroup that contains this group
  final workgroups = container.read(workgroupsProvider);
  Workgroup? workgroup;

  for (final wg in workgroups) {
    if (wg.groups.any((g) => g.id == group.id)) {
      workgroup = wg;
      break;
    }
  }

  if (workgroup == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workgroup not found for this group')),
    );
    return;
  }

  final groupId = int.tryParse(group.groupId);
  if (groupId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invalid group ID: ${group.groupId}')),
    );
    return;
  }

  // Format store as scene command for group
  final command = HelvarNetCommands.storeAsSceneGroup(
    2, // Protocol version
    groupId,
    1, // Block ID (default to 1)
    sceneNumber,
    forceStore: true, // Force store
  );

  // Use gateway router IP address from the group if available, otherwise try to use a router from the workgroup
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

  workgroupsNotifier
      .sendRouterCommand(
    workgroup.id,
    routerIpAddress,
    command,
  )
      .then((result) {
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Stored scene $sceneNumber for group ${group.groupId}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to store scene: ${result.errorMessage}')),
      );
    }
  });
}

void performDirectProportion(
    BuildContext context, HelvarGroup group, int proportion) {
  final container = ProviderScope.containerOf(context);
  final workgroupsNotifier = container.read(workgroupsProvider.notifier);

  // Find the workgroup that contains this group
  final workgroups = container.read(workgroupsProvider);
  Workgroup? workgroup;

  for (final wg in workgroups) {
    if (wg.groups.any((g) => g.id == group.id)) {
      workgroup = wg;
      break;
    }
  }

  if (workgroup == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workgroup not found for this group')),
    );
    return;
  }

  final groupId = int.tryParse(group.groupId);
  if (groupId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invalid group ID: ${group.groupId}')),
    );
    return;
  }

  // Format direct proportion command for group
  final command = HelvarNetCommands.directProportionGroup(
    2, // Protocol version
    groupId,
    proportion,
    fadeTime: 700, // Default fade time
  );

  // Use gateway router IP address from the group if available, otherwise try to use a router from the workgroup
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

  workgroupsNotifier
      .sendRouterCommand(
    workgroup.id,
    routerIpAddress,
    command,
  )
      .then((result) {
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Set direct proportion $proportion for group ${group.groupId}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to set proportion: ${result.errorMessage}')),
      );
    }
  });
}

void performModifyProportion(
    BuildContext context, HelvarGroup group, int proportion) {
  final container = ProviderScope.containerOf(context);
  final workgroupsNotifier = container.read(workgroupsProvider.notifier);

  // Find the workgroup that contains this group
  final workgroups = container.read(workgroupsProvider);
  Workgroup? workgroup;

  for (final wg in workgroups) {
    if (wg.groups.any((g) => g.id == group.id)) {
      workgroup = wg;
      break;
    }
  }

  if (workgroup == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workgroup not found for this group')),
    );
    return;
  }

  final groupId = int.tryParse(group.groupId);
  if (groupId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invalid group ID: ${group.groupId}')),
    );
    return;
  }

  // Format modify proportion command for group
  final command = HelvarNetCommands.modifyProportionGroup(
    2, // Protocol version
    groupId,
    proportion,
    fadeTime: 700, // Default fade time
  );

  // Use gateway router IP address from the group if available, otherwise try to use a router from the workgroup
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

  workgroupsNotifier
      .sendRouterCommand(
    workgroup.id,
    routerIpAddress,
    command,
  )
      .then((result) {
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Modified proportion by $proportion for group ${group.groupId}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to modify proportion: ${result.errorMessage}')),
      );
    }
  });
}

void performEmergencyFunctionTest(
    BuildContext context, HelvarGroup group, Workgroup workgroup) {
  final container = ProviderScope.containerOf(context);
  final workgroupsNotifier = container.read(workgroupsProvider.notifier);

  final groupId = int.tryParse(group.groupId);
  if (groupId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invalid group ID: ${group.groupId}')),
    );
    return;
  }

  // Format emergency function test command for group
  final command = HelvarNetCommands.emergencyFunctionTestGroup(
    2, // Protocol version
    groupId,
  );

  // Use gateway router IP address from the group if available, otherwise try to use a router from the workgroup
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

  workgroupsNotifier
      .sendRouterCommand(
    workgroup.id,
    routerIpAddress,
    command,
  )
      .then((result) {
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Started emergency function test for group ${group.groupId}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to start emergency test: ${result.errorMessage}')),
      );
    }
  });
}

void performEmergencyDurationTest(
    BuildContext context, HelvarGroup group, Workgroup workgroup) {
  final container = ProviderScope.containerOf(context);
  final workgroupsNotifier = container.read(workgroupsProvider.notifier);

  final groupId = int.tryParse(group.groupId);
  if (groupId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invalid group ID: ${group.groupId}')),
    );
    return;
  }

  // Format emergency duration test command for group
  final command = HelvarNetCommands.emergencyDurationTestGroup(
    2, // Protocol version
    groupId,
  );

  // Use gateway router IP address from the group if available, otherwise try to use a router from the workgroup
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

  workgroupsNotifier
      .sendRouterCommand(
    workgroup.id,
    routerIpAddress,
    command,
  )
      .then((result) {
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Started emergency duration test for group ${group.groupId}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to start emergency test: ${result.errorMessage}')),
      );
    }
  });
}

void stopEmergencyTest(
    BuildContext context, HelvarGroup group, Workgroup workgroup) {
  final container = ProviderScope.containerOf(context);
  final workgroupsNotifier = container.read(workgroupsProvider.notifier);

  final groupId = int.tryParse(group.groupId);
  if (groupId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invalid group ID: ${group.groupId}')),
    );
    return;
  }

  // Format stop emergency tests command for group
  final command = HelvarNetCommands.stopEmergencyTestsGroup(
    2, // Protocol version
    groupId,
  );

  // Use gateway router IP address from the group if available, otherwise try to use a router from the workgroup
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

  workgroupsNotifier
      .sendRouterCommand(
    workgroup.id,
    routerIpAddress,
    command,
  )
      .then((result) {
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Stopped emergency tests for group ${group.groupId}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to stop emergency tests: ${result.errorMessage}')),
      );
    }
  });
}

void resetEmergencyBatteryTotalLampTime(
    BuildContext context, HelvarGroup group, Workgroup workgroup) {
  final container = ProviderScope.containerOf(context);
  final workgroupsNotifier = container.read(workgroupsProvider.notifier);

  final groupId = int.tryParse(group.groupId);
  if (groupId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invalid group ID: ${group.groupId}')),
    );
    return;
  }

  // Format reset emergency battery command for group
  final command = HelvarNetCommands.resetEmergencyBatteryAndTotalLampTimeGroup(
    2, // Protocol version
    groupId,
  );

  // Use gateway router IP address from the group if available, otherwise try to use a router from the workgroup
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

  workgroupsNotifier
      .sendRouterCommand(
    workgroup.id,
    routerIpAddress,
    command,
  )
      .then((result) {
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Reset emergency battery and total lamp time for group ${group.groupId}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Failed to reset emergency battery: ${result.errorMessage}')),
      );
    }
  });
}

void refreshGroupProperties(
    BuildContext context, HelvarGroup group, Workgroup workgroup) {
  final container = ProviderScope.containerOf(context);
  final workgroupsNotifier = container.read(workgroupsProvider.notifier);

  final groupId = int.tryParse(group.groupId);
  if (groupId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invalid group ID: ${group.groupId}')),
    );
    return;
  }

  // Format query commands for group properties
  final descriptionCommand = HelvarNetCommands.queryDescriptionGroup(
    2, // Protocol version
    groupId,
  );

  // Use gateway router IP address from the group if available, otherwise try to use a router from the workgroup
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

  // Send a query for the group description
  workgroupsNotifier
      .sendRouterCommand(
    workgroup.id,
    routerIpAddress,
    descriptionCommand,
  )
      .then((result) {
    if (result.success) {
      // Parse the description from the response
      final response = result.response;
      if (response != null && response.contains('=')) {
        final parts = response.split('=');
        if (parts.length > 1) {
          final description = parts[1].replaceAll('#', '');

          // Update the group description
          final updatedGroup = group.copyWith(
            description: description,
            lastMessage: 'Group properties refreshed',
            lastMessageTime: DateTime.now(),
          );

          // Save the updated group
          workgroupsNotifier.updateGroup(workgroup.id, updatedGroup);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Group properties refreshed')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to refresh properties: ${result.errorMessage}')),
      );
    }
  });
}

void performDeviceDirectLevel(
    BuildContext context, HelvarDevice device, int level) {
  final container = ProviderScope.containerOf(context);
  final workgroupsNotifier = container.read(workgroupsProvider.notifier);

  final parts = device.address.split('.');
  if (parts.length >= 4) {
    final cluster = int.parse(parts[0]);
    final router = int.parse(parts[1]);
    final routerAddress = '@$cluster.$router';

    String deviceAddress = device.address;
    if (deviceAddress.startsWith('@')) {
      deviceAddress = deviceAddress.substring(1);
    }

    final command = '>V:1,C:14,L:$level,F:700,@$deviceAddress#';

    workgroupsNotifier
        .sendRouterCommand(
      _getWorkgroupIdForDevice(context, device),
      routerAddress,
      command,
    )
        .then((result) {
      if (result.success) {
        if (device is HelvarDriverOutputDevice) {
          device.level = level;
        }
        device.out = "Level set to $level (${result.response})";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Set level to $level for device ${device.deviceId}')),
        );
      } else {
        device.out = "Failed to set level: ${result.errorMessage}";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to set level: ${result.errorMessage}')),
        );
      }
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Invalid device address format: ${device.address}')),
    );
  }
}

void performDirectLevel(BuildContext context, HelvarGroup group, int level) {
  final container = ProviderScope.containerOf(context);
  final workgroupsNotifier = container.read(workgroupsProvider.notifier);

  // Find the workgroup that contains this group
  final workgroups = container.read(workgroupsProvider);
  Workgroup? workgroup;

  for (final wg in workgroups) {
    if (wg.groups.any((g) => g.id == group.id)) {
      workgroup = wg;
      break;
    }
  }

  if (workgroup == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workgroup not found for this group')),
    );
    return;
  }

  final groupId = int.tryParse(group.groupId);
  if (groupId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Invalid group ID: ${group.groupId}')),
    );
    return;
  }

  // Format direct level command for group
  final command = HelvarNetCommands.directLevelGroup(
    2, // Protocol version
    groupId,
    level,
    fadeTime: 700, // Default fade time in 0.1 seconds
  );

  // Use gateway router IP address from the group if available, otherwise try to use a router from the workgroup
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

  workgroupsNotifier
      .sendRouterCommand(
    workgroup.id,
    routerIpAddress,
    command,
  )
      .then((result) {
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Set direct level $level for group ${group.groupId}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set level: ${result.errorMessage}')),
      );
    }
  });
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
