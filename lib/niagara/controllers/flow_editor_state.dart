import 'package:flutter/material.dart';
import '../models/component.dart';
import '../models/command_history.dart';
import '../home/manager.dart';

class FlowEditorState {
  final FlowManager flowManager;
  final CommandHistory commandHistory;
  final Map<String, Offset> componentPositions = {};
  final Map<String, GlobalKey> componentKeys = {};
  final Map<String, double> componentWidths = {};
  final GlobalKey canvasKey = GlobalKey();
  final GlobalKey interactiveViewerChildKey = GlobalKey();
  bool isPanelExpanded = false;
  FlowEditorState({required this.flowManager, required this.commandHistory});

  void initializeComponentState(
    Component component, {
    Offset position = Offset.zero,
    double width = 160.0,
  }) {
    componentPositions[component.id] = position;
    componentKeys[component.id] = GlobalKey();
    componentWidths[component.id] = width;
  }

  Offset getComponentPosition(String componentId) {
    return componentPositions[componentId] ?? Offset.zero;
  }

  void setComponentPosition(String componentId, Offset position) {
    componentPositions[componentId] = position;
  }

  double getComponentWidth(String componentId) {
    return componentWidths[componentId] ?? 160.0;
  }

  void setComponentWidth(String componentId, double width) {
    componentWidths[componentId] = width;
  }

  GlobalKey getComponentKey(String componentId) {
    if (!componentKeys.containsKey(componentId)) {
      componentKeys[componentId] = GlobalKey();
    }
    return componentKeys[componentId]!;
  }

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

  void clear() {
    componentPositions.clear();
    componentKeys.clear();
    componentWidths.clear();
    flowManager.components.clear();
    flowManager.connections.clear();
    commandHistory.clear();
  }
}
