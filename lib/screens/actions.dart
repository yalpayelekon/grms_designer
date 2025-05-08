import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/helvar_models/helvar_device.dart';
import '../models/helvar_models/helvar_group.dart';
import '../models/helvar_models/workgroup.dart';
import '../providers/workgroups_provider.dart';
import 'dialogs/action_dialogs.dart';

String getWorkgroupIdForDevice(BuildContext context, HelvarDevice device) {
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
    BuildContext context, HelvarGroup group, int sceneNumber) {}

void performStoreScene(
    BuildContext context, HelvarGroup group, int sceneNumber) {}

void performDirectLevel(BuildContext context, HelvarGroup group, int level) {}

void performDirectProportion(
    BuildContext context, HelvarGroup group, int proportion) {}

void performModifyProportion(
    BuildContext context, HelvarGroup group, int proportion) {}

void performEmergencyFunctionTest(
    BuildContext context, HelvarGroup group, Workgroup workgroup) {}

void performEmergencyDurationTest(
    BuildContext context, HelvarGroup group, Workgroup workgroup) {}

void stopEmergencyTest(
    BuildContext context, HelvarGroup group, Workgroup workgroup) {}

void resetEmergencyBatteryTotalLampTime(
    BuildContext context, HelvarGroup group, Workgroup workgroup) {}

void refreshGroupProperties(
    BuildContext context, HelvarGroup group, Workgroup workgroup) {}

void performDeviceDirectLevel(
    BuildContext context, HelvarDevice device, int level) {}

void performDeviceRecallScene(
    BuildContext context, HelvarDevice device, int sceneNumber) {}

void performDeviceDirectProportion(
    BuildContext context, HelvarDevice device, int proportion) {}

void performDeviceModifyProportion(
    BuildContext context, HelvarDevice device, int proportion) {}

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
