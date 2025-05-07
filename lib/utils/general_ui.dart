import 'package:flutter/material.dart';
import '../models/canvas_item.dart';
import '../models/helvar_models/helvar_device.dart';
import '../models/link.dart';
import '../models/wiresheet.dart';
import '../providers/wiresheets_provider.dart';

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

void updateCanvasSize(Wiresheet wiresheet, ref) {
  if (wiresheet.canvasItems.isEmpty) return;

  double minX = double.infinity;
  double minY = double.infinity;
  double maxX = 0;
  double maxY = 0;

  for (var item in wiresheet.canvasItems) {
    final rightEdge = item.position.dx + item.size.width;
    final bottomEdge = item.position.dy + item.size.height;

    minX = minX > item.position.dx ? item.position.dx : minX;
    minY = minY > item.position.dy ? item.position.dy : minY;
    maxX = maxX < rightEdge ? rightEdge : maxX;
    maxY = maxY < bottomEdge ? bottomEdge : maxY;
  }

  const padding = 100.0;

  bool needsUpdate = false;
  Size newCanvasSize = wiresheet.canvasSize;
  Offset newCanvasOffset = wiresheet.canvasOffset;

  if (minX < padding) {
    double extraWidth = padding - minX;
    newCanvasSize =
        Size(wiresheet.canvasSize.width + extraWidth, newCanvasSize.height);
    newCanvasOffset = Offset(
      wiresheet.canvasOffset.dx - extraWidth,
      newCanvasOffset.dy,
    );
    final updatedItems = List<CanvasItem>.from(wiresheet.canvasItems);
    for (int i = 0; i < updatedItems.length; i++) {
      final item = updatedItems[i];
      final updatedItem = item.copyWith(
        position: Offset(item.position.dx + extraWidth, item.position.dy),
      );
      ref.read(wiresheetsProvider.notifier).updateWiresheetItem(
            wiresheet.id,
            i,
            updatedItem,
          );
    }

    needsUpdate = true;
  }

  if (minY < padding) {
    double extraHeight = padding - minY;
    newCanvasSize = Size(
      newCanvasSize.width,
      wiresheet.canvasSize.height + extraHeight,
    );
    newCanvasOffset = Offset(
      newCanvasOffset.dx,
      wiresheet.canvasOffset.dy - extraHeight,
    );
    final updatedItems = List<CanvasItem>.from(wiresheet.canvasItems);
    for (int i = 0; i < updatedItems.length; i++) {
      final item = updatedItems[i];
      final updatedItem = item.copyWith(
        position: Offset(item.position.dx, item.position.dy + extraHeight),
      );
      ref.read(wiresheetsProvider.notifier).updateWiresheetItem(
            wiresheet.id,
            i,
            updatedItem,
          );
    }

    needsUpdate = true;
  }

  if (maxX > wiresheet.canvasSize.width - padding) {
    double extraWidth = maxX - (wiresheet.canvasSize.width - padding);
    newCanvasSize =
        Size(wiresheet.canvasSize.width + extraWidth, newCanvasSize.height);
    needsUpdate = true;
  }

  if (maxY > wiresheet.canvasSize.height - padding) {
    double extraHeight = maxY - (wiresheet.canvasSize.height - padding);
    newCanvasSize = Size(
      newCanvasSize.width,
      wiresheet.canvasSize.height + extraHeight,
    );
    needsUpdate = true;
  }

  if (needsUpdate) {
    ref.read(wiresheetsProvider.notifier).updateCanvasSize(
          wiresheet.id,
          newCanvasSize,
        );

    ref.read(wiresheetsProvider.notifier).updateCanvasOffset(
          wiresheet.id,
          newCanvasOffset,
        );
  }
}

Widget getPositionDetail(
    CanvasItem item, String wiresheetId, int selectedItemIndex, ref) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'X Position',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(
                text: item.position.dx.toStringAsFixed(0),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final dx = double.tryParse(value) ?? item.position.dx;
                final updatedItem = item.copyWith(
                  position: Offset(dx, item.position.dy),
                );
                ref.read(wiresheetsProvider.notifier).updateWiresheetItem(
                      wiresheetId,
                      selectedItemIndex,
                      updatedItem,
                    );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Y Position',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(
                text: item.position.dy.toStringAsFixed(0),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final dy = double.tryParse(value) ?? item.position.dy;
                final updatedItem = item.copyWith(
                  position: Offset(item.position.dx, dy),
                );
                ref.read(wiresheetsProvider.notifier).updateWiresheetItem(
                      wiresheetId,
                      selectedItemIndex,
                      updatedItem,
                    );
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Width',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(
                text: item.size.width.toStringAsFixed(0),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final width = double.tryParse(value) ?? item.size.width;
                final updatedItem = item.copyWith(
                  size: Size(width, item.size.height),
                );
                ref.read(wiresheetsProvider.notifier).updateWiresheetItem(
                      wiresheetId,
                      selectedItemIndex,
                      updatedItem,
                    );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Height',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(
                text: item.size.height.toStringAsFixed(0),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final height = double.tryParse(value) ?? item.size.height;
                final updatedItem = item.copyWith(
                  size: Size(item.size.width, height),
                );
                ref.read(wiresheetsProvider.notifier).updateWiresheetItem(
                      wiresheetId,
                      selectedItemIndex,
                      updatedItem,
                    );
              },
            ),
          ),
        ],
      ),
    ],
  );
}

void showSnackBarMsg(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
