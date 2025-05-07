import 'package:flutter/material.dart';
import '../models/canvas_item.dart';
import '../utils/general_ui.dart';

class DraggingLinkPainter extends CustomPainter {
  final CanvasItem startItem;
  final String startPortId;
  final Offset endPoint;

  DraggingLinkPainter({
    required this.startItem,
    required this.startPortId,
    required this.endPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final port = startItem.getPort(startPortId);
    if (port == null) return;

    final start = getPortPosition(startItem, port, false);

    final path = Path();
    path.moveTo(start.dx, start.dy);

    // Create a cubic bezier curve path for the dragging link
    final controlPoint1 =
        Offset(start.dx + (endPoint.dx - start.dx) * 0.4, start.dy);
    final controlPoint2 =
        Offset(start.dx + (endPoint.dx - start.dx) * 0.6, endPoint.dy);

    path.cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      endPoint.dx,
      endPoint.dy,
    );

    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(endPoint, 5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
