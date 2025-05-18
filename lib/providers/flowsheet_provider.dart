import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../niagara/models/component.dart';
import '../niagara/models/connection.dart';
import '../models/flowsheet.dart';
import '../services/flowsheet_storage_service.dart';
import '../utils/logger.dart';

class FlowsheetsNotifier extends StateNotifier<List<Flowsheet>> {
  final FlowsheetStorageService _storageService;
  String? _activeFlowsheetId;
  bool _initialized = false;

  FlowsheetsNotifier({required FlowsheetStorageService storageService})
      : _storageService = storageService,
        super([]) {
    _initializeData();
  }

  String? get activeFlowsheetId => _activeFlowsheetId;

  Future<void> _initializeData() async {
    if (_initialized) return;

    try {
      final flowsheets = await _storageService.listFlowsheets();

      if (flowsheets.isEmpty) {
        final defaultFlowsheet =
            await _storageService.createFlowsheet('Default Flowsheet');
        state = [defaultFlowsheet];
        _activeFlowsheetId = defaultFlowsheet.id;
      } else {
        state = flowsheets;
        _activeFlowsheetId = flowsheets.first.id;
      }

      _initialized = true;
    } catch (e) {
      logError('Error initializing flowsheets: $e');
    }
  }

  Flowsheet? get activeFlowsheet {
    if (_activeFlowsheetId == null || state.isEmpty) return null;

    try {
      return state.firstWhere(
        (sheet) => sheet.id == _activeFlowsheetId,
      );
    } catch (e) {
      return state.isNotEmpty ? state.first : null;
    }
  }

  // Add these methods to the FlowsheetsNotifier class

  Future<void> updateComponentPosition(
      String flowsheetId, String componentId, Offset position) async {
    final index = state.indexWhere((sheet) => sheet.id == flowsheetId);

    if (index >= 0) {
      final updatedState = List<Flowsheet>.from(state);
      updatedState[index].updateComponentPosition(componentId, position);
      state = updatedState;
      await _storageService.saveFlowsheet(updatedState[index]);
    }
  }

  Future<void> updateComponentWidth(
      String flowsheetId, String componentId, double width) async {
    final index = state.indexWhere((sheet) => sheet.id == flowsheetId);

    if (index >= 0) {
      final updatedState = List<Flowsheet>.from(state);
      updatedState[index].updateComponentWidth(componentId, width);
      state = updatedState;
      await _storageService.saveFlowsheet(updatedState[index]);
    }
  }

  Future<void> updatePortValue(String flowsheetId, String componentId,
      int slotIndex, dynamic value) async {
    final index = state.indexWhere((sheet) => sheet.id == flowsheetId);

    if (index >= 0) {
      final updatedState = List<Flowsheet>.from(state);
      updatedState[index].updatePortValue(componentId, slotIndex, value);
      state = updatedState;
      await _storageService.saveFlowsheet(updatedState[index]);
    }
  }

  void setActiveFlowsheet(String id) {
    final exists = state.any((sheet) => sheet.id == id);
    if (exists) {
      _activeFlowsheetId = id;
    } else if (state.isNotEmpty) {
      _activeFlowsheetId = state.first.id;
    } else {
      _activeFlowsheetId = null;
    }
  }

  Future<Flowsheet> createFlowsheet(String name) async {
    final flowsheet = await _storageService.createFlowsheet(name);
    state = [...state, flowsheet];
    _activeFlowsheetId = flowsheet.id;
    return flowsheet;
  }

  Future<bool> deleteFlowsheet(String id) async {
    final success = await _storageService.deleteFlowsheet(id);

    if (success) {
      state = state.where((sheet) => sheet.id != id).toList();
      if (_activeFlowsheetId == id) {
        _activeFlowsheetId = state.isNotEmpty ? state.first.id : null;
      }
    }

    return success;
  }

  Future<bool> renameFlowsheet(String id, String newName) async {
    final updatedFlowsheet = await _storageService.renameFlowsheet(id, newName);

    if (updatedFlowsheet != null) {
      state = state
          .map((sheet) => sheet.id == id ? updatedFlowsheet : sheet)
          .toList();
      return true;
    }

    return false;
  }

  Future<Flowsheet?> duplicateFlowsheet(String id, String newName) async {
    final duplicatedFlowsheet =
        await _storageService.duplicateFlowsheet(id, newName);

    if (duplicatedFlowsheet != null) {
      state = [...state, duplicatedFlowsheet];
      _activeFlowsheetId = duplicatedFlowsheet.id;
      return duplicatedFlowsheet;
    }

    return null;
  }

