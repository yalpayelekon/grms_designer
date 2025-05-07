import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_settings.dart';
import '../services/app_directory_service.dart';
import '../utils/logger.dart';

class ProjectSettingsNotifier extends StateNotifier<ProjectSettings> {
  final AppDirectoryService _directoryService = AppDirectoryService();
  static const String _settingsFileName = 'project_settings.json';

  ProjectSettingsNotifier() : super(ProjectSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final filePath =
          await _directoryService.getSettingsFilePath(_settingsFileName);
      final file = File(filePath);

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final json = jsonDecode(jsonString);

        state = ProjectSettings.fromJson(json);
      }
    } catch (e) {
      logError('Error loading project settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final filePath =
          await _directoryService.getSettingsFilePath(_settingsFileName);
      final file = File(filePath);

      final jsonString = jsonEncode(state.toJson());
      await file.writeAsString(jsonString);

      logInfo('Project settings saved to: $filePath');
    } catch (e) {
      logError('Error saving project settings: $e');
    }
  }

  Future<void> setProjectName(String name) async {
    state = state.copyWith(projectName: name);
    await _saveSettings();
  }

  Future<void> setSocketTimeout(int timeoutMs) async {
    state = state.copyWith(socketTimeoutMs: timeoutMs);
    await _saveSettings();
  }

  Future<void> setAutoSave(bool enabled) async {
    state = state.copyWith(autoSave: enabled);
    await _saveSettings();
  }

  Future<void> setAutoSaveInterval(int minutes) async {
    state = state.copyWith(autoSaveIntervalMinutes: minutes);
    await _saveSettings();
  }

  Future<String?> createSettingsBackup() async {
    try {
      return _directoryService.createBackup(
          AppDirectoryService.settingsDir, _settingsFileName);
    } catch (e) {
      logError('Error creating project settings backup: $e');
      return null;
    }
  }

  Future<bool> restoreSettingsFromBackup(String backupFileName) async {
    try {
      final backupFilePath =
          await _directoryService.getBackupFilePath(backupFileName);
      final backupFile = File(backupFilePath);

      if (!await backupFile.exists()) {
        return false;
      }

      final jsonString = await backupFile.readAsString();
      final json = jsonDecode(jsonString);

      state = ProjectSettings.fromJson(json);
      await _saveSettings();

      return true;
    } catch (e) {
      logError('Error restoring project settings from backup: $e');
      return false;
    }
  }

  Future<void> setCommandTimeout(int timeoutMs) async {
    state = state.copyWith(commandTimeoutMs: timeoutMs);
    await _saveSettings();
  }

  Future<void> setHeartbeatInterval(int seconds) async {
    state = state.copyWith(heartbeatIntervalSeconds: seconds);
    await _saveSettings();
  }

  Future<void> setMaxCommandRetries(int retries) async {
    state = state.copyWith(maxCommandRetries: retries);
    await _saveSettings();
  }

  Future<void> setMaxConcurrentCommands(int maxCommands) async {
    state = state.copyWith(maxConcurrentCommandsPerRouter: maxCommands);
    await _saveSettings();
  }

  Future<void> setCommandHistorySize(int size) async {
    state = state.copyWith(commandHistorySize: size);
    await _saveSettings();
  }

  Future<void> setProtocolVersion(int version) async {
    state = state.copyWith(protocolVersion: version);
    await _saveSettings();
  }
}

final protocolVersionProvider = Provider<int>((ref) {
  return ref.watch(projectSettingsProvider).protocolVersion;
});

final projectSettingsProvider =
    StateNotifierProvider<ProjectSettingsNotifier, ProjectSettings>((ref) {
  return ProjectSettingsNotifier();
});

final projectNameProvider = Provider<String>((ref) {
  return ref.watch(projectSettingsProvider).projectName;
});

final socketTimeoutProvider = Provider<int>((ref) {
  return ref.watch(projectSettingsProvider).socketTimeoutMs;
});

final autoSaveEnabledProvider = Provider<bool>((ref) {
  return ref.watch(projectSettingsProvider).autoSave;
});

final autoSaveIntervalProvider = Provider<int>((ref) {
  return ref.watch(projectSettingsProvider).autoSaveIntervalMinutes;
});

final commandTimeoutProvider = Provider<int>((ref) {
  return ref.watch(projectSettingsProvider).commandTimeoutMs;
});

final heartbeatIntervalProvider = Provider<int>((ref) {
  return ref.watch(projectSettingsProvider).heartbeatIntervalSeconds;
});

final maxCommandRetriesProvider = Provider<int>((ref) {
  return ref.watch(projectSettingsProvider).maxCommandRetries;
});

final maxConcurrentCommandsProvider = Provider<int>((ref) {
  return ref.watch(projectSettingsProvider).maxConcurrentCommandsPerRouter;
});

final commandHistorySizeProvider = Provider<int>((ref) {
  return ref.watch(projectSettingsProvider).commandHistorySize;
});
