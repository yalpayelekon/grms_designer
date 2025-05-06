import 'package:flutter/material.dart';

import 'canvas_item.dart';

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
    final portList = startItem.ports.where((p) => !p.isInput).toList();
    final index = portList.indexWhere((p) => p.id == startPortId);
    final portCount = portList.length;
    final verticalSpacing = startItem.size.height / (portCount + 1);
    final verticalPosition =
        startItem.position.dy + verticalSpacing * (index + 1);
    final startPoint =
        Offset(startItem.position.dx + startItem.size.width, verticalPosition);
    final path = Path();
    path.moveTo(startPoint.dx, startPoint.dy);
    final controlPoint1 = Offset(
        startPoint.dx + (endPoint.dx - startPoint.dx) * 0.4, startPoint.dy);
    final controlPoint2 = Offset(
        startPoint.dx + (endPoint.dx - startPoint.dx) * 0.6, endPoint.dy);

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
