import 'package:flutter/material.dart';

import '../../models/helvar_models/helvar_device.dart';
import '../../utils/general_ui.dart';
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
        buttonBottomCenter, buttonBottomCenter + const Offset(1, 1)),
    Offset.zero & overlay.size,
  );

  final List<PopupMenuEntry<String>> menuItems = [];

  menuItems.add(
    const PopupMenuItem(
      value: 'clear_result',
      child: Text('Clear Result'),
    ),
  );

  if (device.helvarType == 'output') {
    menuItems.addAll([
      const PopupMenuItem(
        value: 'recall_scene',
        child: Text('Recall Scene'),
      ),
      const PopupMenuItem(
        value: 'direct_level',
        child: Text('Direct Level'),
      ),
      const PopupMenuItem(
        value: 'direct_proportion',
        child: Text('Direct Proportion'),
      ),
      const PopupMenuItem(
        value: 'modify_proportion',
        child: Text('Modify Proportion'),
      ),
    ]);
  }

  showMenu<String>(context: context, position: position, items: menuItems)
      .then((String? value) {
    if (value == null) return;

    switch (value) {
      case 'clear_result':
        _clearDeviceResult(context, device);
        break;
      case 'recall_scene':
        showDeviceRecallSceneDialog(context, device);
        break;
      case 'direct_level':
        showDeviceDirectLevelDialog(context, device);
        break;
      case 'direct_proportion':
        showDeviceDirectProportionDialog(context, device);
        break;
      case 'modify_proportion':
        showDeviceModifyProportionDialog(context, device);
        break;
    }
  });
}

void _clearDeviceResult(BuildContext context, HelvarDevice device) {
  device.clearResult();
  showSnackBarMsg(context, 'Cleared result for device ${device.deviceId}');
}
