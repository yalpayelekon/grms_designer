import 'package:flutter/material.dart';
import '../models/canvas_item.dart';
import '../models/helvar_models/helvar_device.dart';
import '../models/link.dart';

IconData getDeviceIcon(HelvarDevice device) {
  if (device.isButtonDevice) {
    return Icons.touch_app;
  } else if (device.isMultisensor) {
    return Icons.sensors;
  } else if (device.helvarType == 'emergency') {
    return Icons.emergency;
  } else if (device.helvarType == 'output') {
    return Icons.lightbulb;
  } else {
    return Icons.device_unknown;
  }
}

String formatDateTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) {
    return 'Just now';
  } else if (difference.inHours < 1) {
    return '${difference.inMinutes}m ago';
  } else if (difference.inDays < 1) {
    return '${difference.inHours}h ago';
  } else {
    return '${difference.inDays}d ago';
  }
}

Offset getPortPosition(CanvasItem item, Port? port, bool isInput) {
  if (port == null) {
    return isInput
        ? Offset(item.position.dx, item.position.dy + item.size.height / 2)
        : Offset(item.position.dx + item.size.width,
            item.position.dy + item.size.height / 2);
  }

  final portList = isInput
      ? item.ports.where((p) => p.isInput).toList()
      : item.ports.where((p) => !p.isInput).toList();

  final index = portList.indexWhere((p) => p.id == port.id);
  final portCount = portList.length;

  final verticalSpacing = item.size.height / (portCount + 1);
  final verticalPosition = item.position.dy + verticalSpacing * (index + 1);

  final horizontalPosition =
      isInput ? item.position.dx : item.position.dx + item.size.width;

  return Offset(horizontalPosition, verticalPosition);
}
