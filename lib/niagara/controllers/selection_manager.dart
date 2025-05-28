import 'package:flutter/services.dart';
import '../models/component.dart';

typedef SelectionChangedCallback = void Function(Set<Component> selected);

class SelectionManager {
  final Set<Component> _selectedComponents = {};
  SelectionChangedCallback? _onSelectionChanged;

  Offset? _selectionBoxStart;
  Offset? _selectionBoxEnd;
  bool _isDraggingSelectionBox = false;
  Set<Component> get selectedComponents => _selectedComponents;
  bool get isDraggingSelectionBox => _isDraggingSelectionBox;
  Offset? get selectionBoxStart => _selectionBoxStart;
  Offset? get selectionBoxEnd => _selectionBoxEnd;

  Rect? getSelectionRect() {
    if (_selectionBoxStart == null || _selectionBoxEnd == null) return null;
    return Rect.fromPoints(_selectionBoxStart!, _selectionBoxEnd!);
  }

  void clearSelection() {
    if (_selectedComponents.isNotEmpty) {
      _selectedComponents.clear();
      _notifySelectionChanged();
    }
  }

  void selectComponent(Component component) {
    clearSelection();
    _selectedComponents.add(component);
    _notifySelectionChanged();
  }

  void toggleComponentSelection(Component component) {
    if (_selectedComponents.contains(component)) {
      _selectedComponents.remove(component);
    } else {
      _selectedComponents.add(component);
    }
    _notifySelectionChanged();
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

  // Add these methods to your SelectionManager class

  /// More efficient selection box completion with component size lookup
  void endSelectionBoxWithSizes(
    List<Component> allComponents,
    Map<String, Offset> componentPositions,
    Map<String, double> componentWidths, // Use actual widths
    double defaultHeight,
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
        final componentWidth = componentWidths[component.id] ?? 160.0;
        final componentHeight = defaultHeight;

        final componentRect = Rect.fromLTWH(
          componentPos.dx,
          componentPos.dy,
          componentWidth + 20, // Include padding
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

  void setOnSelectionChanged(SelectionChangedCallback callback) {
    _onSelectionChanged = callback;
  }

  void _notifySelectionChanged() {
    _onSelectionChanged?.call(_selectedComponents);
  }
}
