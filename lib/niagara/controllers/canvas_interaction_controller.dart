import 'package:flutter/material.dart';

class CanvasInteractionController {
  final TransformationController transformationController;

  Matrix4? _cachedInverseMatrix;
  Matrix4? _lastMatrix;
  Size _canvasSize;

  Offset _canvasOffset;
  static const double canvasPadding = 100.0;
  bool isDragging = false;

  CanvasInteractionController({
    Size initialCanvasSize = const Size(2000, 2000),
    Offset initialCanvasOffset = Offset.zero,
  }) : transformationController = TransformationController(),
       _canvasSize = initialCanvasSize,
       _canvasOffset = initialCanvasOffset {
    transformationController.value = Matrix4.identity();
  }

  Size get canvasSize => _canvasSize;
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

  void clearCache() {
    _cachedInverseMatrix = null;
    _lastMatrix = null;
  }

  bool updateCanvasSize(
    Map<String, Offset> componentPositions,
    Map<String, double> componentWidths,
  ) {
    if (componentPositions.isEmpty) return false;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

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

    if (maxX > _canvasSize.width - canvasPadding) {
      double extraWidth = maxX - (_canvasSize.width - canvasPadding);
      newCanvasSize = Size(
        _canvasSize.width + extraWidth,
        newCanvasSize.height,
      );
      needsUpdate = true;
    }

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
      clearCache();
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
