import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wiresheet.dart';
import '../models/canvas_item.dart';
import '../services/wiresheet_storage_service.dart';

class WiresheetsNotifier extends StateNotifier<List<Wiresheet>> {
  final WiresheetStorageService _storageService;
  String? _activeWiresheetId;
  bool _initialized = false;

  WiresheetsNotifier({required WiresheetStorageService storageService})
      : _storageService = storageService,
        super([]) {
    _initializeData();
  }

  /// Get the active wiresheet ID
  String? get activeWiresheetId => _activeWiresheetId;

  /// Initialize data from storage
  Future<void> _initializeData() async {
    if (_initialized) return;

    try {
      final wiresheets = await _storageService.listWiresheets();

      if (wiresheets.isEmpty) {
        // Create default wiresheet if none exist
        final defaultWiresheet =
            await _storageService.createWiresheet('Default Wiresheet');
        state = [defaultWiresheet];
        _activeWiresheetId = defaultWiresheet.id;
      } else {
        state = wiresheets;
        _activeWiresheetId = wiresheets.first.id;
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing wiresheets: $e');
    }
  }

  Wiresheet? get activeWiresheet {
    if (_activeWiresheetId == null || state.isEmpty) return null;

    try {
      return state.firstWhere(
        (sheet) => sheet.id == _activeWiresheetId,
      );
    } catch (e) {
      return state.isNotEmpty ? state.first : null;
    }
  }

  void setActiveWiresheet(String id) {
    final exists = state.any((sheet) => sheet.id == id);
    if (exists) {
      _activeWiresheetId = id;
    } else if (state.isNotEmpty) {
      _activeWiresheetId = state.first.id;
    } else {
      _activeWiresheetId = null;
    }
  }

  Future<Wiresheet> createWiresheet(String name) async {
    final wiresheet = await _storageService.createWiresheet(name);
    state = [...state, wiresheet];
    _activeWiresheetId = wiresheet.id;
    return wiresheet;
  }

  /// Delete a wiresheet
  Future<bool> deleteWiresheet(String id) async {
    final success = await _storageService.deleteWiresheet(id);

    if (success) {
      state = state.where((sheet) => sheet.id != id).toList();

      // Update active wiresheet if the deleted one was active
      if (_activeWiresheetId == id) {
        _activeWiresheetId = state.isNotEmpty ? state.first.id : null;
      }
    }

    return success;
  }

  /// Rename a wiresheet
  Future<bool> renameWiresheet(String id, String newName) async {
    final updatedWiresheet = await _storageService.renameWiresheet(id, newName);

    if (updatedWiresheet != null) {
      state = state
          .map((sheet) => sheet.id == id ? updatedWiresheet : sheet)
          .toList();
      return true;
    }

    return false;
  }

  /// Duplicate a wiresheet
  Future<Wiresheet?> duplicateWiresheet(String id, String newName) async {
    final duplicatedWiresheet =
        await _storageService.duplicateWiresheet(id, newName);

    if (duplicatedWiresheet != null) {
      state = [...state, duplicatedWiresheet];
      _activeWiresheetId = duplicatedWiresheet.id;
      return duplicatedWiresheet;
    }

    return null;
  }

  /// Update a wiresheet canvas item
  Future<void> updateWiresheetItem(
      String wiresheetId, int itemIndex, CanvasItem updatedItem) async {
    final wiresheet = state.firstWhere(
      (sheet) => sheet.id == wiresheetId,
      orElse: () => null as Wiresheet, // This will throw if not found
    );

    wiresheet.updateItem(itemIndex, updatedItem);

    // Update state
    state = state
        .map((sheet) => sheet.id == wiresheetId ? wiresheet : sheet)
        .toList();

    // Save to storage
    await _storageService.saveWiresheet(wiresheet);
  }

  /// Add a canvas item to a wiresheet
  Future<void> addWiresheetItem(String wiresheetId, CanvasItem item) async {
    final index = state.indexWhere((sheet) => sheet.id == wiresheetId);

    if (index >= 0) {
      // Create a new list to ensure state immutability
      final updatedState = List<Wiresheet>.from(state);

      // Get the wiresheet and add the item
      final wiresheet = updatedState[index];
      wiresheet.addItem(item);

      // Update state
      state = updatedState;

      // Save to storage
      await _storageService.saveWiresheet(wiresheet);
    }
  }

  /// Remove a canvas item from a wiresheet
  Future<void> removeWiresheetItem(String wiresheetId, int itemIndex) async {
    final index = state.indexWhere((sheet) => sheet.id == wiresheetId);

    if (index >= 0) {
      // Create a new list to ensure state immutability
      final updatedState = List<Wiresheet>.from(state);

      // Get the wiresheet and remove the item
      final wiresheet = updatedState[index];
      wiresheet.removeItem(itemIndex);

      // Update state
      state = updatedState;

      // Save to storage
      await _storageService.saveWiresheet(wiresheet);
    }
  }

  /// Update canvas size for a wiresheet
  Future<void> updateCanvasSize(String wiresheetId, Size newSize) async {
    final index = state.indexWhere((sheet) => sheet.id == wiresheetId);

    if (index >= 0) {
      // Create a new list to ensure state immutability
      final updatedState = List<Wiresheet>.from(state);

      // Get the wiresheet and update canvas size
      final wiresheet = updatedState[index];
      wiresheet.updateCanvasSize(newSize);

      // Update state
      state = updatedState;

      // Save to storage
      await _storageService.saveWiresheet(wiresheet);
    }
  }

  /// Update canvas offset for a wiresheet
  Future<void> updateCanvasOffset(String wiresheetId, Offset newOffset) async {
    final index = state.indexWhere((sheet) => sheet.id == wiresheetId);

    if (index >= 0) {
      // Create a new list to ensure state immutability
      final updatedState = List<Wiresheet>.from(state);

      // Get the wiresheet and update canvas offset
      final wiresheet = updatedState[index];
      wiresheet.updateCanvasOffset(newOffset);

      // Update state
      state = updatedState;

      // Save to storage
      await _storageService.saveWiresheet(wiresheet);
    }
  }
}

/// Provider for the wiresheet storage service
final wiresheetStorageServiceProvider =
    Provider<WiresheetStorageService>((ref) {
  return WiresheetStorageService();
});

/// Provider for wiresheets state
final wiresheetsProvider =
    StateNotifierProvider<WiresheetsNotifier, List<Wiresheet>>((ref) {
  return WiresheetsNotifier(
    storageService: ref.watch(wiresheetStorageServiceProvider),
  );
});

/// Provider for the active wiresheet
final activeWiresheetProvider = Provider<Wiresheet?>((ref) {
  final notifier = ref.watch(wiresheetsProvider.notifier);
  return notifier.activeWiresheet;
});
