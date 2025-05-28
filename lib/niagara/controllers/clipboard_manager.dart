import 'package:flutter/material.dart';
import '../models/component.dart';
import '../models/connection.dart';

/// Manages clipboard operations for the flowsheet editor.
///
/// Handles copying, cutting, and pasting of components and their connections,
/// maintaining the clipboard state and providing methods for clipboard operations.
class ClipboardManager {
  /// List of components in the clipboard
  final List<Component> _clipboardComponents = [];

  /// Original positions of components in the clipboard
  final List<Offset> _clipboardPositions = [];

  /// Connections between components in the clipboard
  final List<Connection> _clipboardConnections = [];

  /// Position of the first component in the clipboard (for reference)
  Offset? _clipboardReferencePosition;

  /// Get the list of components in the clipboard
  List<Component> get clipboardComponents => _clipboardComponents;

  /// Get the original positions of components in the clipboard
  List<Offset> get clipboardPositions => _clipboardPositions;

  /// Get the connections between components in the clipboard
  List<Connection> get clipboardConnections => _clipboardConnections;

  /// Get the reference position for the clipboard
  Offset? get clipboardReferencePosition => _clipboardReferencePosition;

  /// Check if the clipboard is empty
  bool get isEmpty => _clipboardComponents.isEmpty;

  /// Copy a single component to the clipboard
  void copyComponent(Component component, Offset position) {
    _clipboardComponents.clear();
    _clipboardPositions.clear();
    _clipboardConnections.clear();

    _clipboardComponents.add(component);
    _clipboardPositions.add(position);
    _clipboardReferencePosition = position;
  }

  /// Copy multiple components to the clipboard
  void copyMultipleComponents(
    Set<Component> components,
    Map<String, Offset> componentPositions,
    List<Connection> allConnections,
  ) {
    if (components.isEmpty) return;

    _clipboardComponents.clear();
    _clipboardPositions.clear();
    _clipboardConnections.clear();

    // Create a mapping from component ID to index in the clipboard
    Map<String, int> componentIndexMap = {};

    int index = 0;
    for (final component in components) {
      _clipboardComponents.add(component);

      final position = componentPositions[component.id] ?? Offset.zero;
      _clipboardPositions.add(position);

      componentIndexMap[component.id] = index;
      index++;
    }

    // Store connections between copied components
    for (final connection in allConnections) {
      final fromSelected = componentIndexMap.containsKey(
        connection.fromComponentId,
      );
      final toSelected = componentIndexMap.containsKey(
        connection.toComponentId,
      );

      // Only include connections where both components are selected
      if (fromSelected && toSelected) {
        _clipboardConnections.add(connection);
      }
    }

    if (_clipboardComponents.isNotEmpty) {
      _clipboardReferencePosition = _clipboardPositions.first;
    }
  }

  /// Set the reference position for the clipboard
  void setClipboardReferencePosition(Offset position) {
    _clipboardReferencePosition = position;
  }

  /// Clear the clipboard
  void clear() {
    _clipboardComponents.clear();
    _clipboardPositions.clear();
    _clipboardConnections.clear();
    _clipboardReferencePosition = null;
  }

  /// Get the relative positions of components in the clipboard
  List<Offset> getRelativePositions() {
    if (_clipboardReferencePosition == null || _clipboardPositions.isEmpty) {
      return List.filled(_clipboardPositions.length, Offset.zero);
    }

    return _clipboardPositions
        .map((pos) => pos - _clipboardReferencePosition!)
        .toList();
  }

  /// Calculate paste positions based on a target position
  List<Offset> calculatePastePositions(Offset targetPosition) {
    final relativePositions = getRelativePositions();
    return relativePositions.map((relPos) => targetPosition + relPos).toList();
  }
}
