import '../models/canvas_item.dart';
import '../models/link.dart';
import 'package:flutter/material.dart';

class LinkPainter extends CustomPainter {
  final List<Link> links;
  final List<CanvasItem> items;
  final Function(String) onLinkSelected;

  LinkPainter({
    required this.links,
    required this.items,
    required this.onLinkSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final link in links) {
      // Find source and target items
      final sourceItem =
          items.firstWhere((item) => item.id == link.sourceItemId);
      final targetItem =
          items.firstWhere((item) => item.id == link.targetItemId);

      // Find port positions
      final sourcePort = sourceItem.getPort(link.sourcePortId);
      final targetPort = targetItem.getPort(link.targetPortId);

      // Calculate start and end points
      final start = _getPortPosition(sourceItem, sourcePort!, false);
      final end = _getPortPosition(targetItem, targetPort!, true);

      // Draw the link with a bezier curve
      final paint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(start.dx, start.dy);

      // Control points for the curve
      final controlPoint1 =
          Offset(start.dx + (end.dx - start.dx) * 0.4, start.dy);
      final controlPoint2 =
          Offset(start.dx + (end.dx - start.dx) * 0.6, end.dy);

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        end.dx,
        end.dy,
      );

      canvas.drawPath(path, paint);
    }
  }

  Offset _getPortPosition(CanvasItem item, Port? port, bool isInput) {
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

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
