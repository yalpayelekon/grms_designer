import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_settings.dart';
import '../services/app_directory_service.dart';

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
      debugPrint('Error loading project settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final filePath =
          await _directoryService.getSettingsFilePath(_settingsFileName);
      final file = File(filePath);

      final jsonString = jsonEncode(state.toJson());
      await file.writeAsString(jsonString);

      debugPrint('Project settings saved to: $filePath');
    } catch (e) {
      debugPrint('Error saving project settings: $e');
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
      debugPrint('Error creating project settings backup: $e');
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
      debugPrint('Error restoring project settings from backup: $e');
      return false;
    }
  }
}

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
