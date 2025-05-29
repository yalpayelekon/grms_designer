import 'package:flutter/material.dart';
import 'package:grms_designer/models/helvar_models/input_device.dart';
import 'package:grms_designer/models/helvar_models/output_device.dart';

Color getOutputPointValueColor(OutputPoint outputPoint) {
  if (outputPoint.pointType == 'boolean') {
    final value = outputPoint.value as bool? ?? false;
    return value ? Colors.green : Colors.red;
  } else {
    final value = (outputPoint.value as num?)?.toDouble() ?? 0.0;
    if (value == 0) return Colors.grey;
    return Colors.blue;
  }
}

String formatOutputPointValue(OutputPoint outputPoint) {
  if (outputPoint.pointType == 'boolean') {
    final value = outputPoint.value as bool? ?? false;
    return value ? 'true' : 'false';
  } else {
    final value = (outputPoint.value as num?)?.toDouble() ?? 0.0;
    if (outputPoint.pointId == 5) {
      return '${value.toStringAsFixed(0)}%';
    } else if (outputPoint.pointId == 6) {
      return '${value.toStringAsFixed(1)}W';
    }
    return value.toStringAsFixed(1);
  }
}

IconData getButtonPointIcon(ButtonPoint buttonPoint) {
  if (buttonPoint.function.contains('Status') ||
      buttonPoint.name.contains('Missing')) {
    return Icons.info_outline;
  } else if (buttonPoint.function.contains('IR')) {
    return Icons.settings_remote;
  } else {
    return Icons.touch_app;
  }
}

String getButtonPointDisplayName(ButtonPoint buttonPoint) {
  return buttonPoint.name.split('_').last;
}

IconData getOutputPointIcon(OutputPoint outputPoint) {
  switch (outputPoint.pointId) {
    case 1:
      return Icons.device_hub;
    case 2:
      return Icons.lightbulb_outline;
    case 3:
      return Icons.help_outline;
    case 4:
      return Icons.warning;
    case 5:
      return Icons.tune;
    case 6:
      return Icons.power;
    default:
      return Icons.circle;
  }
}
