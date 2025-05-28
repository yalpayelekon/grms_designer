import 'package:flutter/services.dart';
import '../models/component.dart';

class SelectionManager {
  /// Set of currently selected components
  final Set<Component> _selectedComponents = {};

  /// Starting point of the selection box
  Offset? _selectionBoxStart;

  /// Current end point of the selection box
  Offset? _selectionBoxEnd;

  /// Flag indicating if a selection box is being dragged
  bool _isDraggingSelectionBox = false;

  /// Get the current set of selected components
  Set<Component> get selectedComponents => _selectedComponents;

  /// Check if a selection box is currently being dragged
  bool get isDraggingSelectionBox => _isDraggingSelectionBox;

  /// Get the starting point of the selection box
  Offset? get selectionBoxStart => _selectionBoxStart;

  /// Get the end point of the selection box
  Offset? get selectionBoxEnd => _selectionBoxEnd;

  /// Get the rectangle formed by the selection box
  Rect? getSelectionRect() {
    if (_selectionBoxStart == null || _selectionBoxEnd == null) return null;
    return Rect.fromPoints(_selectionBoxStart!, _selectionBoxEnd!);
  }

  /// Clear all selections
  void clearSelection() {
    _selectedComponents.clear();
  }

  /// Select a single component
  void selectComponent(Component component) {
    clearSelection();
    _selectedComponents.add(component);
  }

  /// Toggle selection of a component (for multi-select with Ctrl/Cmd)
  void toggleComponentSelection(Component component) {
    if (_selectedComponents.contains(component)) {
      _selectedComponents.remove(component);
    } else {
      _selectedComponents.add(component);
    }
  }

  /// Check if a component is selected
  bool isComponentSelected(Component component) {
    return _selectedComponents.contains(component);
  }

  /// Start a selection box operation
  void startSelectionBox(Offset position) {
    _selectionBoxStart = position;
    _selectionBoxEnd = position;
    _isDraggingSelectionBox = true;
  }

  /// Update the selection box during drag
  void updateSelectionBox(Offset position) {
    if (_isDraggingSelectionBox) {
      _selectionBoxEnd = position;
    }
  }

  /// Complete a selection box operation
  void endSelectionBox(
    List<Component> allComponents,
    Map<String, Offset> componentPositions,
  ) {
    if (!_isDraggingSelectionBox ||
        _selectionBoxStart == null ||
        _selectionBoxEnd == null) {
      _isDraggingSelectionBox = false;
      return;
    }

    final selectionRect = getSelectionRect();
    if (selectionRect == null) {
      _isDraggingSelectionBox = false;
      return;
    }

    // If not pressing Ctrl/Cmd, clear previous selection
    if (!HardwareKeyboard.instance.isControlPressed) {
      clearSelection();
    }

    // Select components that intersect with the selection box
    for (final component in allComponents) {
      final componentPos = componentPositions[component.id];
      if (componentPos != null) {
        const double componentWidth = 180.0;
        const double componentHeight = 150.0;

        final componentRect = Rect.fromLTWH(
          componentPos.dx,
          componentPos.dy,
          componentWidth,
          componentHeight,
        );

        if (selectionRect.overlaps(componentRect)) {
          _selectedComponents.add(component);
        }
      }
    }

    // Reset selection box state
    _isDraggingSelectionBox = false;
    _selectionBoxStart = null;
    _selectionBoxEnd = null;
  }

  /// Cancel the current selection box operation
  void cancelSelectionBox() {
    _isDraggingSelectionBox = false;
    _selectionBoxStart = null;
    _selectionBoxEnd = null;
  }

  /// Select all components
  void selectAll(List<Component> allComponents) {
    _selectedComponents.clear();
    _selectedComponents.addAll(allComponents);
  }
}
