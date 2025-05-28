import 'package:flutter/material.dart';
import '../models/component.dart';
import '../models/connection.dart';

class ClipboardManager {
  final List<Component> _clipboardComponents = [];
  final List<Offset> _clipboardPositions = [];
  final List<Connection> _clipboardConnections = [];
  Offset? _clipboardReferencePosition;
  List<Component> get clipboardComponents => _clipboardComponents;
  List<Offset> get clipboardPositions => _clipboardPositions;
  List<Connection> get clipboardConnections => _clipboardConnections;
  Offset? get clipboardReferencePosition => _clipboardReferencePosition;
  bool get isEmpty => _clipboardComponents.isEmpty;

  void copyComponent(Component component, Offset position) {
    _clipboardComponents.clear();
    _clipboardPositions.clear();
    _clipboardConnections.clear();

    _clipboardComponents.add(component);
    _clipboardPositions.add(position);
    _clipboardReferencePosition = position;
  }

  void copyMultipleComponents(
    Set<Component> components,
    Map<String, Offset> componentPositions,
    List<Connection> allConnections,
  ) {
    if (components.isEmpty) return;

    _clipboardComponents.clear();
    _clipboardPositions.clear();
    _clipboardConnections.clear();

    Map<String, int> componentIndexMap = {};

    int index = 0;
    for (final component in components) {
      _clipboardComponents.add(component);

      final position = componentPositions[component.id] ?? Offset.zero;
      _clipboardPositions.add(position);

      componentIndexMap[component.id] = index;
      index++;
    }

    for (final connection in allConnections) {
      final fromSelected = componentIndexMap.containsKey(
        connection.fromComponentId,
      );
      final toSelected = componentIndexMap.containsKey(
        connection.toComponentId,
      );

      if (fromSelected && toSelected) {
        _clipboardConnections.add(connection);
      }
    }

    if (_clipboardComponents.isNotEmpty) {
      _clipboardReferencePosition = _clipboardPositions.first;
    }
  }

  void setClipboardReferencePosition(Offset position) {
    _clipboardReferencePosition = position;
  }

  void clear() {
    _clipboardComponents.clear();
    _clipboardPositions.clear();
    _clipboardConnections.clear();
    _clipboardReferencePosition = null;
  }

  List<Offset> getRelativePositions() {
    if (_clipboardReferencePosition == null || _clipboardPositions.isEmpty) {
      return List.filled(_clipboardPositions.length, Offset.zero);
    }

    return _clipboardPositions
        .map((pos) => pos - _clipboardReferencePosition!)
        .toList();
  }

  List<Offset> calculatePastePositions(Offset targetPosition) {
    final relativePositions = getRelativePositions();
    return relativePositions.map((relPos) => targetPosition + relPos).toList();
  }
}
