import 'package:flutter/material.dart';

Offset? getPosition(
  Offset globalPosition,
  GlobalKey canvasKey,
  TransformationController transformationController,
) {
  final RenderBox? canvasBox =
      canvasKey.currentContext?.findRenderObject() as RenderBox?;

  if (canvasBox != null) {
    final Offset localPosition = canvasBox.globalToLocal(globalPosition);

    final matrix = transformationController.value;
    final inverseMatrix = Matrix4.inverted(matrix);
    final canvasPosition = MatrixUtils.transformPoint(
      inverseMatrix,
      localPosition,
    );

    return canvasPosition;
  }
  return null;
}
