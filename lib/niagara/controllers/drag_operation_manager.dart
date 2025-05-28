import 'package:flutter/material.dart';
import '../home/component_widget.dart';
import '../models/component.dart';

class DragOperationManager {
  SlotDragInfo? _currentDraggedPort;
  Offset? _tempLineEndPoint;
  Offset? _dragStartPosition;
  SlotDragInfo? get currentDraggedPort => _currentDraggedPort;
  Offset? get tempLineEndPoint => _tempLineEndPoint;
  Offset? get dragStartPosition => _dragStartPosition;

  void startPortDrag(SlotDragInfo slotInfo) {
    _currentDraggedPort = slotInfo;
  }

  void updatePortDragPosition(Offset position) {
    _tempLineEndPoint = position;
  }

  void endPortDrag() {
    _currentDraggedPort = null;
    _tempLineEndPoint = null;
  }

  void startComponentDrag(Offset position) {
    _dragStartPosition = position;
  }

  void endComponentDrag() {
    _dragStartPosition = null;
  }

  Offset calculateDragOffset(Offset currentPosition) {
    if (_dragStartPosition == null) return Offset.zero;
    return currentPosition - _dragStartPosition!;
  }

  bool isComponentDragInProgress() {
    return _dragStartPosition != null;
  }

  bool isPortDragInProgress() {
    return _currentDraggedPort != null;
  }

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
