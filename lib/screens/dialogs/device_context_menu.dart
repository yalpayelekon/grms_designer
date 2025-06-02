import 'package:flutter/material.dart';
import 'package:grms_designer/utils/ui/ui_helpers.dart';

import '../../models/helvar_models/device_action.dart';
import '../../models/helvar_models/helvar_device.dart';
import 'action_dialogs.dart';

void showDeviceContextMenu(BuildContext context, HelvarDevice device) {
  final RenderBox button = context.findRenderObject() as RenderBox;
  final RenderBox overlay =
      Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;

  final buttonBottomCenter = button.localToGlobal(
    Offset(300, button.size.height / 3),
    ancestor: overlay,
  );

  final RelativeRect position = RelativeRect.fromRect(
    Rect.fromPoints(
      buttonBottomCenter,
      buttonBottomCenter + const Offset(1, 1),
    ),
    Offset.zero & overlay.size,
  );

  final List<PopupMenuEntry<DeviceAction>> menuItems = [];

  menuItems.add(
    PopupMenuItem(
      value: DeviceAction.clearResult,
      child: Text(DeviceAction.clearResult.displayName),
    ),
  );

  if (device.helvarType == 'output') {
    menuItems.addAll([
      PopupMenuItem(
        value: DeviceAction.recallScene,
        child: Text(DeviceAction.recallScene.displayName),
      ),
      PopupMenuItem(
        value: DeviceAction.directLevel,
        child: Text(DeviceAction.directLevel.displayName),
      ),
      PopupMenuItem(
        value: DeviceAction.directProportion,
        child: Text(DeviceAction.directProportion.displayName),
      ),
      PopupMenuItem(
        value: DeviceAction.modifyProportion,
        child: Text(DeviceAction.modifyProportion.displayName),
      ),
    ]);
  } else if (device.helvarType == 'emergency') {
    menuItems.addAll([
      PopupMenuItem(
        value: DeviceAction.emergencyFunctionTest,
        child: Text(DeviceAction.emergencyFunctionTest.displayName),
      ),
      PopupMenuItem(
        value: DeviceAction.emergencyDurationTest,
        child: Text(DeviceAction.emergencyDurationTest.displayName),
      ),
      PopupMenuItem(
        value: DeviceAction.stopEmergencyTest,
        child: Text(DeviceAction.stopEmergencyTest.displayName),
      ),
      PopupMenuItem(
        value: DeviceAction.resetEmergencyBattery,
        child: Text(DeviceAction.resetEmergencyBattery.displayName),
      ),
    ]);
  }

  showMenu<DeviceAction>(
    context: context,
    position: position,
    items: menuItems,
  ).then((DeviceAction? value) {
    if (value == null) return;

    switch (value) {
      case DeviceAction.clearResult:
        _clearDeviceResult(context, device);
        break;
      case DeviceAction.recallScene:
        showDeviceRecallSceneDialog(context, device);
        break;
      case DeviceAction.directLevel:
        showDeviceDirectLevelDialog(context, device);
        break;
      case DeviceAction.directProportion:
        showDeviceDirectProportionDialog(context, device);
        break;
      case DeviceAction.modifyProportion:
        showDeviceModifyProportionDialog(context, device);
        break;
      case DeviceAction.emergencyFunctionTest:
        // TODO: Add implementation for emergency function test
        break;
      case DeviceAction.emergencyDurationTest:
        // Add implementation for emergency duration test
        break;
      case DeviceAction.stopEmergencyTest:
        // Add implementation for stop emergency test
        break;
      case DeviceAction.resetEmergencyBattery:
        // Add implementation for reset emergency battery
        break;
    }
  });
}

void _clearDeviceResult(BuildContext context, HelvarDevice device) {
  device.clearResult();
  showSnackBarMsg(context, 'Cleared result for device ${device.deviceId}');
}
