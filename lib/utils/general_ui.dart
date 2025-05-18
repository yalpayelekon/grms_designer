import 'package:flutter/material.dart';
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

void showSnackBarMsg(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

Color getPortColor(PortType type) {
  switch (type) {
    case PortType.boolean:
      return Colors.green;
    case PortType.number:
      return Colors.blue;
    case PortType.string:
      return Colors.orange;
    case PortType.any:
    default:
      return Colors.purple;
  }
}

const Color inputPortColor = Colors.blue;
const Color outputPortColor = Colors.green;

Offset evaluateCubic(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
  final u = 1 - t;
  final tt = t * t;
  final uu = u * u;
  final uuu = uu * u;
  final ttt = tt * t;

  var result = p0 * uuu;
  result += p1 * 3 * uu * t;
  result += p2 * 3 * u * tt;
  result += p3 * ttt;

  return result;
}
