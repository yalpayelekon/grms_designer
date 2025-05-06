import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/helvar_models/helvar_device.dart';
import '../models/helvar_models/helvar_group.dart';
import '../models/helvar_models/output_device.dart';
import '../models/helvar_models/workgroup.dart';
import '../providers/workgroups_provider.dart';
import 'dialogs/action_dialogs.dart';

void performDeviceRecallScene(
    BuildContext context, HelvarDevice device, int sceneNumber) {
  final container = ProviderScope.containerOf(context);
  final workgroupsNotifier = container.read(workgroupsProvider.notifier);

  final parts = device.address.split('.');
  if (parts.length >= 2) {
    final cluster = parts[0];
    final router = parts[1];
    final routerAddress = '$cluster.$router';

    final command = '>V:2,C:12,B:1,S:$sceneNumber,F:700,@${device.address}#';

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
  // TODO: Here we would use the Helvar protocol implementation to recall a scene
  // For now, just show a snackbar
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
        content:
            Text('Recalling scene $sceneNumber for group ${group.groupId}')),
  );
}

void performDeviceDirectProportion(
    BuildContext context, HelvarDevice device, int proportion) {
  if (device is HelvarDriverOutputDevice) {
    device.directProportion('$proportion,700');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Set proportion to $proportion for device ${device.deviceId}')),
    );
  }
}

void performDeviceDirectLevel(
    BuildContext context, HelvarDevice device, int level) {
  if (device is HelvarDriverOutputDevice) {
    device.directLevel('$level,700');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Set level to $level for device ${device.deviceId}')),
    );
  }
}

void performStoreScene(
    BuildContext context, HelvarGroup group, int sceneNumber) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
        content: Text('Storing scene $sceneNumber for group ${group.groupId}')),
  );
}

void performDirectLevel(BuildContext context, HelvarGroup group, int level) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
        content:
            Text('Setting direct level $level for group ${group.groupId}')),
  );
}

void performDirectProportion(
    BuildContext context, HelvarGroup group, int proportion) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
        content: Text(
            'Setting direct proportion $proportion for group ${group.groupId}')),
  );
}

void performModifyProportion(
    BuildContext context, HelvarGroup group, int proportion) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
        content: Text(
            'Modifying proportion by $proportion for group ${group.groupId}')),
  );
}

void performEmergencyFunctionTest(
    BuildContext context, HelvarGroup group, Workgroup workgroup) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
        content: Text('Emergency Function Test for group ${group.groupId}')),
  );
}

void performEmergencyDurationTest(
    BuildContext context, HelvarGroup group, Workgroup workgroup) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
        content: Text('Emergency Duration Test for group ${group.groupId}')),
  );
}

void stopEmergencyTest(
    BuildContext context, HelvarGroup group, Workgroup workgroup) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
        content: Text('Stopping Emergency Test for group ${group.groupId}')),
  );
}

void resetEmergencyBatteryTotalLampTime(
    BuildContext context, HelvarGroup group, Workgroup workgroup) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
        content: Text(
            'Reset Emergency Battery Total Lamp Time for group ${group.groupId}')),
  );
}

void refreshGroupProperties(
    BuildContext context, HelvarGroup group, Workgroup workgroup) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Refreshing properties for group ${group.groupId}')),
  );
}

void performDeviceModifyProportion(
    BuildContext context, HelvarDevice device, int proportion) {
  if (device is HelvarDriverOutputDevice) {
    device.modifyProportion('$proportion,700');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Modified proportion by $proportion for device ${device.deviceId}')),
    );
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
