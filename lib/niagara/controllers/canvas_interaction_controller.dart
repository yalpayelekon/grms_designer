import 'package:flutter/material.dart';

/// Manages canvas interactions including pan, zoom, and transformation.
///
/// This controller centralizes the logic for canvas manipulation,
/// making it easier to optimize canvas performance and handle
/// complex interactions.
class CanvasInteractionController {
  /// Controller for canvas transformations (pan/zoom)
  final TransformationController transformationController;

  Matrix4? _cachedInverseMatrix;
  Matrix4? _lastMatrix;
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

  Offset? getCanvasPositionOptimized(
    Offset globalPosition,
    RenderBox canvasBox,
  ) {
    final Offset localPosition = canvasBox.globalToLocal(globalPosition);
    final matrix = transformationController.value;

    if (_lastMatrix != matrix) {
      _cachedInverseMatrix = Matrix4.inverted(matrix);
      _lastMatrix = matrix.clone();
    }

    final canvasPosition = MatrixUtils.transformPoint(
      _cachedInverseMatrix!,
      localPosition,
    );

    return canvasPosition;
  }

  Rect getViewportBounds(Size viewportSize) {
    final matrix = transformationController.value;
    final inverseMatrix = Matrix4.inverted(matrix);

    final topLeft = MatrixUtils.transformPoint(inverseMatrix, Offset.zero);
    final bottomRight = MatrixUtils.transformPoint(
      inverseMatrix,
      Offset(viewportSize.width, viewportSize.height),
    );

    return Rect.fromPoints(topLeft, bottomRight);
  }

  /// Check if a component is visible in the current viewport
  bool isComponentVisible(
    Offset componentPos,
    Size componentSize,
    Size viewportSize,
  ) {
    final viewportBounds = getViewportBounds(viewportSize);
    final componentRect = Rect.fromLTWH(
      componentPos.dx,
      componentPos.dy,
      componentSize.width,
      componentSize.height,
    );

    return viewportBounds.overlaps(componentRect);
  }

  /// Clear the transformation cache
  void clearCache() {
    _cachedInverseMatrix = null;
    _lastMatrix = null;
  }

  /// Update the canvas size with better bounds calculation
  bool updateCanvasSize(
    Map<String, Offset> componentPositions,
    Map<String, double> componentWidths,
  ) {
    if (componentPositions.isEmpty) return false;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    // Find the bounds of all components using actual widths
    componentPositions.forEach((id, position) {
      final width = componentWidths[id] ?? 160.0;
      const estimatedHeight = 120.0;

      minX = minX < position.dx ? minX : position.dx;
      minY = minY < position.dy ? minY : position.dy;
      maxX = maxX > position.dx + width ? maxX : position.dx + width;
      maxY = maxY > position.dy + estimatedHeight
          ? maxY
          : position.dy + estimatedHeight;
    });

    bool needsUpdate = false;
    Size newCanvasSize = _canvasSize;
    Offset newCanvasOffset = _canvasOffset;

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
      clearCache(); // Clear cache when canvas changes
      return true;
    }

    return false;
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

  void setCanvasSize(Size size, Offset offset) {
    _canvasSize = size;
    _canvasOffset = offset;
  }
}
