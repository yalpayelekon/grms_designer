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
  String? get activeWiresheetId => _activeWiresheetId;
  Future<void> _initializeData() async {
    if (_initialized) return;

    try {
      final wiresheets = await _storageService.listWiresheets();

      if (wiresheets.isEmpty) {
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

  Future<bool> deleteWiresheet(String id) async {
    final success = await _storageService.deleteWiresheet(id);

    if (success) {
      state = state.where((sheet) => sheet.id != id).toList();
      if (_activeWiresheetId == id) {
        _activeWiresheetId = state.isNotEmpty ? state.first.id : null;
      }
    }

    return success;
  }

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

  Future<void> updateWiresheetItem(
      String wiresheetId, int itemIndex, CanvasItem updatedItem) async {
    final wiresheet = state.firstWhere(
      (sheet) => sheet.id == wiresheetId,
      orElse: () => null as Wiresheet, // This will throw if not found
    );

    wiresheet.updateItem(itemIndex, updatedItem);
    state = state
        .map((sheet) => sheet.id == wiresheetId ? wiresheet : sheet)
        .toList();
    await _storageService.saveWiresheet(wiresheet);
  }

  Future<void> addWiresheetItem(String wiresheetId, CanvasItem item) async {
    final index = state.indexWhere((sheet) => sheet.id == wiresheetId);

    if (index >= 0) {
      final updatedState = List<Wiresheet>.from(state);
      final wiresheet = updatedState[index];
      wiresheet.addItem(item);
      state = updatedState;
      await _storageService.saveWiresheet(wiresheet);
    }
  }

  Future<void> removeWiresheetItem(String wiresheetId, int itemIndex) async {
    final index = state.indexWhere((sheet) => sheet.id == wiresheetId);

    if (index >= 0) {
      final updatedState = List<Wiresheet>.from(state);
      final wiresheet = updatedState[index];
      wiresheet.removeItem(itemIndex);
      state = updatedState;
      await _storageService.saveWiresheet(wiresheet);
    }
  }

  Future<void> updateCanvasSize(String wiresheetId, Size newSize) async {
    final index = state.indexWhere((sheet) => sheet.id == wiresheetId);

    if (index >= 0) {
      final updatedState = List<Wiresheet>.from(state);
      final wiresheet = updatedState[index];
      wiresheet.updateCanvasSize(newSize);
      state = updatedState;
      await _storageService.saveWiresheet(wiresheet);
    }
  }

  Future<void> updateCanvasOffset(String wiresheetId, Offset newOffset) async {
    final index = state.indexWhere((sheet) => sheet.id == wiresheetId);

    if (index >= 0) {
      final updatedState = List<Wiresheet>.from(state);
      final wiresheet = updatedState[index];
      wiresheet.updateCanvasOffset(newOffset);
      state = updatedState;
      await _storageService.saveWiresheet(wiresheet);
    }
  }
}

final wiresheetStorageServiceProvider =
    Provider<WiresheetStorageService>((ref) {
  return WiresheetStorageService();
});
final wiresheetsProvider =
    StateNotifierProvider<WiresheetsNotifier, List<Wiresheet>>((ref) {
  return WiresheetsNotifier(
    storageService: ref.watch(wiresheetStorageServiceProvider),
  );
});
final activeWiresheetProvider = Provider<Wiresheet?>((ref) {
  final notifier = ref.watch(wiresheetsProvider.notifier);
  return notifier.activeWiresheet;
});
