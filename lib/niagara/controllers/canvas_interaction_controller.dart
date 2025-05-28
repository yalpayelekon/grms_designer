import 'package:flutter/material.dart';

/// Manages canvas interactions including pan, zoom, and transformation.
///
/// This controller centralizes the logic for canvas manipulation,
/// making it easier to optimize canvas performance and handle
/// complex interactions.
class CanvasInteractionController {
  /// Controller for canvas transformations (pan/zoom)
  final TransformationController transformationController;

  /// Current size of the canvas
  Size _canvasSize;

  /// Current offset of the canvas within the view
  Offset _canvasOffset;

  /// Padding around components when auto-sizing the canvas
  static const double canvasPadding = 100.0;

  /// Flag indicating if the canvas is being dragged
  bool isDragging = false;

  /// Constructor
  CanvasInteractionController({
    Size initialCanvasSize = const Size(2000, 2000),
    Offset initialCanvasOffset = Offset.zero,
  }) : transformationController = TransformationController(),
       _canvasSize = initialCanvasSize,
       _canvasOffset = initialCanvasOffset {
    // Initialize with identity matrix (no transformation)
    transformationController.value = Matrix4.identity();
  }

  /// Get the current canvas size
  Size get canvasSize => _canvasSize;

  /// Get the current canvas offset
  Offset get canvasOffset => _canvasOffset;

  void resetView() {
    transformationController.value = Matrix4.identity();
  }

  Offset? getCanvasPosition(Offset globalPosition, RenderBox canvasBox) {
    final Offset localPosition = canvasBox.globalToLocal(globalPosition);

    final matrix = transformationController.value;
    final inverseMatrix = Matrix4.inverted(matrix);
    final canvasPosition = MatrixUtils.transformPoint(
      inverseMatrix,
      localPosition,
    );

    return canvasPosition;
  }

  bool updateCanvasSize(Map<String, Offset> componentPositions) {
    if (componentPositions.isEmpty) return false;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (var position in componentPositions.values) {
      const estimatedWidth = 180.0; // 160 width + 20 padding
      const estimatedHeight = 120.0;

      minX = minX < position.dx ? minX : position.dx;
      minY = minY < position.dy ? minY : position.dy;
      maxX = maxX > position.dx + estimatedWidth
          ? maxX
          : position.dx + estimatedWidth;
      maxY = maxY > position.dy + estimatedHeight
          ? maxY
          : position.dy + estimatedHeight;
    }

    bool needsUpdate = false;
    Size newCanvasSize = _canvasSize;
    Offset newCanvasOffset = _canvasOffset;

    // Check if canvas needs to expand left
    if (minX < canvasPadding) {
      double extraWidth = canvasPadding - minX;
      newCanvasSize = Size(
        _canvasSize.width + extraWidth,
        newCanvasSize.height,
      );
      newCanvasOffset = Offset(
        _canvasOffset.dx - extraWidth,
        newCanvasOffset.dy,
      );
      needsUpdate = true;
    }

    // Check if canvas needs to expand top
    if (minY < canvasPadding) {
      double extraHeight = canvasPadding - minY;
      newCanvasSize = Size(
        newCanvasSize.width,
        _canvasSize.height + extraHeight,
      );
      newCanvasOffset = Offset(
        newCanvasOffset.dx,
        _canvasOffset.dy - extraHeight,
      );
      needsUpdate = true;
    }

    // Check if canvas needs to expand right
    if (maxX > _canvasSize.width - canvasPadding) {
      double extraWidth = maxX - (_canvasSize.width - canvasPadding);
      newCanvasSize = Size(
        _canvasSize.width + extraWidth,
        newCanvasSize.height,
      );
      needsUpdate = true;
    }

    // Check if canvas needs to expand bottom
    if (maxY > _canvasSize.height - canvasPadding) {
      double extraHeight = maxY - (_canvasSize.height - canvasPadding);
      newCanvasSize = Size(
        newCanvasSize.width,
        _canvasSize.height + extraHeight,
      );
      needsUpdate = true;
    }

    if (needsUpdate) {
      _canvasSize = newCanvasSize;
      _canvasOffset = newCanvasOffset;
      return true;
    }

    return false;
  }

  /// Get adjusted component positions after canvas resize
  Map<String, Offset> getAdjustedPositions(
    Map<String, Offset> componentPositions,
    Offset offsetChange,
  ) {
    if (offsetChange == Offset.zero) return componentPositions;

    final adjustedPositions = <String, Offset>{};
    componentPositions.forEach((id, position) {
      adjustedPositions[id] = position + offsetChange;
    });

    return adjustedPositions;
  }

  /// Set canvas size and offset
  void setCanvasSize(Size size, Offset offset) {
    _canvasSize = size;
    _canvasOffset = offset;
  }
}
