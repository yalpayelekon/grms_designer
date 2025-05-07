import 'package:flutter/material.dart';

import '../models/link.dart';

class PortWidget extends StatelessWidget {
  final Port port;
  final VoidCallback onTap;
  final bool isConnected;

  const PortWidget({
    super.key,
    required this.port,
    required this.onTap,
    this.isConnected = false,
  });

  @override
  Widget build(BuildContext context) {
    Color portColor;
    switch (port.type) {
      case PortType.boolean:
        portColor = Colors.green;
        break;
      case PortType.number:
        portColor = Colors.blue;
        break;
      case PortType.string:
        portColor = Colors.orange;
        break;
      case PortType.any:
      default:
        portColor = Colors.purple;
    }

    return Tooltip(
      message: "${port.name} (${port.type.toString().split('.').last})",
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isConnected ? portColor.withOpacity(0.7) : Colors.white,
            border: Border.all(color: portColor, width: 2),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
