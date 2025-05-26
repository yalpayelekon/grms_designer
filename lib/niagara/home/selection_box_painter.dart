import 'package:flutter/material.dart';

class SelectionBoxPainter extends CustomPainter {
  final Offset? start;
  final Offset? end;

  SelectionBoxPainter({this.start, this.end});

  @override
  void paint(Canvas canvas, Size size) {
    if (start == null || end == null) return;

    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.2 * 255)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rect = Rect.fromPoints(start!, end!);
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(SelectionBoxPainter oldDelegate) {
    return oldDelegate.start != start || oldDelegate.end != end;
  }
}
