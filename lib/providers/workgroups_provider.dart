import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workgroup.dart';
import '../services/file_storage_service.dart';

class WorkgroupsNotifier extends StateNotifier<List<Workgroup>> {
  final FileStorageService _storageService;
  bool _initialized = false;

  WorkgroupsNotifier({required FileStorageService storageService})
      : _storageService = storageService,
        super([]) {
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (_initialized) return;

    try {
      final workgroups = await _storageService.loadWorkgroups();
      state = workgroups;
      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing workgroups: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      await _storageService.saveWorkgroups(state);
    } catch (e) {
      debugPrint('Error saving workgroups: $e');
    }
  }

  void addWorkgroup(Workgroup workgroup) {
    state = [...state, workgroup];
    _saveToStorage();
  }

  void removeWorkgroup(String id) {
    state = state.where((wg) => wg.id != id).toList();
    _saveToStorage();
  }

  void updateWorkgroup(Workgroup updatedWorkgroup) {
    state = state
        .map((wg) => wg.id == updatedWorkgroup.id ? updatedWorkgroup : wg)
        .toList();
    _saveToStorage();
  }

  void clearWorkgroups() {
    state = [];
    _saveToStorage();
  }

  Future<void> exportWorkgroups(String filePath) async {
    await _storageService.exportWorkgroups(state, filePath);
  }

  Future<void> importWorkgroups(String filePath, {bool merge = false}) async {
    final importedWorkgroups = await _storageService.importWorkgroups(filePath);

    if (merge) {
      final existingWorkgroupsMap = {for (var wg in state) wg.id: wg};

      final List<Workgroup> newState = [...state];

      for (final importedWg in importedWorkgroups) {
        final existingIndex =
            newState.indexWhere((wg) => wg.id == importedWg.id);

        if (existingIndex >= 0) {
          newState[existingIndex] = importedWg;
        } else {
          newState.add(importedWg);
        }
      }

      state = newState;
    } else {
      state = importedWorkgroups;
    }

    _saveToStorage();
  }
}

final fileStorageServiceProvider = Provider<FileStorageService>((ref) {
  return FileStorageService();
});

final workgroupsProvider =
    StateNotifierProvider<WorkgroupsNotifier, List<Workgroup>>((ref) {
  return WorkgroupsNotifier(
    storageService: ref.watch(fileStorageServiceProvider),
  );
});
