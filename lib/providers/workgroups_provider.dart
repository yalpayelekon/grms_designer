import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workgroup.dart';
import '../models/helvar_device.dart';
import '../services/file_storage_service.dart';
import '../services/router_storage_service.dart';

class WorkgroupsNotifier extends StateNotifier<List<Workgroup>> {
  final FileStorageService _fileStorageService;
  final RouterStorageService _routerStorageService;
  bool _initialized = false;

  WorkgroupsNotifier({
    required FileStorageService fileStorageService,
    required RouterStorageService routerStorageService,
  })  : _fileStorageService = fileStorageService,
        _routerStorageService = routerStorageService,
        super([]) {
    _initializeData();
  }
  Future<void> _initializeData() async {
    if (_initialized) return;

    try {
      final workgroups = await _fileStorageService.loadWorkgroups();
      for (var workgroup in workgroups) {
        for (var router in workgroup.routers) {
          try {
            final devices = await _routerStorageService.loadRouterDevices(
              workgroup.id,
              router.address,
            );
            router.devices.clear();
            router.devices.addAll(devices);
          } catch (e) {
            debugPrint(
                'Error loading devices for router ${router.description}: $e');
          }
        }
      }

      state = workgroups;
      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing workgroups: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      await _fileStorageService.saveWorkgroups(state);
      for (var workgroup in state) {
        for (var router in workgroup.routers) {
          try {
            await _routerStorageService.saveRouterDevices(
              workgroup.id,
              router.address,
              router.devices,
            );
          } catch (e) {
            debugPrint(
                'Error saving devices for router ${router.description}: $e');
          }
        }
      }
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

  Future<void> addDeviceToRouter(
      String workgroupId, String routerAddress, HelvarDevice device) async {
    final newState = [...state];
    final workgroupIndex = newState.indexWhere((wg) => wg.id == workgroupId);

    if (workgroupIndex >= 0) {
      final workgroup = newState[workgroupIndex];
      final routerIndex = workgroup.routers
          .indexWhere((router) => router.address == routerAddress);

      if (routerIndex >= 0) {
        final router = workgroup.routers[routerIndex];
        router.addDevice(device);

        state = newState;
        try {
          await _routerStorageService.saveRouterDevices(
            workgroupId,
            routerAddress,
            router.devices,
          );
        } catch (e) {
          debugPrint(
              'Error saving devices for router ${router.description}: $e');
        }
        try {
          await _fileStorageService.saveWorkgroups(state);
        } catch (e) {
          debugPrint('Error saving workgroups: $e');
        }
      }
    }
  }

  Future<void> removeDeviceFromRouter(
      String workgroupId, String routerAddress, HelvarDevice device) async {
    final newState = [...state];
    final workgroupIndex = newState.indexWhere((wg) => wg.id == workgroupId);

    if (workgroupIndex >= 0) {
      final workgroup = newState[workgroupIndex];
      final routerIndex = workgroup.routers
          .indexWhere((router) => router.address == routerAddress);

      if (routerIndex >= 0) {
        final router = workgroup.routers[routerIndex];
        router.removeDevice(device);

        state = newState;
        try {
          await _routerStorageService.saveRouterDevices(
            workgroupId,
            routerAddress,
            router.devices,
          );
        } catch (e) {
          debugPrint(
              'Error saving devices for router ${router.description}: $e');
        }
        try {
          await _fileStorageService.saveWorkgroups(state);
        } catch (e) {
          debugPrint('Error saving workgroups: $e');
        }
      }
    }
  }

  Future<void> updateDeviceInRouter(String workgroupId, String routerAddress,
      HelvarDevice oldDevice, HelvarDevice updatedDevice) async {
    final newState = [...state];
    final workgroupIndex = newState.indexWhere((wg) => wg.id == workgroupId);

    if (workgroupIndex >= 0) {
      final workgroup = newState[workgroupIndex];
      final routerIndex = workgroup.routers
          .indexWhere((router) => router.address == routerAddress);

      if (routerIndex >= 0) {
        final router = workgroup.routers[routerIndex];
        final deviceIndex = router.devices.indexOf(oldDevice);

        if (deviceIndex >= 0) {
          router.devices[deviceIndex] = updatedDevice;

          state = newState;
          try {
            await _routerStorageService.saveRouterDevices(
              workgroupId,
              routerAddress,
              router.devices,
            );
          } catch (e) {
            debugPrint(
                'Error saving devices for router ${router.description}: $e');
          }
          try {
            await _fileStorageService.saveWorkgroups(state);
          } catch (e) {
            debugPrint('Error saving workgroups: $e');
          }
        }
      }
    }
  }

  Future<void> exportWorkgroups(String filePath) async {
    await _fileStorageService.exportWorkgroups(state, filePath);
  }

  Future<void> importWorkgroups(String filePath, {bool merge = false}) async {
    final importedWorkgroups =
        await _fileStorageService.importWorkgroups(filePath);

    if (merge) {
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
    for (var workgroup in state) {
      for (var router in workgroup.routers) {
        try {
          await _routerStorageService.saveRouterDevices(
            workgroup.id,
            router.address,
            router.devices,
          );
        } catch (e) {
          debugPrint(
              'Error saving devices for router ${router.description}: $e');
        }
      }
    }
    try {
      await _fileStorageService.saveWorkgroups(state);
    } catch (e) {
      debugPrint('Error saving workgroups: $e');
    }
  }
}

final fileStorageServiceProvider = Provider<FileStorageService>((ref) {
  return FileStorageService();
});

final routerStorageServiceProvider = Provider<RouterStorageService>((ref) {
  return RouterStorageService();
});
final workgroupsProvider =
    StateNotifierProvider<WorkgroupsNotifier, List<Workgroup>>((ref) {
  return WorkgroupsNotifier(
    fileStorageService: ref.watch(fileStorageServiceProvider),
    routerStorageService: ref.watch(routerStorageServiceProvider),
  );
});
