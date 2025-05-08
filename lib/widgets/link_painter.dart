import 'dart:math';
import 'package:flutter/material.dart';
import 'package:grms_designer/utils/logger.dart';
import '../models/canvas_item.dart';
import '../models/link.dart';
import '../utils/general_ui.dart';

class LinkPainter extends CustomPainter {
  final List<Link> links;
  final List<CanvasItem> items;
  final Function(String) onLinkSelected;
  final String? hoveredLinkId;
  final String? selectedLinkId;

  LinkPainter({
    required this.links,
    required this.items,
    required this.onLinkSelected,
    this.hoveredLinkId,
    this.selectedLinkId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final link in links) {
      final isHovered = link.id == hoveredLinkId;
      final isSelected = link.id == selectedLinkId;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered || isSelected ? 3 : 2;

      if (isSelected) {
        paint.color = Colors.orange;
      } else if (isHovered) {
        paint.color = Colors.lightBlue;
      } else {
        paint.color = Colors.blue.withOpacity(0.8);
      }

      try {
        final sourceItem =
            items.firstWhere((item) => item.id == link.sourceItemId);
        final targetItem =
            items.firstWhere((item) => item.id == link.targetItemId);

        final sourcePort = sourceItem.getPort(link.sourcePortId);
        final targetPort = targetItem.getPort(link.targetPortId);

        if (sourcePort == null || targetPort == null) continue;

        final start = getPortPosition(sourceItem, sourcePort, false);
        final end = getPortPosition(targetItem, targetPort, true);

        final path = Path();
        path.moveTo(start.dx, start.dy);

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

        if (link.type == LinkType.dataFlow) {
          _drawArrow(canvas, path, paint.color);
        }
      } catch (e) {
        logError("Could not draw link: ${e.toString()}");
        continue;
      }
    }
  }

  void _drawArrow(Canvas canvas, Path path, Color color) {
    final pathMetrics = path.computeMetrics().toList();
    if (pathMetrics.isEmpty) return;

    final pathMetric = pathMetrics.first;
    final arrowPosition = pathMetric.length * 0.9; // 90% along the path

    final tangent = pathMetric.getTangentForOffset(arrowPosition);
    if (tangent == null) return;

    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final arrowPath = Path();
    final tipPoint = tangent.position;
    final angle = tangent.angle;

    const arrowSize = 8.0;
    final arrowLeft = Offset(
      tipPoint.dx - arrowSize * cos(angle - pi / 6),
      tipPoint.dy - arrowSize * sin(angle - pi / 6),
    );
    final arrowRight = Offset(
      tipPoint.dx - arrowSize * cos(angle + pi / 6),
      tipPoint.dy - arrowSize * sin(angle + pi / 6),
    );

    arrowPath.moveTo(tipPoint.dx, tipPoint.dy);
    arrowPath.lineTo(arrowLeft.dx, arrowLeft.dy);
    arrowPath.lineTo(arrowRight.dx, arrowRight.dy);
    arrowPath.close();

    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant LinkPainter oldDelegate) =>
      links != oldDelegate.links ||
      items != oldDelegate.items ||
      hoveredLinkId != oldDelegate.hoveredLinkId ||
      selectedLinkId != oldDelegate.selectedLinkId;
}
