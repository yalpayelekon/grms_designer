import 'package:flutter/material.dart';
import '../../models/flowsheet.dart';
import '../../niagara/home/manager.dart';
import '../../niagara/models/component.dart';
import '../../niagara/models/connection.dart';
import '../../services/flowsheet_storage_service.dart';

class PersistenceHelper {
  final Flowsheet flowsheet;
  final FlowsheetStorageService storageService;
  final FlowManager flowManager;
  final Map<String, Offset> componentPositions;
  final Map<String, double> componentWidths;
  final Function() getMountedStatus;
  final Function(Flowsheet) onFlowsheetUpdate;

  PersistenceHelper({
    required this.flowsheet,
    required this.storageService,
    required this.flowManager,
    required this.componentPositions,
    required this.componentWidths,
    required this.getMountedStatus,
    required this.onFlowsheetUpdate,
  });

  Future<void> saveFullState() async {
    if (!getMountedStatus()) return;

    try {
      final updatedFlowsheet = flowsheet.copy();
      updatedFlowsheet.components = flowManager.components;

      final List<Connection> connections = [];
      for (final component in flowManager.components) {
        for (final entry in component.inputConnections.entries) {
          connections.add(
            Connection(
              fromComponentId: entry.value.componentId,
              fromPortIndex: entry.value.portIndex,
              toComponentId: component.id,
              toPortIndex: entry.key,
            ),
          );
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
        await storageService.saveFlowsheet(updatedFlowsheet);
        onFlowsheetUpdate(updatedFlowsheet);
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
    String componentId,
    Offset position,
  ) async {
    await _safeOperation(() async {
      if (!getMountedStatus()) return;

      flowsheet.updateComponentPosition(componentId, position);
      flowsheet.modifiedAt = DateTime.now();

      // Only save to storage, don't update provider
      await storageService.saveFlowsheet(flowsheet);
    });
  }

  Future<void> saveComponentWidth(String componentId, double width) async {
    await _safeOperation(() async {
      if (!getMountedStatus()) return;

      flowsheet.updateComponentWidth(componentId, width);
      flowsheet.modifiedAt = DateTime.now();

      await storageService.saveFlowsheet(flowsheet);
    });
  }

  Future<void> saveAddComponent(Component component) async {
    await _safeOperation(() async {
      if (!getMountedStatus()) return;

      flowsheet.addComponent(component);

      await storageService.saveFlowsheet(flowsheet);
    });
  }

  Future<void> saveUpdateComponent(
    String componentId,
    Component component,
  ) async {
    await _safeOperation(() async {
      if (!getMountedStatus()) return;

      flowsheet.updateComponent(componentId, component);

      await storageService.saveFlowsheet(flowsheet);
    });
  }

  Future<void> saveRemoveComponent(String componentId) async {
    await _safeOperation(() async {
      if (!getMountedStatus()) return;

      flowsheet.removeComponent(componentId);

      await storageService.saveFlowsheet(flowsheet);
    });
  }

  Future<void> saveAddConnection(Connection connection) async {
    await _safeOperation(() async {
      if (!getMountedStatus()) return;

      flowsheet.addConnection(connection);

      await storageService.saveFlowsheet(flowsheet);
    });
  }

  Future<void> saveRemoveConnection(
    String fromComponentId,
    int fromPortIndex,
    String toComponentId,
    int toPortIndex,
  ) async {
    await _safeOperation(() async {
      if (!getMountedStatus()) return;

      flowsheet.removeConnection(
        fromComponentId,
        fromPortIndex,
        toComponentId,
        toPortIndex,
      );

      await storageService.saveFlowsheet(flowsheet);
    });
  }

  Future<void> savePortValue(
    String componentId,
    int slotIndex,
    dynamic value,
  ) async {
    await _safeOperation(() async {
      if (!getMountedStatus()) return;

      flowsheet.updatePortValue(componentId, slotIndex, value);

      await storageService.saveFlowsheet(flowsheet);
    });
  }
}
