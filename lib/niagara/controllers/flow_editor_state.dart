import 'package:flutter/material.dart';
import '../models/component.dart';
import '../models/command_history.dart';
import '../home/manager.dart';

/// Manages the state for the WiresheetFlowEditor.
///
/// This class serves as a central place to store and manage state that
/// was previously scattered throughout the WiresheetFlowEditor widget.
class FlowEditorState {
  /// The flow manager for component and connection management
  final FlowManager flowManager;

  /// Command history for undo/redo operations
  final CommandHistory commandHistory;

  /// Map of component IDs to their positions on the canvas
  final Map<String, Offset> componentPositions = {};

  /// Map of component IDs to their widget keys
  final Map<String, GlobalKey> componentKeys = {};

  /// Map of component IDs to their widths
  final Map<String, double> componentWidths = {};

  /// Key for the canvas
  final GlobalKey canvasKey = GlobalKey();

  /// Key for the InteractiveViewer child
  final GlobalKey interactiveViewerChildKey = GlobalKey();

  /// Whether the panel is expanded
  bool isPanelExpanded = false;

  /// Constructor
  FlowEditorState({required this.flowManager, required this.commandHistory});

  /// Initialize a component's state
  void initializeComponentState(
    Component component, {
    Offset position = Offset.zero,
    double width = 160.0,
  }) {
    componentPositions[component.id] = position;
    componentKeys[component.id] = GlobalKey();
    componentWidths[component.id] = width;
  }

  /// Get a component's position
  Offset getComponentPosition(String componentId) {
    return componentPositions[componentId] ?? Offset.zero;
  }

  /// Set a component's position
  void setComponentPosition(String componentId, Offset position) {
    componentPositions[componentId] = position;
  }

  /// Get a component's width
  double getComponentWidth(String componentId) {
    return componentWidths[componentId] ?? 160.0;
  }

  /// Set a component's width
  void setComponentWidth(String componentId, double width) {
    componentWidths[componentId] = width;
  }

  /// Get a component's key
  GlobalKey getComponentKey(String componentId) {
    if (!componentKeys.containsKey(componentId)) {
      componentKeys[componentId] = GlobalKey();
    }
    return componentKeys[componentId]!;
  }

  /// Check if a point is over any component
  bool isPointOverComponent(Offset point) {
    for (final entry in componentPositions.entries) {
      final componentPos = entry.value;
      const double componentWidth = 180.0;
      const double componentHeight = 150.0;

      final componentRect = Rect.fromLTWH(
        componentPos.dx,
        componentPos.dy,
        componentWidth,
        componentHeight,
      );

      if (componentRect.contains(point)) {
        return true;
      }
    }
    return false;
  }

  /// Find a component at a given point
  Component? findComponentAtPoint(Offset point) {
    for (final component in flowManager.components) {
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

        if (componentRect.contains(point)) {
          return component;
        }
      }
    }
    return null;
  }

  /// Clear all state
  void clear() {
    componentPositions.clear();
    componentKeys.clear();
    componentWidths.clear();
    flowManager.components.clear();
    flowManager.connections.clear();
    commandHistory.clear();
  }
}
