import 'package:flutter/material.dart';
import '../home/component_widget.dart';
import '../models/component.dart';

/// Manages drag operations in the flowsheet editor.
///
/// Handles both component dragging and port connection dragging operations,
/// maintaining the state of ongoing drag operations and providing helper
/// methods for drag-related calculations.
class DragOperationManager {
  /// Information about the currently dragged port (for connections)
  SlotDragInfo? _currentDraggedPort;

  /// Current end point of the temporary connection line
  Offset? _tempLineEndPoint;

  /// Position where the current drag operation started
  Offset? _dragStartPosition;

  /// Get information about the currently dragged port
  SlotDragInfo? get currentDraggedPort => _currentDraggedPort;

  /// Get the current end point of the temporary connection line
  Offset? get tempLineEndPoint => _tempLineEndPoint;

  /// Get the position where the current drag operation started
  Offset? get dragStartPosition => _dragStartPosition;

  /// Start dragging a port (for creating connections)
  void startPortDrag(SlotDragInfo slotInfo) {
    _currentDraggedPort = slotInfo;
  }

  /// Update the temporary connection line end point during drag
  void updatePortDragPosition(Offset position) {
    _tempLineEndPoint = position;
  }

  /// End a port drag operation
  void endPortDrag() {
    _currentDraggedPort = null;
    _tempLineEndPoint = null;
  }

  /// Start dragging a component
  void startComponentDrag(Offset position) {
    _dragStartPosition = position;
  }

  /// End a component drag operation
  void endComponentDrag() {
    _dragStartPosition = null;
  }

  /// Calculate the drag offset for component movement
  Offset calculateDragOffset(Offset currentPosition) {
    if (_dragStartPosition == null) return Offset.zero;
    return currentPosition - _dragStartPosition!;
  }

  /// Check if a component drag is in progress
  bool isComponentDragInProgress() {
    return _dragStartPosition != null;
  }

  /// Check if a port drag is in progress
  bool isPortDragInProgress() {
    return _currentDraggedPort != null;
  }

  /// Move components by a specified offset
  Map<String, Offset> moveComponentsByOffset(
    Map<String, Offset> componentPositions,
    Set<Component> selectedComponents,
    Offset offset,
  ) {
    final Map<String, Offset> updatedPositions = Map.from(componentPositions);

    for (var component in selectedComponents) {
      final currentPos = componentPositions[component.id];
      if (currentPos != null) {
        updatedPositions[component.id] = currentPos + offset;
      }
    }

    return updatedPositions;
  }

  /// Move a single component to a new position
  Map<String, Offset> moveComponentToPosition(
    Map<String, Offset> componentPositions,
    String componentId,
    Offset newPosition,
  ) {
    final Map<String, Offset> updatedPositions = Map.from(componentPositions);
    updatedPositions[componentId] = newPosition;
    return updatedPositions;
  }
}
