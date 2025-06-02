import 'package:flutter/material.dart';
import 'package:grms_designer/niagara/controllers/canvas_interaction_controller.dart';
import 'package:grms_designer/niagara/controllers/flow_editor_state.dart';

Offset getDefaultPosition(
  CanvasInteractionController canvasController,
  FlowEditorState editorState,
) {
  final RenderBox? viewerChildRenderBox =
      editorState.interactiveViewerChildKey.currentContext?.findRenderObject()
          as RenderBox?;

  if (viewerChildRenderBox != null) {
    final viewportSize = viewerChildRenderBox.size;
    final viewportCenter = Offset(
      viewportSize.width / 2,
      viewportSize.height / 2,
    );

    return canvasController.getCanvasPosition(
          viewportCenter,
          viewerChildRenderBox,
        ) ??
        Offset(
          canvasController.canvasSize.width / 2,
          canvasController.canvasSize.height / 2,
        );
  }

  return Offset(
    canvasController.canvasSize.width / 2,
    canvasController.canvasSize.height / 2,
  );
}

Offset calculateOptimalPosition(
  Map<String, Offset> existingPositions,
  Size canvasSize, {
  double margin = 50.0,
}) {
  if (existingPositions.isEmpty) {
    return Offset(canvasSize.width / 2, canvasSize.height / 2);
  }

  const gridSize = 100.0;
  for (int row = 0; row < (canvasSize.height / gridSize).ceil(); row++) {
    for (int col = 0; col < (canvasSize.width / gridSize).ceil(); col++) {
      final candidate = Offset(
        col * gridSize + margin,
        row * gridSize + margin,
      );

      bool hasOverlap = false;
      for (final existingPos in existingPositions.values) {
        if ((candidate - existingPos).distance < gridSize) {
          hasOverlap = true;
          break;
        }
      }

      if (!hasOverlap) {
        return candidate;
      }
    }
  }

  return Offset(canvasSize.width / 2, canvasSize.height / 2);
}

Offset snapToGrid(Offset position, {double gridSize = 20.0}) {
  return Offset(
    (position.dx / gridSize).round() * gridSize,
    (position.dy / gridSize).round() * gridSize,
  );
}
