import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/flowsheet.dart';
import '../niagara/home/manager.dart';
import '../niagara/models/component.dart';
import '../niagara/models/connection.dart';
import '../providers/flowsheet_provider.dart';

class PersistenceHelper {
  final Flowsheet flowsheet;
  final WidgetRef ref;
  final FlowManager flowManager;
  final Map<String, Offset> componentPositions;
  final Map<String, double> componentWidths;
  final Function()
      getMountedStatus; // Function to check if the widget is still mounted

  PersistenceHelper({
    required this.flowsheet,
    required this.ref,
    required this.flowManager,
    required this.componentPositions,
    required this.componentWidths,
    required this.getMountedStatus, // Add this parameter
  });

  Future<void> saveFullState() async {
    if (!getMountedStatus()) return;

    try {
      final updatedFlowsheet = flowsheet.copy();
      updatedFlowsheet.components = flowManager.components;

      final List<Connection> connections = [];
      for (final component in flowManager.components) {
        for (final entry in component.inputConnections.entries) {
          connections.add(Connection(
            fromComponentId: entry.value.componentId,
            fromPortIndex: entry.value.portIndex,
            toComponentId: component.id,
            toPortIndex: entry.key,
          ));
        }
      }
      updatedFlowsheet.connections = connections;

      for (final entry in componentPositions.entries) {
        updatedFlowsheet.updateComponentPosition(entry.key, entry.value);
      }

      for (final entry in componentWidths.entries) {
        updatedFlowsheet.updateComponentWidth(entry.key, entry.value);
      }

      if (getMountedStatus()) {
        final storageService = ref.read(flowsheetStorageServiceProvider);
        await storageService.saveFlowsheet(updatedFlowsheet);
      }
    } catch (e) {
      print('Error saving flowsheet state: $e');
    }
  }

  Future<void> _safeOperation(Future<void> Function() operation) async {
    if (!getMountedStatus()) return;
    try {
      await operation();
    } catch (e) {
      print('Error during persistence operation: $e');
    }
  }

  Future<void> saveComponentPosition(
      String componentId, Offset position) async {
    await _safeOperation(() async {
      if (!getMountedStatus()) return;
      await ref.read(flowsheetsProvider.notifier).updateComponentPosition(
            flowsheet.id,
            componentId,
            position,
          );
    });
  }

  Future<void> saveComponentWidth(String componentId, double width) async {
    await _safeOperation(() async {
      if (!getMountedStatus()) return;
      await ref.read(flowsheetsProvider.notifier).updateComponentWidth(
            flowsheet.id,
            componentId,
            width,
          );
    });
  }

  Future<void> saveAddComponent(Component component) async {
    await _safeOperation(() async {
      if (!getMountedStatus()) return;
      await ref.read(flowsheetsProvider.notifier).addFlowsheetComponent(
            flowsheet.id,
            component,
          );
    });
  }

  Future<void> saveUpdateComponent(
      String componentId, Component component) async {
    await _safeOperation(() async {
      if (!getMountedStatus()) return;
      await ref.read(flowsheetsProvider.notifier).updateFlowsheetComponent(
            flowsheet.id,
            componentId,
            component,
          );
    });
  }

  Future<void> saveRemoveComponent(String componentId) async {
    await _safeOperation(() async {
      if (!getMountedStatus()) return;
      await ref.read(flowsheetsProvider.notifier).removeFlowsheetComponent(
            flowsheet.id,
            componentId,
          );
    });
  }

  Future<void> saveAddConnection(Connection connection) async {
    await _safeOperation(() async {
      if (!getMountedStatus()) return;
      await ref.read(flowsheetsProvider.notifier).addConnection(
            flowsheet.id,
            connection,
          );
    });
  }

  Future<void> saveRemoveConnection(String fromComponentId, int fromPortIndex,
      String toComponentId, int toPortIndex) async {
    await _safeOperation(() async {
      if (!getMountedStatus()) return;
      await ref.read(flowsheetsProvider.notifier).removeConnection(
            flowsheet.id,
            fromComponentId,
            fromPortIndex,
            toComponentId,
            toPortIndex,
          );
    });
  }

  Future<void> savePortValue(
      String componentId, int slotIndex, dynamic value) async {
    await _safeOperation(() async {
      if (!getMountedStatus()) return;
      await ref.read(flowsheetsProvider.notifier).updatePortValue(
            flowsheet.id,
            componentId,
            slotIndex,
            value,
          );
    });
  }
}
