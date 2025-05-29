import 'package:flutter/material.dart';
import 'package:grms_designer/models/helvar_models/helvar_device.dart';
import 'package:grms_designer/utils/device_icons.dart';

Widget buildDraggable(
  String label,
  HelvarDevice? device,
  BuildContext context,
) {
  return Draggable<Map<String, dynamic>>(
    data: {
      "componentType": label,
      "device": device,
      "deviceData": device != null
          ? {
              "deviceId": device.deviceId,
              "deviceAddress": device.address,
              "deviceType": device.helvarType,
              "description": device.description,
            }
          : null,
    },
    feedback: Material(
      elevation: 4.0,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.blue[100],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            getDeviceIconWidget(device),
            const SizedBox(width: 8.0),
            Text(label),
          ],
        ),
      ),
    ),
    childWhenDragging: Row(
      children: [
        getDeviceIconWidget(device, size: 20.0),
        const SizedBox(width: 8.0),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    ),
    child: Row(
      children: [
        getDeviceIconWidget(device),
        const SizedBox(width: 8.0),
        Text(label),
      ],
    ),
  );
}