  Future<void> addFlowsheetComponent(
      String flowsheetId, Component component) async {
    final index = state.indexWhere((sheet) => sheet.id == flowsheetId);

    if (index >= 0) {
      final updatedState = List<Flowsheet>.from(state);
      updatedState[index].addComponent(component);
      state = updatedState;
      await _storageService.saveFlowsheet(updatedState[index]);
    }
  }

  Future<void> updateFlowsheetComponent(String flowsheetId, String componentId,
      Component updatedComponent) async {
    final index = state.indexWhere((sheet) => sheet.id == flowsheetId);

    if (index >= 0) {
      final updatedState = List<Flowsheet>.from(state);
      updatedState[index].updateComponent(componentId, updatedComponent);
      state = updatedState;
      await _storageService.saveFlowsheet(updatedState[index]);
    }
  }

  Future<void> removeFlowsheetComponent(
      String flowsheetId, String componentId) async {
    final index = state.indexWhere((sheet) => sheet.id == flowsheetId);

    if (index >= 0) {
      final updatedState = List<Flowsheet>.from(state);
      updatedState[index].removeComponent(componentId);
      state = updatedState;
      await _storageService.saveFlowsheet(updatedState[index]);
    }
  }

  Future<void> addConnection(String flowsheetId, Connection connection) async {
    final index = state.indexWhere((sheet) => sheet.id == flowsheetId);

    if (index >= 0) {
      final updatedState = List<Flowsheet>.from(state);
      updatedState[index].addConnection(connection);
      state = updatedState;
      await _storageService.saveFlowsheet(updatedState[index]);
    }
  }

  Future<void> removeConnection(String flowsheetId, String fromComponentId,
      int fromPortIndex, String toComponentId, int toPortIndex) async {
    final index = state.indexWhere((sheet) => sheet.id == flowsheetId);

    if (index >= 0) {
      final updatedState = List<Flowsheet>.from(state);
      updatedState[index].removeConnection(
          fromComponentId, fromPortIndex, toComponentId, toPortIndex);
      state = updatedState;
      await _storageService.saveFlowsheet(updatedState[index]);
    }
  }

  Future<void> updateCanvasSize(String flowsheetId, Size newSize) async {
    final index = state.indexWhere((sheet) => sheet.id == flowsheetId);

    if (index >= 0) {
      final updatedState = List<Flowsheet>.from(state);
      updatedState[index].updateCanvasSize(newSize);
      state = updatedState;
      await _storageService.saveFlowsheet(updatedState[index]);
    }
  }

  Future<void> updateCanvasOffset(String flowsheetId, Offset newOffset) async {
    final index = state.indexWhere((sheet) => sheet.id == flowsheetId);

    if (index >= 0) {
      final updatedState = List<Flowsheet>.from(state);
      updatedState[index].updateCanvasOffset(newOffset);
      state = updatedState;
      await _storageService.saveFlowsheet(updatedState[index]);
    }
  }

  Future<void> updateFlowsheet(
      String flowsheetId, Flowsheet updatedFlowsheet) async {
    final index = state.indexWhere((sheet) => sheet.id == flowsheetId);

    if (index >= 0) {
      final updatedState = List<Flowsheet>.from(state);
      updatedState[index] = updatedFlowsheet;
      state = updatedState;
      await _storageService.saveFlowsheet(updatedFlowsheet);
    }
  }

  Future<void> saveFlowsheet(String flowsheetId) async {
    final index = state.indexWhere((sheet) => sheet.id == flowsheetId);

    if (index >= 0) {
      await _storageService.saveFlowsheet(state[index]);
    }
  }

  Future<void> saveActiveFlowsheet() async {
    if (_activeFlowsheetId != null) {
      final flowsheet = activeFlowsheet;
      if (flowsheet != null) {
        await _storageService.saveFlowsheet(flowsheet);
      }
    }
  }

  static Future<void> saveFlowsheetFromProvider(
      WidgetRef ref, String flowsheetId) async {
    await ref.read(flowsheetsProvider.notifier).saveFlowsheet(flowsheetId);
  }
}

final flowsheetStorageServiceProvider =
    Provider<FlowsheetStorageService>((ref) {
  return FlowsheetStorageService();
});

final flowsheetsProvider =
    StateNotifierProvider<FlowsheetsNotifier, List<Flowsheet>>((ref) {
  return FlowsheetsNotifier(
    storageService: ref.watch(flowsheetStorageServiceProvider),
  );
});

final activeFlowsheetProvider = Provider<Flowsheet?>((ref) {
  final notifier = ref.watch(flowsheetsProvider.notifier);
  return notifier.activeFlowsheet;
});
