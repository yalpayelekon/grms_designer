import 'package:flutter/material.dart';
import '../models/helvar_models/helvar_device.dart';

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
